# Azure Disaster Recovery Infrastructure

This directory contains Terraform configurations for deploying Azure disaster recovery infrastructure for the Multi-Cloud Financial Services Platform.

## Architecture Overview

The Azure DR setup provides:
- **AKS Cluster**: Warm standby Kubernetes cluster
- **PostgreSQL**: Flexible server for database replication
- **Redis Cache**: For session and cache replication
- **Application Gateway**: Load balancer with WAF protection
- **Storage Account**: For backup and static assets
- **VPN Gateway**: Cross-cloud connectivity to AWS
- **Monitoring**: Log Analytics and Application Insights

## Directory Structure

```
azureDR/
├── main.tf                    # Main configuration
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── azure-dr.tfvars           # Production variables
└── modules/
    ├── networking/            # VNet, subnets, NSGs
    ├── security/              # Key Vault, security policies
    ├── compute/               # AKS cluster
    ├── database/              # PostgreSQL, Redis, Storage
    ├── app-gateway/           # Application Gateway + WAF
    ├── monitoring/            # Log Analytics, App Insights
    └── vpn/                   # Cross-cloud VPN connectivity
```

## Deployment

### Prerequisites

1. **Azure CLI**: Install and authenticate
   ```bash
   az login
   az account set --subscription "your-subscription-id"
   ```

2. **Terraform**: Version >= 1.0
3. **Azure Subscription**: With appropriate permissions

### Environment Variables

Set required environment variables:
```bash
export TF_VAR_azure_subscription_id="your-subscription-id"
export TF_VAR_azure_tenant_id="your-tenant-id"
export TF_VAR_vpn_shared_key="your-vpn-shared-key"
```

### Deployment Steps

1. **Initialize Terraform**
   ```bash
   cd azureDR
   terraform init
   ```

2. **Plan Deployment**
   ```bash
   terraform plan -var-file="azure-dr.tfvars"
   ```

3. **Deploy Infrastructure**
   ```bash
   terraform apply -var-file="azure-dr.tfvars"
   ```

### Cross-Cloud VPN Setup

To enable cross-cloud connectivity:

1. **Enable VPN in tfvars**
   ```hcl
   enable_cross_cloud_vpn = true
   aws_vpn_gateway_ip    = "aws-vpn-gateway-public-ip"
   ```

2. **Configure AWS Side**
   - Create Customer Gateway in AWS pointing to Azure VPN Gateway IP
   - Create VPN Connection with matching shared key
   - Update route tables for cross-cloud traffic

## DR Activation

### Manual Failover Process

1. **Scale AKS Cluster**
   ```bash
   az aks scale --resource-group fintech-trading-platform-prod-dr-rg \
     --name fintech-trading-platform-prod-dr-aks --node-count 10
   ```

2. **Deploy Applications**
   ```bash
   kubectl apply -f k8s-manifests/ --context azure-dr
   ```

3. **Update DNS**
   - Point domain to Azure Application Gateway IP
   - Update Route 53 records for failover

### Automated Failover (Future)

- Azure Functions for DR orchestration
- Azure Monitor alerts for failure detection
- Automated scaling and deployment scripts

## Cost Optimization

### Warm Standby Mode (Default)
- **AKS**: 1 node (minimal cost)
- **Database**: Basic tier
- **Storage**: Cool tier
- **Estimated Cost**: $500-800/month

### Active-Active Mode
- **AKS**: 3+ nodes
- **Database**: Standard tier
- **Storage**: Hot tier
- **Estimated Cost**: $2000-3000/month

## Monitoring

### Azure Monitor Integration
- **Log Analytics**: Centralized logging
- **Application Insights**: APM and metrics
- **Alerts**: Email notifications for failures
- **Dashboards**: Real-time DR status

### Cross-Cloud Monitoring
- VPN connection status
- Database replication lag
- Application health checks
- Cost monitoring and alerts

## Security

### Network Security
- **NSGs**: Subnet-level security rules
- **Application Gateway WAF**: Web application firewall
- **Private Endpoints**: Secure database access
- **VPN Encryption**: IPSec tunnels to AWS

### Identity and Access
- **Azure AD Integration**: Single sign-on
- **Key Vault**: Secrets management
- **RBAC**: Role-based access control
- **Service Principals**: Automated access

## Compliance

### Data Residency
- All data stored in East US 2 region
- Cross-border data transfer via encrypted VPN
- Audit logs for compliance reporting

### Backup and Recovery
- **Database**: Point-in-time recovery (30 days)
- **Storage**: Geo-redundant backups
- **Configuration**: Infrastructure as Code
- **Testing**: Regular DR drills

## Troubleshooting

### Common Issues

1. **VPN Connection Failed**
   - Verify shared key matches AWS configuration
   - Check NSG rules allow VPN traffic
   - Validate gateway subnet configuration

2. **AKS Deployment Failed**
   - Ensure subnet has sufficient IP addresses
   - Verify service principal permissions
   - Check Azure resource quotas

3. **Database Connection Issues**
   - Validate subnet delegation for PostgreSQL
   - Check firewall rules and NSGs
   - Verify connection strings and credentials

### Support Contacts
- **Platform Team**: platform-team@company.com
- **Security Team**: security-team@company.com
- **Azure Support**: Via Azure Portal