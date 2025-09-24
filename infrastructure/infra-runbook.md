# Infrastructure Deployment Runbook
## Multi-Cloud Financial Trading Platform

### 🎯 Overview
This runbook provides step-by-step instructions for deploying the multi-cloud financial trading platform infrastructure using Terraform.

### 📋 Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0 installed
- Azure CLI (for DR setup)
- Domain name registered and managed in Route 53

---

## 🚀 Deployment Steps

### **Step 1: Environment Setup**
```bash
# Navigate to Terraform directory
cd /Users/syedhassan/testproj/AWS\ HIGH\ LEvel\ dig/infrastructure/terraform

# Verify Terraform installation
terraform version
```

### **Step 2: Fix Route 53 Conflicts**
```bash
# Remove duplicate Route 53 configuration to avoid conflicts
rm route53-dr.tf

# Verify removal
ls -la *.tf
```

### **Step 3: Configure Variables**
```bash
# Create terraform.tfvars file
cat > terraform.tfvars << EOF
# Project Configuration
project_name = "fintech-trading"
environment = "production"
aws_primary_region = "us-east-1"
aws_eu_region = "eu-west-1"
domain_name = "trading-platform.com"

# Feature Flags
enable_eu_region = true
enable_azure_dr = false

# Notification Configuration
notification_endpoints = ["admin@company.com", "devops@company.com"]

# Database Configuration (use AWS Secrets Manager in production)
rds_password = "your-secure-password-here"

# Optional: Azure DR Configuration (when enable_azure_dr = true)
# azure_app_gateway_fqdn = "dr.trading-platform.com"
# azure_app_gateway_ip = "20.1.2.3"
# azure_vpn_gateway_ip = "20.1.2.4"
# azure_postgres_fqdn = "postgres-dr.database.azure.com"
# azure_postgres_password = "azure-secure-password"
# azure_redis_hostname = "redis-dr.redis.cache.windows.net"
# azure_redis_key = "azure-redis-key"
EOF
```

### **Step 4: Initialize Terraform**
```bash
# Initialize Terraform backend and providers
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt
```

---

## 🏗️ Phased Deployment

### **Phase 1: Core Infrastructure**
```bash
# Deploy US networking
terraform apply -target=module.us_networking -auto-approve

# Deploy EU networking (if enabled)
terraform apply -target=module.eu_networking -auto-approve

# Deploy US security (includes CloudTrail)
terraform apply -target=module.us_security -auto-approve

# Deploy EU security (if enabled)
terraform apply -target=module.eu_security -auto-approve
```

### **Phase 2: Data Layer**
```bash
# Deploy US database infrastructure
terraform apply -target=module.us_database -auto-approve

# Deploy EU database infrastructure (if enabled)
terraform apply -target=module.eu_database -auto-approve
```

### **Phase 3: Compute & API**
```bash
# Deploy US EKS cluster
terraform apply -target=module.us_compute -auto-approve

# Deploy EU EKS cluster (if enabled)
terraform apply -target=module.eu_compute -auto-approve

# Deploy US API Gateway
terraform apply -target=module.us_api_gateway -auto-approve

# Deploy EU API Gateway (if enabled)
terraform apply -target=module.eu_api_gateway -auto-approve
```

### **Phase 4: Monitoring & Global Services**
```bash
# Deploy US monitoring
terraform apply -target=module.us_monitoring -auto-approve

# Deploy EU monitoring (if enabled)
terraform apply -target=module.eu_monitoring -auto-approve

# Deploy global CloudFront distribution
terraform apply -target=aws_cloudfront_distribution.global_static -auto-approve

# Deploy Route 53 records
terraform apply -target=aws_route53_record.api_eu_users -auto-approve
terraform apply -target=aws_route53_record.api_default_users -auto-approve
terraform apply -target=aws_route53_record.static_assets -auto-approve
```

