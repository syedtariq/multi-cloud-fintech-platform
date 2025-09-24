# AWS CLI Configuration Guide
## Financial Trading Platform Deployment

### 🎯 Overview
This guide provides step-by-step instructions for configuring AWS CLI with the necessary permissions to deploy the multi-cloud financial trading platform.

---

## 📋 Prerequisites
- AWS Account with administrative access
- AWS CLI v2 installed
- Access to AWS IAM console

---

## 🚀 Step-by-Step Setup

### **Step 1: Install AWS CLI v2**
```bash
# macOS (using Homebrew)
brew install awscli

# macOS (direct download)
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Verify installation
aws --version
```

### **Step 2: Create IAM User for Terraform**

#### **Option A: AWS Console (Recommended)**
1. **Login to AWS Console** → IAM → Users → Create User
2. **User Details**:
   - Username: `terraform-fintech-platform`
   - Access type: ✅ Programmatic access
3. **Attach Policies** (see Step 3 for detailed permissions)
4. **Download credentials** (Access Key ID + Secret Access Key)

#### **Option B: AWS CLI (if you have admin access)**
```bash
# Create IAM user
aws iam create-user --user-name terraform-fintech-platform

# Create access key
aws iam create-access-key --user-name terraform-fintech-platform
```

### **Step 3: Required IAM Permissions**

#### **Minimum Required Policies (Attach to User)**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "eks:*",
        "rds:*",
        "elasticache:*",
        "s3:*",
        "cloudfront:*",
        "route53:*",
        "iam:*",
        "kms:*",
        "logs:*",
        "cloudwatch:*",
        "sns:*",
        "sqs:*",
        "kinesis:*",
        "lambda:*",
        "events:*",
        "cloudtrail:*",
        "wafv2:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "application-autoscaling:*",
        "dms:*",
        "xray:*",
        "apigateway:*",
        "acm:*",
        "secretsmanager:*",
        "ssm:*",
        "sts:GetCallerIdentity",
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}
```

#### **AWS Managed Policies (Alternative - Less Secure)**
For quick setup, attach these managed policies:
- `PowerUserAccess`
- `IAMFullAccess`

### **Step 4: Configure AWS CLI**
```bash
# Configure AWS CLI with your credentials
aws configure

# Enter the following when prompted:
# AWS Access Key ID: [Your Access Key from Step 2]
# AWS Secret Access Key: [Your Secret Key from Step 2]
# Default region name: us-east-1
# Default output format: json
```

### **Step 5: Configure Additional Profiles (Multi-Region)**
```bash
# Configure EU region profile
aws configure --profile eu-region
# AWS Access Key ID: [Same as above]
# AWS Secret Access Key: [Same as above]
# Default region name: eu-west-1
# Default output format: json

# Set environment variable for default profile
export AWS_PROFILE=default
```

### **Step 6: Verify Configuration**
```bash
# Test AWS CLI connectivity
aws sts get-caller-identity

# Expected output:
# {
#     "UserId": "AIDACKCEVSQ6C2EXAMPLE",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/terraform-fintech-platform"
# }

# Test permissions
aws ec2 describe-regions
aws eks list-clusters
aws rds describe-db-instances
```

---

## 🔒 Security Best Practices

### **Step 7: Enable MFA (Recommended)**
```bash
# Create MFA device (replace with your device serial)
aws iam create-virtual-mfa-device \
    --virtual-mfa-device-name terraform-fintech-mfa \
    --outfile QRCode.png \
    --bootstrap-method QRCodePNG

# Enable MFA for user
aws iam enable-mfa-device \
    --user-name terraform-fintech-platform \
    --serial-number arn:aws:iam::123456789012:mfa/terraform-fintech-mfa \
    --authentication-code-1 123456 \
    --authentication-code-2 789012
```

### **Step 8: Use AWS Profiles for Different Environments**
```bash
# Create profiles for different environments
aws configure --profile fintech-dev
aws configure --profile fintech-staging  
aws configure --profile fintech-prod

