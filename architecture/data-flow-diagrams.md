# Data Flow Diagrams

## Real-Time Trading Flow

### Order Processing Flow
```
User → CloudFront → ALB → API Gateway → Trading Service
                                            ↓
Market Data ← Kinesis ← Market Data Service ← Order Validation
    ↓                                           ↓
Risk Engine → Position Check → Order Queue → Execution Engine
    ↓                              ↓              ↓
Audit Log ← Database ← Order Status ← Trade Confirmation
    ↓
Cross-Cloud Sync → Azure Event Hubs
```

### Data Synchronization Flow
```
AWS Primary                          Azure DR
     ↓                                  ↑
┌─────────────┐                  ┌─────────────┐
│ RDS Aurora  │ ──── VPN ────→   │ PostgreSQL  │
│ (Master)    │                  │ (Replica)   │
└─────────────┘                  └─────────────┘
     ↓                                  ↑
┌─────────────┐                  ┌─────────────┐
│ ElastiCache │ ──── Sync ────→  │ Azure Cache │
│ Redis       │                  │ Redis       │
└─────────────┘                  └─────────────┘
     ↓                                  ↑
┌─────────────┐                  ┌─────────────┐
│ S3 Bucket   │ ──── Repl ────→  │ Blob Storage│
│ (Encrypted) │                  │ (Encrypted) │
└─────────────┘                  └─────────────┘
```

## Compliance Data Flows

### GDPR Data Residency
```
EU Users → Route 53 → eu-west-1 (Frankfurt)
    ↓
┌─────────────────────────────────────────┐
│ EU-Specific Infrastructure              │
├─────────────────────────────────────────┤
│ • EKS Cluster (EU region)              │
│ • RDS Aurora (EU region)               │
│ • ElastiCache (EU region)              │
│ • S3 Buckets (EU region)               │
└─────────────────────────────────────────┘
    ↓
Data Processing (GDPR compliant)
    ↓
Audit Logs → CloudTrail (EU region)
```

### PCI-DSS Payment Flow
```
Payment Request → WAF → TLS 1.3 → Payment Service
                                        ↓
                              Tokenization Service
                                        ↓
                              Encrypted Card Data
                                        ↓
                              PCI-Compliant Vault
                                        ↓
                              Payment Processor API
                                        ↓
                              Transaction Response
                                        ↓
                              Audit Trail → SIEM
```

## Monitoring & Observability Flow
```
Application Metrics → CloudWatch → Grafana Dashboard
        ↓                ↓              ↓
    Prometheus ← EKS Pods → X-Ray → Distributed Tracing
        ↓                              ↓
    AlertManager → PagerDuty → Incident Response
        ↓
Cross-Cloud Metrics → Azure Monitor → Unified Dashboard
```

## Disaster Recovery Flow
```
Primary Failure Detection
    ↓
Route 53 Health Check Failure
    ↓
DNS Failover to Azure
    ↓
Azure Front Door → AKS Cluster
    ↓
Scale Up DR Infrastructure
    ↓
Data Sync Validation
    ↓
Service Restoration
    ↓
Monitoring & Alerting
```

## Security Event Flow
```
Security Event → CloudTrail/Azure Activity Log
    ↓
SIEM (Splunk/Sentinel) → Correlation Rules
    ↓
Threat Detection → Automated Response
    ↓
Incident Creation → Security Team Alert
    ↓
Forensic Analysis → Compliance Reporting
```