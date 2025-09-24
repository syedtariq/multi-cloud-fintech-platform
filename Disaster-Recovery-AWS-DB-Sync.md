# Disaster Recovery - AWS Database Synchronization to Azure

## Overview

This document outlines the complete setup for real-time database and cache synchronization from AWS to Azure for disaster recovery purposes. The solution provides automated cross-cloud replication with minimal latency to ensure business continuity.

## Architecture Components

### AWS Services Used
- **AWS DMS (Database Migration Service)**: PostgreSQL replication with Change Data Capture
- **AWS Lambda**: Redis cache synchronization
- **AWS VPN Gateway**: Secure cross-cloud connectivity
- **AWS CloudWatch**: Monitoring and scheduling
- **AWS IAM**: Security and access management

### Azure Services Used
- **Azure PostgreSQL Flexible Server**: Target database for replication
- **Azure Redis Cache**: Target cache for synchronization
- **Azure VPN Gateway**: Cross-cloud network connectivity
- **Azure Virtual Network**: Secure network isolation

## Prerequisites

### AWS Requirements
1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0 installed
3. **VPC** with private subnets for DMS instance
4. **RDS Aurora PostgreSQL** as source database
5. **ElastiCache Redis** as source cache

### Azure Requirements
1. **Azure CLI** authenticated
2. **Azure subscription** with sufficient permissions
3. **Resource Group** for DR resources
4. **Virtual Network** with database subnet delegation
5. **PostgreSQL Flexible Server** deployed
6. **Redis Cache** instance created

## Step-by-Step Implementation

### Phase 1: Azure Infrastructure Deployment

#### 1.1 Deploy Azure DR Infrastructure
```bash
# Navigate to Azure DR directory
cd infrastructure/terraform/azureDR

# Initialize Terraform
terraform init

# Deploy Azure infrastructure
terraform apply -var-file="azure-dr.tfvars"
```

#### 1.2 Collect Azure Connection Details
```bash
# Get Azure PostgreSQL details
terraform output postgres_server_fqdn
terraform output postgres_server_name

# Get Azure Redis details
terraform output redis_cache_hostname
terraform output redis_cache_name

# Get Azure VPN Gateway IP
terraform output vpn_gateway_public_ip
```

### Phase 2: Cross-Cloud Network Connectivity

#### 2.1 Configure VPN Connection
```bash
# Set environment variables
export TF_VAR_azure_vpn_gateway_ip="<azure-vpn-gateway-ip>"
export TF_VAR_vpn_shared_key="<secure-shared-key>"

# Update AWS infrastructure with VPN configuration
cd ../  # Back to main terraform directory
terraform apply -var-file="prod.tfvars"
```

#### 2.2 Verify VPN Connectivity
```bash
# Check VPN connection status
aws ec2 describe-vpn-connections \
  --filters Name=tag:Name,Values=fintech-trading-platform-prod-azure-vpn-connection

# Verify route propagation
aws ec2 describe-route-tables \
  --filters Name=tag:Name,Values=fintech-trading-platform-prod-private-rt
```

### Phase 3: Database Replication Setup

#### 3.1 Configure DMS Endpoints
```bash
# Set database credentials
export TF_VAR_rds_password="<aws-rds-password>"
export TF_VAR_azure_postgres_password="<azure-postgres-password>"
export TF_VAR_azure_postgres_fqdn="<azure-postgres-fqdn>"

# Deploy DMS configuration
terraform apply -var-file="prod.tfvars" \
  -target=aws_dms_replication_instance.cross_cloud \
  -target=aws_dms_endpoint.source \
  -target=aws_dms_endpoint.target
```

#### 3.2 Test DMS Endpoints
```bash
# Test source endpoint (AWS RDS)
aws dms test-connection \
  --replication-instance-arn <dms-instance-arn> \
  --endpoint-arn <source-endpoint-arn>

# Test target endpoint (Azure PostgreSQL)
aws dms test-connection \
  --replication-instance-arn <dms-instance-arn> \
  --endpoint-arn <target-endpoint-arn>
```

#### 3.3 Create and Start Replication Task
```bash
# Deploy replication task
terraform apply -var-file="prod.tfvars" \
  -target=aws_dms_replication_task.cross_cloud

# Start replication task
aws dms start-replication-task \
  --replication-task-arn <replication-task-arn> \
  --start-replication-task-type start-replication
```

### Phase 4: Redis Cache Synchronization

#### 4.1 Package Lambda Function
```bash
# Navigate to lambda directory
cd lambda

# Install dependencies
pip install redis -t .

# Create deployment package
zip -r redis_replication.zip redis_replication.py redis/
```