# Use specific profile
export AWS_PROFILE=fintech-prod
# or
aws s3 ls --profile fintech-prod
```

### **Step 9: Secure Credential Storage**
```bash
# View current configuration
aws configure list

# Configuration files location
ls -la ~/.aws/
# ~/.aws/credentials (contains access keys)
# ~/.aws/config (contains profiles and settings)

# Set proper permissions
chmod 600 ~/.aws/credentials
chmod 600 ~/.aws/config
```

---

## 🔧 Advanced Configuration

### **Cross-Account Role Assumption (Enterprise)**
```bash
# Configure role assumption for cross-account access
aws configure set role_arn arn:aws:iam::ACCOUNT-B:role/TerraformRole --profile cross-account
aws configure set source_profile default --profile cross-account

# Use cross-account profile
aws sts get-caller-identity --profile cross-account
```

### **Session Token for MFA**
```bash
# Get session token with MFA
aws sts get-session-token \
    --serial-number arn:aws:iam::123456789012:mfa/terraform-fintech-mfa \
    --token-code 123456

# Use temporary credentials
export AWS_ACCESS_KEY_ID=ASIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_SESSION_TOKEN=AQoDYXdzEJr...<remainder of session token>
```

---

## ✅ Validation Checklist

### **Test Required Services**
```bash
# Test VPC permissions
aws ec2 describe-vpcs

# Test EKS permissions  
aws eks describe-cluster --name test-cluster 2>/dev/null || echo "EKS permissions OK"

# Test RDS permissions
aws rds describe-db-instances

# Test S3 permissions
aws s3 ls

# Test Route 53 permissions
aws route53 list-hosted-zones

# Test CloudTrail permissions
aws cloudtrail describe-trails

# Test KMS permissions
aws kms list-keys

# Test IAM permissions
aws iam list-roles
```

### **Test Terraform Backend Access**
```bash
# Test S3 backend bucket access
aws s3 ls s3://fintech-platform-terraform-state/

# Test DynamoDB state lock table
aws dynamodb describe-table --table-name terraform-state-lock
```

---

## 🚨 Troubleshooting

### **Common Issues**

#### **Access Denied Errors**
```bash
# Check current identity
aws sts get-caller-identity

# Check attached policies
aws iam list-attached-user-policies --user-name terraform-fintech-platform

# Check inline policies
aws iam list-user-policies --user-name terraform-fintech-platform
```

#### **Region Issues**
```bash
# Check current region
aws configure get region

# Override region for specific command
aws ec2 describe-instances --region us-east-1
```

#### **Profile Issues**
```bash
# List all profiles
aws configure list-profiles

# Check specific profile
aws configure list --profile fintech-prod

# Switch profile
export AWS_PROFILE=fintech-prod
```

#### **MFA Issues**
```bash
# Check MFA devices
aws iam list-mfa-devices --user-name terraform-fintech-platform

# Get new session token
aws sts get-session-token --serial-number arn:aws:iam::123456789012:mfa/device-name --token-code 123456
```

---

## 📊 Cost Considerations

### **IAM User Costs**
- ✅ **IAM Users**: Free
- ✅ **Access Keys**: Free  
- ✅ **MFA Devices**: Free
- ⚠️ **API Calls**: Minimal cost for Terraform operations

### **Resource Costs**
- Monitor usage with AWS Cost Explorer
- Set up billing alerts for unexpected charges
- Use AWS Budgets for cost control

---

## 🔐 Security Recommendations

1. **✅ Use least privilege principle**
2. **✅ Enable MFA on all accounts**
3. **✅ Rotate access keys regularly (90 days)**
4. **✅ Use AWS Secrets Manager for sensitive data**
5. **✅ Enable CloudTrail for audit logging**
6. **✅ Monitor with AWS Config**
7. **✅ Use separate accounts for dev/staging/prod**

---

## 📞 Support

- **AWS Support**: Create support case in AWS Console
- **Documentation**: https://docs.aws.amazon.com/cli/
- **Platform Team**: platform-team@company.com

---

**Last Updated**: December 2024  
**Version**: 1.0  
**Maintained By**: Platform Engineering Team