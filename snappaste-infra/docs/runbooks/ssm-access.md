# SSM Access Runbook

How to access jumpbox and runner via AWS SSM Session Manager.
No SSH keys, no bastion, no open ports needed.

---

## Prerequisites

### 1. Install AWS CLI
```bash
# Windows
winget install --id Amazon.AWSCLI

# Verify
aws --version
```

### 2. Install Session Manager Plugin
Download from:
https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html

```bash
# Windows — run installer from above link
# Verify
session-manager-plugin --version
```

**If plugin installed but not found in Git Bash:**
```bash
# Check if file exists
ls "/c/Program Files/Amazon/SessionManagerPlugin/bin/session-manager-plugin.exe"

# Add to PATH permanently
echo 'export PATH=$PATH:"/c/Program Files/Amazon/SessionManagerPlugin/bin"' >> ~/.bashrc
source ~/.bashrc

# Verify
which session-manager-plugin
```

### 3. Configure AWS credentials
```bash
aws configure
# Enter: Access Key ID, Secret Access Key, Region (us-east-1), Output (json)
```

---

## Get Instance IDs

```bash
# List all snappaste instances
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=snappaste" \
  --query "Reservations[].Instances[].[Tags[?Key=='Name'].Value|[0],InstanceId,State.Name]" \
  --output table \
  --region us-east-1
```

---

## Connect to Jumpbox

```bash
# SSM into jumpbox
aws ssm start-session \
  --target <jumpbox-instance-id> \
  --region us-east-1

# Example
aws ssm start-session \
  --target i-0a7ef8e592ed516f3 \
  --region us-east-1
```

---

## Connect to Runner

```bash
aws ssm start-session \
  --target <runner-instance-id> \
  --region us-east-1

# Example
aws ssm start-session \
  --target i-0ca27e5acd25bcb71 \
  --region us-east-1
```

---

## Install kubectl on Jumpbox (first time only)

Once inside jumpbox via SSM — kubectl is not pre-installed:

```bash
# Write to /tmp to avoid permission issues
cd /tmp
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

# Verify
kubectl version --client
```

---

## Grant Jumpbox IAM Role Access to EKS (first time only)

Run from your **laptop** (not jumpbox) — jumpbox role must be added to EKS access entries:

```bash
# Step 1 — Add jumpbox role as EKS access entry
aws eks create-access-entry \
  --cluster-name snappaste-dev-eks \
  --principal-arn arn:aws:iam::884337374668:role/snappaste-dev-jumpbox-role \
  --region us-east-1

# Step 2 — Grant cluster admin policy
aws eks associate-access-policy \
  --cluster-name snappaste-dev-eks \
  --principal-arn arn:aws:iam::884337374668:role/snappaste-dev-jumpbox-role \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region us-east-1
```

> **Note:** This is a temporary manual step. It will be added to Terraform permanently so it's never needed again after re-apply.

---

## Configure kubectl from Jumpbox

Once inside the jumpbox session:

```bash
# Configure kubectl to point to dev cluster
aws eks update-kubeconfig \
  --name snappaste-dev-eks \
  --region us-east-1

# Verify nodes are ready
kubectl get nodes

# Check all pods
kubectl get pods -A

# Check specific namespace
kubectl get pods -n snappaste
```

---

## Switch Between Environments

```bash
# Dev
aws eks update-kubeconfig --name snappaste-dev-eks --region us-east-1

# Staging
aws eks update-kubeconfig --name snappaste-staging-eks --region us-east-1

# Prod
aws eks update-kubeconfig --name snappaste-prod-eks --region us-east-1

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>
```

---

## Useful kubectl Commands

```bash
# Node status
kubectl get nodes -o wide

# All pods across namespaces
kubectl get pods -A

# App pods
kubectl get pods -n snappaste

# Monitoring pods
kubectl get pods -n monitoring

# Describe a pod (useful for debugging)
kubectl describe pod <pod-name> -n snappaste

# Pod logs
kubectl logs <pod-name> -n snappaste

# Follow logs
kubectl logs -f <pod-name> -n snappaste
```

---

## Check Runner Registration

```bash
# From inside runner via SSM
sudo systemctl status actions.runner.*

# View runner logs
sudo journalctl -u actions.runner.* -f
```

---

## Troubleshooting

### SSM session fails — instance not reachable
- Check instance is running: `aws ec2 describe-instances --instance-ids <id>`
- Check SSM agent is running (give jumpbox 3-5 mins after launch to initialize)
- Check IAM role has `AmazonSSMManagedInstanceCore` policy attached

### kubectl — "Unable to connect to server"
- EKS endpoint is private — must run kubectl from inside VPC (jumpbox or runner)
- Never run kubectl from your laptop directly

### Nodes show NotReady
```bash
kubectl describe node <node-name>
# Look at Conditions and Events sections
```

### Runner shows offline in GitHub
```bash
# SSM into runner, check service
sudo systemctl status actions.runner.*
sudo systemctl restart actions.runner.*
```