#### 4.2 Deploy Lambda Function
```bash
# Set Redis connection details
export TF_VAR_azure_redis_hostname="<azure-redis-hostname>"
export TF_VAR_azure_redis_key="<azure-redis-access-key>"

# Deploy Lambda function and CloudWatch trigger
terraform apply -var-file="prod.tfvars" \
  -target=aws_lambda_function.redis_replication \
  -target=aws_cloudwatch_event_rule.redis_replication
```

#### 4.3 Test Lambda Function
```bash
# Invoke Lambda function manually
aws lambda invoke \
  --function-name fintech-trading-platform-prod-redis-replication \
  --payload '{}' \
  response.json

# Check execution logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/fintech-trading-platform-prod-redis-replication
```

## Monitoring and Validation

### Database Replication Monitoring

#### Check DMS Task Status
```bash
# Get replication task details
aws dms describe-replication-tasks \
  --filters Name=replication-task-id,Values=fintech-trading-platform-prod-cross-cloud-task

# Monitor replication statistics
aws dms describe-table-statistics \
  --replication-task-arn <replication-task-arn>
```

#### Monitor Replication Lag
```bash
# CloudWatch metrics for DMS
aws cloudwatch get-metric-statistics \
  --namespace AWS/DMS \
  --metric-name CDCLatencyTarget \
  --dimensions Name=ReplicationTaskArn,Value=<task-arn> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300 \
  --statistics Average
```

### Redis Synchronization Monitoring

#### Check Lambda Execution
```bash
# Get Lambda function metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Duration \
  --dimensions Name=FunctionName,Value=fintech-trading-platform-prod-redis-replication \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T01:00:00Z \
  --period 300 \
  --statistics Average,Maximum
```

#### Validate Data Synchronization
```bash
# Connect to AWS Redis
redis-cli -h <aws-redis-endpoint> -p 6379

# Connect to Azure Redis
redis-cli -h <azure-redis-hostname> -p 6380 -a <azure-redis-key> --tls

# Compare key counts
redis-cli -h <aws-redis-endpoint> -p 6379 INFO keyspace
redis-cli -h <azure-redis-hostname> -p 6380 -a <azure-redis-key> --tls INFO keyspace
```

## Performance Metrics

### Expected Replication Performance

| Component | Latency | Throughput | Notes |
|-----------|---------|------------|-------|
| **PostgreSQL (DMS)** | 2-5 seconds | 10,000 TPS | Change Data Capture |
| **Redis (Lambda)** | 30 seconds | All keys | Scheduled synchronization |
| **Network (VPN)** | <50ms | 10 Gbps | Cross-cloud connectivity |

### Key Performance Indicators

#### Database Replication
- **Replication Lag**: < 5 seconds (target)
- **Data Consistency**: 99.99%
- **Error Rate**: < 0.01%
- **Throughput**: 10,000+ transactions/second

#### Redis Synchronization
- **Sync Frequency**: Every 30 seconds
- **Key Coverage**: 100% of critical patterns
- **Success Rate**: > 99.9%
- **Execution Time**: < 60 seconds per sync

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. VPN Connection Failed
**Symptoms**: DMS cannot connect to Azure PostgreSQL
```bash
# Check VPN connection status
aws ec2 describe-vpn-connections --query 'VpnConnections[*].State'

# Verify shared key matches
# Check Azure VPN Gateway configuration
az network vnet-gateway show --name <gateway-name> --resource-group <rg-name>
```

**Solutions**:
- Verify shared key matches on both sides
- Check security group rules allow port 5432
- Ensure route tables include Azure VNet CIDR

#### 2. DMS Replication Task Failed
**Symptoms**: Replication task shows failed status
```bash
# Get detailed error information
aws dms describe-replication-tasks \
  --filters Name=replication-task-id,Values=<task-id> \
  --query 'ReplicationTasks[*].ReplicationTaskStats'
```

**Solutions**:
- Check source/target endpoint connectivity
- Verify database permissions for replication user
- Review CloudWatch logs for detailed errors
- Ensure sufficient storage on DMS instance

#### 3. Lambda Redis Sync Failing
**Symptoms**: Lambda function timing out or failing
```bash
# Check Lambda logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/<function-name> \
  --start-time 1640995200000
```

**Solutions**:
- Verify Redis connection strings and credentials
- Check VPC connectivity for Lambda function
- Increase Lambda timeout if processing large datasets
- Review Redis memory usage and key patterns

