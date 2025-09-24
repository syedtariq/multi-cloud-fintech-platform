# Security Module - Security Groups, KMS, IAM, CloudTrail

# KMS Keys
resource "aws_kms_key" "cluster" {
  description             = "EKS Cluster encryption key"
  deletion_window_in_days = 30

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-eks-cluster-key"
  })
}

resource "aws_kms_alias" "cluster" {
  name          = "alias/${var.name_prefix}-eks-cluster"
  target_key_id = aws_kms_key.cluster.key_id
}

resource "aws_kms_key" "database" {
  description             = "RDS encryption key"
  deletion_window_in_days = 30

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-database-key"
  })
}

resource "aws_kms_alias" "database" {
  name          = "alias/${var.name_prefix}-database"
  target_key_id = aws_kms_key.database.key_id
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
}

resource "aws_security_group" "eks_cluster" {
  name_prefix = "${var.name_prefix}-eks-cluster-"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-eks-cluster-sg"
  })
}

resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.name_prefix}-eks-nodes-"
  vpc_id      = var.vpc_id

  # Ingress from ALB
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "HTTP from ALB"
  }

  # Ingress from EKS cluster
  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_cluster.id]
    description     = "EKS cluster communication"
  }

  # Self-referencing for pod-to-pod communication
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
    description = "Pod-to-pod communication"
  }

  # Egress to databases only
  egress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.database.id]
    description     = "PostgreSQL access"
  }

  egress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.database.id]
    description     = "Redis access"
  }

  # HTTPS for external API calls (AWS services, etc.)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for AWS services"
  }

  # DNS resolution
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS resolution"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-eks-nodes-sg"
  })
}

resource "aws_security_group" "database" {
  name_prefix = "${var.name_prefix}-database-"
  vpc_id      = var.vpc_id

  # PostgreSQL from EKS nodes only
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "PostgreSQL from EKS nodes"
  }

  # Redis from EKS nodes only
  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.eks_nodes.id]
    description     = "Redis from EKS nodes"
  }

  # No egress rules - databases don't need outbound access
  # This follows zero-trust principle

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-database-sg"
  })
}

# IAM Roles
resource "aws_iam_role" "eks_cluster" {
  name = "${var.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role" "eks_nodes" {
  name = "${var.name_prefix}-eks-nodes-role"

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

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_nodes.name
}

# Include CloudTrail resources
# S3 Bucket for CloudTrail Logs
resource "aws_s3_bucket" "cloudtrail" {
  bucket        = "${var.name_prefix}-cloudtrail-logs"
  force_destroy = false

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-cloudtrail-logs"
  })
}

resource "aws_s3_bucket_versioning" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_encryption" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.cloudtrail.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CloudTrail KMS Key
resource "aws_kms_key" "cloudtrail" {
  description             = "KMS key for CloudTrail encryption"
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable CloudTrail Encryption"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-cloudtrail-key"
  })
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/${var.name_prefix}-cloudtrail"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

# CloudTrail
resource "aws_cloudtrail" "main" {
  name           = "${var.name_prefix}-cloudtrail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket
  s3_key_prefix  = "cloudtrail-logs"

  include_global_service_events = true
  is_multi_region_trail        = true
  enable_logging               = true
  enable_log_file_validation   = true
  kms_key_id                   = aws_kms_key.cloudtrail.arn

  # Data Events for S3 (Financial Data)
  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    exclude_management_event_sources = []

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.name_prefix}-*/*"]
    }
  }

  # Insight Events for Cost Optimization
  insight_selector {
    insight_type = "ApiCallRateInsight"
  }

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-cloudtrail"
  })

  depends_on = [aws_s3_bucket_policy.cloudtrail]
}

# S3 Bucket Policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail" {
  bucket = aws_s3_bucket.cloudtrail.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}