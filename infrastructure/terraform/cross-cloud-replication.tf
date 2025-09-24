# Cross-Cloud Database Replication
# AWS RDS → Azure PostgreSQL Real-time Sync

# DMS Replication Instance
resource "aws_dms_replication_instance" "cross_cloud" {
  allocated_storage            = 100
  apply_immediately           = true
  auto_minor_version_upgrade  = true
  availability_zone           = "us-east-1a"
  engine_version             = "3.5.2"
  multi_az                   = false
  preferred_maintenance_window = "sun:10:30-sun:14:30"
  publicly_accessible        = false
  replication_instance_class  = "dms.t3.medium"
  replication_instance_id     = "${local.name_prefix}-cross-cloud-replication"
  replication_subnet_group_id = aws_dms_replication_subnet_group.cross_cloud.id
  vpc_security_group_ids      = [aws_security_group.dms.id]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-dms-replication"
  })
}

# DMS Subnet Group
resource "aws_dms_replication_subnet_group" "cross_cloud" {
  replication_subnet_group_description = "DMS subnet group for cross-cloud replication"
  replication_subnet_group_id          = "${local.name_prefix}-dms-subnet-group"
  subnet_ids                           = module.us_networking.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-dms-subnet-group"
  })
}

# VPN Gateway for Cross-Cloud Connectivity
resource "aws_vpn_gateway" "cross_cloud" {
  count  = var.enable_azure_dr ? 1 : 0
  vpc_id = module.us_networking.vpc_id
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cross-cloud-vpn-gw"
  })
}

# Customer Gateway (Azure VPN Gateway)
resource "aws_customer_gateway" "azure" {
  count      = var.enable_azure_dr ? 1 : 0
  bgp_asn    = 65000
  ip_address = var.azure_vpn_gateway_ip
  type       = "ipsec.1"
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-azure-customer-gw"
  })
}

# VPN Connection to Azure
resource "aws_vpn_connection" "azure" {
  count               = var.enable_azure_dr ? 1 : 0
  vpn_gateway_id      = aws_vpn_gateway.cross_cloud[0].id
  customer_gateway_id = aws_customer_gateway.azure[0].id
  type                = "ipsec.1"
  static_routes_only  = true
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-azure-vpn-connection"
  })
}

# VPN Connection Route to Azure VNet
resource "aws_vpn_connection_route" "azure_vnet" {
  count                  = var.enable_azure_dr ? 1 : 0
  vpn_connection_id      = aws_vpn_connection.azure[0].id
  destination_cidr_block = "10.1.0.0/16"  # Azure VNet CIDR
}

# Route Table for VPN
resource "aws_route" "azure_vpn" {
  count                  = var.enable_azure_dr ? 1 : 0
  route_table_id         = module.us_networking.private_route_table_ids[0]
  destination_cidr_block = "10.1.0.0/16"
  vpn_gateway_id         = aws_vpn_gateway.cross_cloud[0].id
}

# DMS Security Group
resource "aws_security_group" "dms" {
  name_prefix = "${local.name_prefix}-dms-"
  vpc_id      = module.us_networking.vpc_id

  # Allow connection to AWS RDS
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "PostgreSQL from AWS VPC"
  }

  # Allow connection to Azure PostgreSQL via VPN
  egress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
    description = "PostgreSQL to Azure VNet"
  }

  # Allow HTTPS for DMS management
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for DMS management"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-dms-sg"
  })
}

# Source Endpoint (AWS RDS)
resource "aws_dms_endpoint" "source" {
  database_name   = "trading_db"
  endpoint_id     = "${local.name_prefix}-source-endpoint"
  endpoint_type   = "source"
  engine_name     = "postgres"
  password        = var.rds_password
  port            = 5432
  server_name     = module.us_database.rds_cluster_endpoint
  ssl_mode        = "require"
  username        = "postgres"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-source-endpoint"
  })
}

# Target Endpoint (Azure PostgreSQL)
resource "aws_dms_endpoint" "target" {
  count = var.enable_azure_dr ? 1 : 0
  
  database_name   = "trading_db"
  endpoint_id     = "${local.name_prefix}-target-endpoint"
  endpoint_type   = "target"
  engine_name     = "postgres"
  password        = var.azure_postgres_password
  port            = 5432
  server_name     = var.azure_postgres_fqdn
  ssl_mode        = "require"
  username        = "postgres"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-target-endpoint"
  })
}

