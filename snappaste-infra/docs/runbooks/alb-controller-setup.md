# ALB Ingress Controller Setup

How to install the AWS Load Balancer Controller on EKS and how Pod Identity
provides it AWS permissions — no static credentials, no IRSA.

---

## How It Works

```
Terraform (already applied):
  1. eks-pod-identity-agent addon  → DaemonSet running on every node
  2. IAM role created              → has full ALB/ELB permissions
  3. Pod Identity association      → links the IAM role to:
       namespace:       kube-system
       service_account: aws-load-balancer-controller

Helm install (steps below):
  4. Creates ServiceAccount named: aws-load-balancer-controller
       ↓
  Pod Identity Agent sees the name match → injects temp AWS credentials into pod
       ↓
  Controller can now create/update/delete ALBs when you apply an Ingress
```

**Where this lives in Terraform:**
- Agent: `modules/eks/main.tf` — `eks-pod-identity-agent` addon
- IAM role + association: `modules/eks/main.tf` — `module "lb_controller_pod_identity"`

> The `serviceAccount.name` in the Helm install **must match exactly** what
> Terraform registered in the Pod Identity association (`aws-load-balancer-controller`).

---

## Prerequisites

- EKS cluster is up (`terraform apply` completed)
- Jumpbox accessible via SSM (see [ssm-access.md](ssm-access.md))
- kubectl configured on jumpbox (`aws eks update-kubeconfig ...`)
- Helm installed on jumpbox (see below)

---

## Step 1 — Install Helm on Jumpbox (first time only)

```bash
# Inside jumpbox via SSM
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Verify
helm version
```

> **Note:** This is now automated in `user_data` inside `modules/jumpbox/main.tf`.
> Only run manually if the jumpbox was provisioned before this change.

---

## Step 2 — Install the ALB Controller

```bash
# Configure kubectl (if not already done)
aws eks update-kubeconfig --name snappaste-dev-eks --region us-east-1

# Add EKS Helm repo
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Get VPC ID
VPC_ID=$(aws ec2 describe-vpcs \
  --filters "Name=tag:Name,Values=snappaste-dev-vpc" \
  --query "Vpcs[0].VpcId" \
  --output text \
  --region us-east-1)

echo "VPC ID: $VPC_ID"   # verify before proceeding

# Install
# serviceAccount.name MUST match the Pod Identity association in Terraform
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=snappaste-dev-eks \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.create=true \
  --set region=us-east-1 \
  --set vpcId=$VPC_ID

# Verify — should show 2 pods Running within ~60 seconds
kubectl get pods -n kube-system | grep aws-load-balancer
kubectl get deployment -n kube-system aws-load-balancer-controller
```

---

## Step 3 — Verify Pod Identity is Working

```bash
# Controller logs — should NOT show any auth/credential errors
kubectl logs -n kube-system \
  deployment/aws-load-balancer-controller \
  --tail=50

# After deploying an Ingress, check events to confirm ALB provisioning
kubectl describe ingress <ingress-name> -n snappaste
# Look for: "Successfully reconciled" and an ADDRESS appearing
```

---

## Upgrade

```bash
helm repo update
helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=snappaste-dev-eks \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.create=true \
  --set region=us-east-1 \
  --set vpcId=$VPC_ID
```

---

## Troubleshooting

### Controller pods not starting
```bash
kubectl describe pod -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
# Look at Events section for image pull or permission errors
```

### "AccessDenied" in controller logs
- Pod Identity association not set up — check Terraform applied `module "lb_controller_pod_identity"`
- Service account name mismatch — must be exactly `aws-load-balancer-controller`
- `eks-pod-identity-agent` addon not installed — check `kubectl get pods -n kube-system | grep pod-identity`

### Ingress not getting an ADDRESS
```bash
# Check controller is running
kubectl get pods -n kube-system | grep aws-load-balancer

# Check ingress class is set correctly
kubectl describe ingress <name> -n snappaste
# ingressClassName must be: alb
```