### **Phase 5: Cross-Cloud Replication (Optional)**
```bash
# Only deploy if enable_azure_dr = true
# First deploy Azure DR infrastructure separately
cd ../azureDR
terraform init
terraform apply

# Return to main directory and deploy cross-cloud components
cd ../terraform
terraform apply -target=aws_dms_replication_instance.cross_cloud -auto-approve
terraform apply -target=aws_lambda_function.redis_replication -auto-approve
```

---

## 🚀 Alternative: Full Deployment
```bash
# Deploy everything at once (after fixing conflicts)
terraform plan -out=tfplan

# Review the plan carefully
terraform show tfplan

# Apply the complete infrastructure
terraform apply tfplan
```

---

## ✅ Post-Deployment Validation

### **Step 1: Verify Infrastructure**
```bash
# Check Terraform state
terraform show

# Get outputs
terraform output

# Verify resources in AWS Console
aws eks list-clusters --region us-east-1
aws rds describe-db-clusters --region us-east-1
```

### **Step 2: Test Connectivity**
```bash
# Update kubeconfig for EKS
aws eks update-kubeconfig --region us-east-1 --name fintech-trading-production-us-cluster

# Verify EKS connectivity
kubectl get nodes
kubectl get pods --all-namespaces
```

### **Step 3: Validate DNS Resolution**
```bash
# Test Route 53 routing
nslookup api.trading-platform.com
nslookup static.trading-platform.com

# Test health endpoints (once applications are deployed)
curl -k https://api.trading-platform.com/health
```

---

## 🔧 Troubleshooting

### **Common Issues**

#### **Route 53 Conflicts**
```bash
# Error: duplicate Route 53 records
# Solution: Ensure route53-dr.tf is removed
rm route53-dr.tf
terraform plan
```

#### **Module Dependencies**
```bash
# Error: module not found
# Solution: Ensure all modules exist
ls -la modules/
terraform get
```

#### **Permission Issues**
```bash
# Error: insufficient permissions
# Solution: Verify AWS credentials and policies
aws sts get-caller-identity
aws iam list-attached-user-policies --user-name your-username
```

#### **State Lock Issues**
```bash
# Error: state locked
# Solution: Force unlock (use carefully)
terraform force-unlock LOCK_ID
```

---

## 🧹 Cleanup (Destroy Infrastructure)

### **Reverse Order Destruction**
```bash
# Destroy in reverse order to avoid dependency issues
terraform destroy -target=aws_route53_record.api_eu_users
terraform destroy -target=aws_route53_record.api_default_users
terraform destroy -target=aws_cloudfront_distribution.global_static

terraform destroy -target=module.us_monitoring
terraform destroy -target=module.eu_monitoring

terraform destroy -target=module.us_api_gateway
terraform destroy -target=module.eu_api_gateway

terraform destroy -target=module.us_compute
terraform destroy -target=module.eu_compute

terraform destroy -target=module.us_database
terraform destroy -target=module.eu_database

terraform destroy -target=module.us_security
terraform destroy -target=module.eu_security

terraform destroy -target=module.us_networking
terraform destroy -target=module.eu_networking
```

### **Complete Destruction**
```bash
# Destroy everything (use with caution)
terraform destroy
```

---

## 📊 Cost Monitoring

### **Expected Monthly Costs**
- **Baseline (10K users)**: $3,277/month
- **Growth (25K users)**: $8,209/month  
- **Enterprise (50K users)**: $18,410/month

### **Cost Optimization**
- Use Reserved Instances for 30% savings
- Enable Spot Instances for non-critical workloads
- Monitor with AWS Cost Explorer
- Set up billing alerts

---

## 🔒 Security Checklist

- ✅ CloudTrail enabled for audit logging
- ✅ All data encrypted at rest and in transit
- ✅ Security groups follow least privilege
- ✅ KMS keys for encryption
- ✅ VPC isolation implemented
- ✅ WAF protection enabled

---

## 📞 Support Contacts

- **Platform Team**: platform-team@company.com
- **Security Team**: security@company.com
- **FinOps Team**: finops@company.com

---

**Last Updated**: December 2024  
**Version**: 1.0  
**Maintained By**: Platform Engineering Team