#### 4. High Replication Lag
**Symptoms**: DMS showing high CDCLatencyTarget metrics
```bash
# Monitor replication lag over time
aws cloudwatch get-metric-statistics \
  --namespace AWS/DMS \
  --metric-name CDCLatencyTarget \
  --dimensions Name=ReplicationTaskArn,Value=<arn> \
  --period 300 \
  --statistics Maximum
```

**Solutions**:
- Scale up DMS replication instance
- Optimize source database for CDC
- Check network bandwidth utilization
- Review table-level replication statistics

## Security Considerations

### Network Security
- **VPN Encryption**: IPSec tunnels with AES-256 encryption
- **Private Connectivity**: No public internet exposure for databases
- **Security Groups**: Restrictive rules for DMS and Lambda
- **Network ACLs**: Additional layer of network security

### Data Security
- **Encryption in Transit**: TLS 1.2+ for all database connections
- **Encryption at Rest**: Both AWS and Azure databases encrypted
- **Access Control**: IAM roles with least privilege principles
- **Audit Logging**: All replication activities logged and monitored

### Compliance
- **SOC 2**: Continuous monitoring and access controls
- **PCI-DSS**: Secure data transmission and storage
- **GDPR**: Data residency and privacy controls
- **Audit Trail**: Complete logging of all replication activities

## Cost Analysis

### Monthly Cost Breakdown

| Service | Configuration | Monthly Cost |
|---------|---------------|-------------|
| **AWS DMS Instance** | dms.t3.medium | $146 |
| **AWS VPN Gateway** | Standard VPN | $36 |
| **AWS Lambda** | 2,880 executions/month | $1 |
| **Azure VPN Gateway** | VpnGw1 | $27 |
| **Data Transfer** | Cross-cloud (estimated) | $50 |
| **CloudWatch Logs** | DMS + Lambda logs | $10 |
| **Total** | | **$270/month** |

### Cost Optimization Tips
- Use DMS instance only during business hours for non-critical replication
- Implement data compression for cross-cloud transfer
- Monitor and optimize Lambda execution frequency
- Use reserved instances for predictable workloads

## Disaster Recovery Activation

### Automated Failover Process
1. **Health Check Failure**: Route 53 detects AWS failure
2. **DNS Failover**: Traffic routes to Azure Application Gateway
3. **Database Promotion**: Azure PostgreSQL becomes primary
4. **Cache Warmup**: Redis cache populated from recent sync
5. **Application Scaling**: AKS cluster scales to handle traffic

### Manual Failover Steps
```bash
# 1. Stop DMS replication task
aws dms stop-replication-task --replication-task-arn <task-arn>

# 2. Promote Azure PostgreSQL (if needed)
az postgres flexible-server restart --name <server-name> --resource-group <rg-name>

# 3. Scale Azure AKS cluster
az aks scale --resource-group <rg-name> --name <cluster-name> --node-count 10

# 4. Update DNS to point to Azure
aws route53 change-resource-record-sets --hosted-zone-id <zone-id> --change-batch file://failover-dns.json

# 5. Deploy applications to Azure
kubectl apply -f k8s-manifests/ --context azure-dr
```

## Testing and Validation

### Regular DR Testing Schedule
- **Weekly**: Automated replication lag monitoring
- **Monthly**: Manual failover testing in staging environment
- **Quarterly**: Full DR drill with business validation
- **Annually**: Complete disaster recovery audit

### Test Scenarios
1. **Planned Failover**: Scheduled maintenance simulation
2. **Unplanned Failover**: Sudden AWS region failure
3. **Partial Failure**: Single service degradation
4. **Network Partition**: Cross-cloud connectivity loss
5. **Data Corruption**: Database integrity issues

## Support and Contacts

### Escalation Matrix
- **Level 1**: Platform Team (platform-team@company.com)
- **Level 2**: Database Team (dba-team@company.com)
- **Level 3**: Cloud Architecture Team (cloud-arch@company.com)
- **Emergency**: On-call Engineer (oncall@company.com)

### External Support
- **AWS Support**: Enterprise support plan
- **Azure Support**: Professional support plan
- **Vendor Support**: Database and application vendors

---

## Conclusion

This disaster recovery solution provides robust, automated database synchronization between AWS and Azure with minimal latency and high reliability. The combination of AWS DMS for PostgreSQL replication and Lambda-based Redis synchronization ensures comprehensive data protection and business continuity.

Regular monitoring, testing, and maintenance of this system are essential for maintaining optimal performance and ensuring successful disaster recovery when needed.