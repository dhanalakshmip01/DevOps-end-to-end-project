# Issues Faced & Fixes

Running log of issues encountered during setup and how they were resolved.

---

## Issue 1 — Security Group Description Rejected by AWS

**Error:**
```
InvalidParameterValue: Value (Security group for jumpbox — SSM only, no SSH)
for parameter GroupDescription is invalid.
Character sets beyond ASCII are not supported.
```

**Cause:**
Em dash (`—`) used in security group description. AWS only accepts ASCII characters in SG descriptions.

**Fix:**
Replace em dash (`—`) with regular hyphen (`-`) in all AWS resource description fields in `modules/jumpbox/main.tf`:
```hcl
# Before
description = "Security group for jumpbox — SSM only, no SSH"

# After
description = "Security group for jumpbox - SSM only, no SSH"
```

---

## Issue 2 — Terraform Deprecated Attribute Warning

**Warning:**
```
Warning: Deprecated attribute
on ..\..\modules\jumpbox\main.tf line 65
The attribute "name" is deprecated.
```

**Cause:**
`data.aws_region.current.name` is deprecated in AWS provider v6. Should use `.id` instead.

**Fix:**
```hcl
# Before
data.aws_region.current.name

# After
data.aws_region.current.id
```

---

## Issue 3 — Session Manager Plugin Not Found in Git Bash

**Error:**
```
SessionManagerPlugin is not found.
```

**Cause:**
Plugin was installed but its directory was not in Git Bash PATH.

**Fix:**
```bash
# Add to PATH permanently
echo 'export PATH=$PATH:"/c/Program Files/Amazon/SessionManagerPlugin/bin"' >> ~/.bashrc
source ~/.bashrc
```

---

## Issue 4 — kubectl Not Installed on Jumpbox

**Error:**
```
sh: kubectl: command not found
```

**Cause:**
Jumpbox EC2 launches with bare Amazon Linux 2023 — no `user_data` script to install tools.

**Fix (manual — until Terraform is re-applied):**
```bash
cd /tmp
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
```

**Permanent fix:**
Added `user_data` to `modules/jumpbox/main.tf` to auto-install kubectl on boot.

---

## Issue 5 — kubectl Download Failed: Permission Denied

**Error:**
```
Warning: Failed to open the file kubectl: Permission denied
curl: (23) client returned ERROR on write of 1369 bytes
```

**Cause:**
SSM session user has no write permission to the current directory (`/home/ssm-user`).

**Fix:**
Use `/tmp` which is writable by all users:
```bash
cd /tmp
curl -LO "https://dl.k8s.io/release/..."
```

---

## Issue 6 — kubectl get nodes: Server Asked for Credentials

**Error:**
```
E0321 memcache.go:265 "Unhandled Error" err="couldn't get current server API group list:
the server has asked for the client to provide credentials"
```

**Cause:**
Jumpbox IAM role (`snappaste-dev-jumpbox-role`) was not added to EKS access entries.
EKS does not recognize the role and rejects all K8s API calls.

**Fix:**
Run from laptop (not jumpbox) using personal IAM user with admin access:
```bash
# Add jumpbox role to EKS access entries
aws eks create-access-entry \
  --cluster-name snappaste-dev-eks \
  --principal-arn arn:aws:iam::884337374668:role/snappaste-dev-jumpbox-role \
  --region us-east-1

# Grant cluster admin policy
aws eks associate-access-policy \
  --cluster-name snappaste-dev-eks \
  --principal-arn arn:aws:iam::884337374668:role/snappaste-dev-jumpbox-role \
  --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy \
  --access-scope type=cluster \
  --region us-east-1
```

**Permanent fix:**
Add `access_entries` block to `modules/eks/main.tf` so Terraform manages this automatically on next apply.

---

## Issue 7 — EKS Access Entry Commands Run from Jumpbox Instead of Laptop

**Error:**
```
AccessDeniedException: User assumed-role/snappaste-dev-jumpbox-role is not authorized
to perform: eks:CreateAccessEntry
```

**Cause:**
Commands were run from inside the SSM jumpbox session. The jumpbox IAM role only has
`eks:DescribeCluster` and `eks:ListClusters` — not `eks:CreateAccessEntry`.

**Fix:**
Exit the jumpbox session first, then run from laptop:
```bash
exit   # exit jumpbox SSM session
# then run aws eks commands from laptop
```

---

## Issue 8 — EKS Console Shows "No Nodes"

**Symptom:**
EKS console shows node group exists but "No Nodes" visible. EC2 console shows nodes running.

**Cause:**
Expected behavior. EKS console tries to reach the K8s API server from the browser.
We set `endpoint_public_access = false` — K8s API is only accessible from inside the VPC.
Browser cannot reach it, so node list appears empty.

**Fix:**
Not a real issue. To view nodes, SSM into jumpbox and use kubectl:
```bash
aws eks update-kubeconfig --name snappaste-dev-eks --region us-east-1
kubectl get nodes
```
