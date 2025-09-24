# Network Topology & Security Zones

## AWS Network Architecture

### VPC Structure (10.0.0.0/16)
```
┌─────────────────────────────────────────────────────────────────┐
│ Production VPC (us-east-1)                                      │
├─────────────────────────────────────────────────────────────────┤
│ Public Subnets (DMZ Zone)                                      │
│ • 10.0.1.0/24 (us-east-1a) - ALB, NAT Gateway                 │
│ • 10.0.2.0/24 (us-east-1b) - ALB, NAT Gateway                 │
│ • 10.0.3.0/24 (us-east-1c) - ALB, NAT Gateway                 │
├─────────────────────────────────────────────────────────────────┤
│ Private Subnets (Application Zone)                             │
│ • 10.0.10.0/24 (us-east-1a) - EKS Worker Nodes                │
│ • 10.0.11.0/24 (us-east-1b) - EKS Worker Nodes                │
│ • 10.0.12.0/24 (us-east-1c) - EKS Worker Nodes                │
├─────────────────────────────────────────────────────────────────┤
│ Database Subnets (Data Zone)                                   │
│ • 10.0.20.0/24 (us-east-1a) - RDS, ElastiCache                │
│ • 10.0.21.0/24 (us-east-1b) - RDS, ElastiCache                │
│ • 10.0.22.0/24 (us-east-1c) - RDS, ElastiCache                │
├─────────────────────────────────────────────────────────────────┤
│ Management Subnets (Admin Zone)                                │
│ • 10.0.30.0/24 (us-east-1a) - Bastion, Monitoring             │
│ • 10.0.31.0/24 (us-east-1b) - Bastion, Monitoring             │
└─────────────────────────────────────────────────────────────────┘
```

## Azure Network Architecture

### Virtual Network Structure (10.1.0.0/16)
```
┌─────────────────────────────────────────────────────────────────┐
│ DR Virtual Network (East US 2)                                 │
├─────────────────────────────────────────────────────────────────┤
│ Public Subnets                                                 │
│ • 10.1.1.0/24 - Application Gateway, Load Balancer            │
│ • 10.1.2.0/24 - Application Gateway, Load Balancer            │
├─────────────────────────────────────────────────────────────────┤
│ Private Subnets                                                │
│ • 10.1.10.0/24 - AKS Worker Nodes                             │
│ • 10.1.11.0/24 - AKS Worker Nodes                             │
├─────────────────────────────────────────────────────────────────┤
│ Database Subnets                                               │
│ • 10.1.20.0/24 - Azure Database, Cache                        │
│ • 10.1.21.0/24 - Azure Database, Cache                        │
└─────────────────────────────────────────────────────────────────┘
```

## Security Zones & Controls

### Zone-Based Security
1. **Internet Zone** → **DMZ Zone**
   - WAF, DDoS protection
   - Rate limiting, geo-blocking
   - SSL termination

2. **DMZ Zone** → **Application Zone**
   - Application-level firewalls
   - API gateways with authentication
   - Container network policies

3. **Application Zone** → **Data Zone**
   - Database security groups
   - Encryption in transit (TLS 1.3)
   - Connection pooling limits

4. **Management Zone**
   - Bastion hosts with MFA
   - VPN access only
   - Audit logging

### Cross-Cloud Connectivity
- **Site-to-Site VPN**: AWS VGW ↔ Azure VPN Gateway
- **BGP Routing**: Dynamic route propagation
- **Encryption**: IPSec tunnels with AES-256
- **Bandwidth**: 10 Gbps dedicated connection