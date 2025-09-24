# Database Module - RDS Aurora, ElastiCache, S3

# Database Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.name_prefix}-db-subnet-group"
  subnet_ids = var.database_subnet_ids

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-db-subnet-group"
  })
}

# RDS Aurora Cluster
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "${var.name_prefix}-aurora"
  engine                  = "aurora-postgresql"
  engine_version          = var.database_config.engine_version
  database_name           = "trading_platform"
  master_username         = "dbadmin"
  master_password         = var.rds_password
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = var.security_group_ids
  
  backup_retention_period = var.database_config.backup_retention_days
  preferred_backup_window = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  
  storage_encrypted = true
  kms_key_id       = var.kms_key_arn
  
  skip_final_snapshot = true
  
  tags = var.common_tags
}

resource "aws_rds_cluster_instance" "main" {
  count              = var.database_config.multi_az ? 2 : 1
  identifier         = "${var.name_prefix}-aurora-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = var.database_config.instance_class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  performance_insights_enabled = var.database_config.performance_insights
  
  tags = var.common_tags
}

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.name_prefix}-cache-subnet"
  subnet_ids = var.database_subnet_ids
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.name_prefix}-redis"
  description                = "Redis cluster for trading platform"
  
  node_type                  = var.cache_config.node_type
  port                       = 6379
  parameter_group_name       = var.cache_config.parameter_group
  engine_version             = var.cache_config.engine_version
  
  num_cache_clusters         = var.cache_config.num_cache_nodes
  
  subnet_group_name          = aws_elasticache_subnet_group.main.name
  security_group_ids         = var.security_group_ids
  
  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  
  tags = var.common_tags
}

# S3 Bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "data" {
  bucket = "${var.name_prefix}-trading-data-${random_id.bucket_suffix.hex}"
  
  tags = var.common_tags
}

resource "aws_s3_bucket_encryption_configuration" "data" {
  bucket = aws_s3_bucket.data.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Cross-Region Replication (to external Azure endpoint)
resource "aws_s3_bucket_replication_configuration" "azure_replication" {
  role   = aws_iam_role.s3_replication.arn
  bucket = aws_s3_bucket.data.id

  rule {
    id     = "azure-replication"
    status = "Enabled"

    destination {
      bucket        = "arn:aws:s3:::${var.azure_blob_endpoint}"  # External Azure endpoint
      storage_class = "STANDARD"
      
      encryption_configuration {
        replica_kms_key_id = var.kms_key_arn
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.data]
}

# IAM Role for S3 Replication
resource "aws_iam_role" "s3_replication" {
  name = "${var.name_prefix}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# Kinesis Data Stream
resource "aws_kinesis_stream" "trading_events" {
  name             = "${var.name_prefix}-trading-events"
  shard_count      = 10
  retention_period = 24

  encryption_type = "KMS"
  kms_key_id      = var.kms_key_arn

  tags = var.common_tags
}

# SQS Queue
resource "aws_sqs_queue" "order_processing" {
  name                      = "${var.name_prefix}-order-processing"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 1209600
  receive_wait_time_seconds = 10
  
  kms_master_key_id = var.kms_key_arn
  
  tags = var.common_tags
}

# DMS Replication Instance for RDS to Azure
resource "aws_dms_replication_instance" "azure_replication" {
  allocated_storage            = 100
  apply_immediately           = true
  auto_minor_version_upgrade  = true
  engine_version              = "3.5.2"
  multi_az                    = false
  publicly_accessible         = false
  replication_instance_class  = "dms.t3.medium"
  replication_instance_id     = "${var.name_prefix}-azure-replication"
  replication_subnet_group_id = aws_dms_replication_subnet_group.main.id
  vpc_security_group_ids      = var.security_group_ids

  tags = var.common_tags
}

# DMS Subnet Group
resource "aws_dms_replication_subnet_group" "main" {
  replication_subnet_group_description = "DMS subnet group for Azure replication"
  replication_subnet_group_id          = "${var.name_prefix}-dms-subnet-group"
  subnet_ids                           = var.database_subnet_ids

  tags = var.common_tags
}

# DMS Source Endpoint (RDS Aurora)
resource "aws_dms_endpoint" "source" {
  endpoint_id   = "${var.name_prefix}-source-endpoint"
  endpoint_type = "source"
  engine_name   = "aurora-postgresql"
  server_name   = aws_rds_cluster.main.endpoint
  port          = 5432
  database_name = aws_rds_cluster.main.database_name
  username      = aws_rds_cluster.main.master_username
  password      = "placeholder"  # Will be managed separately
  ssl_mode      = "require"

  tags = var.common_tags
}

# DMS Target Endpoint (Azure PostgreSQL - external)
resource "aws_dms_endpoint" "target" {
  endpoint_id   = "${var.name_prefix}-target-endpoint"
  endpoint_type = "target"
  engine_name   = "postgres"
  server_name   = var.azure_postgres_endpoint  # External Azure endpoint
  port          = 5432
  database_name = "trading_platform"
  username      = "azure_admin"
  password      = "placeholder"  # Will be managed separately
  ssl_mode      = "require"

  tags = var.common_tags
}

# Lambda Function for Redis Sync
resource "aws_lambda_function" "redis_sync" {
  filename         = "redis_sync.zip"
  function_name    = "${var.name_prefix}-redis-sync"
  role            = aws_iam_role.lambda_redis_sync.arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      AWS_REDIS_ENDPOINT   = aws_elasticache_replication_group.main.primary_endpoint_address
      AZURE_REDIS_ENDPOINT = var.azure_redis_endpoint  # External Azure endpoint
      SYNC_INTERVAL       = "300"  # 5 minutes
    }
  }

  tags = var.common_tags
}

# IAM Role for Lambda Redis Sync
resource "aws_iam_role" "lambda_redis_sync" {
  name = "${var.name_prefix}-lambda-redis-sync-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}