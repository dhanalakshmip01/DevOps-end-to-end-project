# ──────────────────────────────────────────────
# Security Group for GitHub Actions Self-Hosted Runner
# ──────────────────────────────────────────────
resource "aws_security_group" "runner" {
  name_prefix = "${var.project_name}-${var.environment}-gh-runner-"
  description = "Security group for GitHub Actions self-hosted runner"
  vpc_id      = var.vpc_id

  # Outbound — runner needs internet to pull repos, images, talk to GitHub API
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound (GitHub API, ECR, Docker Hub)"
  }

  # SSH access from bastion only
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = var.bastion_security_group_id != null ? [var.bastion_security_group_id] : []
    description     = "SSH from bastion host only"
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-gh-runner-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# ──────────────────────────────────────────────
# IAM Role for the Runner EC2
# ──────────────────────────────────────────────
resource "aws_iam_role" "runner" {
  name = "${var.project_name}-${var.environment}-gh-runner-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# ECR access — runner needs to push/pull images
resource "aws_iam_role_policy" "ecr_access" {
  name = "${var.project_name}-${var.environment}-gh-runner-ecr"
  role = aws_iam_role.runner.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      }
    ]
  })
}

# EKS access — runner needs to deploy via kubectl/helm
resource "aws_iam_role_policy" "eks_access" {
  name = "${var.project_name}-${var.environment}-gh-runner-eks"
  role = aws_iam_role.runner.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ]
        Resource = "*"
      }
    ]
  })
}

# SSM access — for Session Manager (no SSH key needed)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.runner.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "runner" {
  name = "${var.project_name}-${var.environment}-gh-runner-profile"
  role = aws_iam_role.runner.name
}

# ──────────────────────────────────────────────
# EC2 Instance — Self-Hosted GitHub Actions Runner
# ──────────────────────────────────────────────
resource "aws_instance" "runner" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.runner.id]
  iam_instance_profile   = aws_iam_instance_profile.runner.name
  key_name               = var.key_name

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    github_runner_url   = var.github_runner_url
    github_runner_token = var.github_runner_token
    runner_name         = "${var.project_name}-${var.environment}-runner"
    runner_labels       = "${var.environment},self-hosted,linux,x64"
  }))

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-${var.environment}-gh-runner"
    Environment = var.environment
    ManagedBy   = "terraform"
    Role        = "github-actions-runner"
  })
}

# Latest Ubuntu 24.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