# DMS Replication Task
resource "aws_dms_replication_task" "cross_cloud" {
  count = var.enable_azure_dr ? 1 : 0
  
  migration_type           = "full-load-and-cdc"  # Full load + Change Data Capture
  replication_instance_arn = aws_dms_replication_instance.cross_cloud.replication_instance_arn
  replication_task_id      = "${local.name_prefix}-cross-cloud-task"
  source_endpoint_arn      = aws_dms_endpoint.source.endpoint_arn
  target_endpoint_arn      = aws_dms_endpoint.target[0].endpoint_arn

  table_mappings = jsonencode({
    rules = [
      {
        rule-type = "selection"
        rule-id   = "1"
        rule-name = "1"
        object-locator = {
          schema-name = "public"
          table-name  = "%"
        }
        rule-action = "include"
      }
    ]
  })

  replication_task_settings = jsonencode({
    TargetMetadata = {
      TargetSchema                 = ""
      SupportLobs                  = true
      FullLobMode                  = false
      LobChunkSize                 = 0
      LimitedSizeLobMode           = true
      LobMaxSize                   = 32
      InlineLobMaxSize            = 0
      LoadMaxFileSize             = 0
      ParallelLoadThreads         = 0
      ParallelLoadBufferSize      = 0
      BatchApplyEnabled           = false
      TaskRecoveryTableEnabled    = false
      ParallelApplyThreads        = 0
      ParallelApplyBufferSize     = 0
      ParallelApplyQueuesPerThread = 0
    }
    FullLoadSettings = {
      TargetTablePrepMode          = "DROP_AND_CREATE"
      CreatePkAfterFullLoad        = false
      StopTaskCachedChangesApplied = false
      StopTaskCachedChangesNotApplied = false
      MaxFullLoadSubTasks          = 8
      TransactionConsistencyTimeout = 600
      CommitRate                   = 10000
    }
    Logging = {
      EnableLogging = true
    }
  })

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-cross-cloud-replication-task"
  })
}

# Lambda Function for Redis Replication
resource "aws_lambda_function" "redis_replication" {
  count = var.enable_azure_dr ? 1 : 0
  
  filename         = "redis_replication.zip"
  function_name    = "${local.name_prefix}-redis-replication"
  role            = aws_iam_role.lambda_redis_replication[0].arn
  handler         = "index.handler"
  runtime         = "python3.9"
  timeout         = 300

  environment {
    variables = {
      AWS_REDIS_ENDPOINT    = module.us_database.redis_primary_endpoint
      AZURE_REDIS_ENDPOINT  = var.azure_redis_hostname
      AZURE_REDIS_KEY       = var.azure_redis_key
      REPLICATION_INTERVAL  = "30"  # seconds
    }
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-replication"
  })
}

# Lambda IAM Role
resource "aws_iam_role" "lambda_redis_replication" {
  count = var.enable_azure_dr ? 1 : 0
  
  name = "${local.name_prefix}-lambda-redis-replication"

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

  tags = local.common_tags
}

# Lambda IAM Policy
resource "aws_iam_role_policy" "lambda_redis_replication" {
  count = var.enable_azure_dr ? 1 : 0
  
  name = "${local.name_prefix}-lambda-redis-policy"
  role = aws_iam_role.lambda_redis_replication[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "elasticache:DescribeCacheClusters",
          "elasticache:DescribeReplicationGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Event Rule for Redis Replication
resource "aws_cloudwatch_event_rule" "redis_replication" {
  count = var.enable_azure_dr ? 1 : 0
  
  name                = "${local.name_prefix}-redis-replication-schedule"
  description         = "Trigger Redis replication every 30 seconds"
  schedule_expression = "rate(30 seconds)"

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-redis-replication-schedule"
  })
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "redis_replication" {
  count = var.enable_azure_dr ? 1 : 0
  
  rule      = aws_cloudwatch_event_rule.redis_replication[0].name
  target_id = "RedisReplicationTarget"
  arn       = aws_lambda_function.redis_replication[0].arn
}

# Lambda Permission for CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  count = var.enable_azure_dr ? 1 : 0
  
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.redis_replication[0].function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.redis_replication[0].arn
}