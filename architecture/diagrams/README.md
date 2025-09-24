# Draw.io Architecture Diagrams

This directory contains Draw.io compatible XML diagrams for the multi-cloud financial services platform.

## How to Use

1. **Open Draw.io**: Go to [app.diagrams.net](https://app.diagrams.net) or use the desktop app
2. **Import Diagram**: Click "File" → "Open from" → "Device" and select any `.drawio` file
3. **Edit**: Modify colors, shapes, text, and layout as needed
4. **Export**: Save as PNG, SVG, PDF, or other formats

## Available Diagrams

### 1. High-Level Architecture (`high-level-architecture.drawio`)
- **Purpose**: Overall multi-cloud system overview
- **Shows**: AWS primary, Azure DR, cross-cloud connectivity
- **Key Components**: EKS/AKS clusters, data layers, VPN connections
- **Colors**: 
  - Blue: AWS services
  - Red: Azure services  
  - Yellow: Shared/global services
  - Green: Container platforms

### 2. Network Topology (`network-topology.drawio`)
- **Purpose**: Detailed network design and security zones
- **Shows**: VPC/VNet structure, subnets, security boundaries
- **Key Components**: Public/private subnets, security groups, VPN gateways
- **Colors**:
  - Red: Public subnets (DMZ)
  - Green: Private subnets (Application)
  - Yellow: Database subnets (Data)
  - Purple: Management subnets (Admin)

### 3. Data Flow (`data-flow.drawio`)
- **Purpose**: Real-time trading order processing flow
- **Shows**: User request → order execution → cross-cloud sync
- **Key Components**: API Gateway, microservices, databases, message queues
- **Performance**: <100ms latency, 50K TPS throughput
- **Colors**:
  - Blue: API/Gateway services
  - Green: Core trading services
  - Red: Risk/security services
  - Orange: Data storage

### 4. Microservices Architecture (`microservices-architecture.drawio`)
- **Purpose**: Detailed service design and scaling
- **Shows**: Individual pods, auto-scaling, service mesh
- **Key Components**: Trading engine, order management, risk engine
- **Features**: HPA configuration, resource allocation, mTLS
- **Colors**:
  - Green: Core trading services
  - Blue: User/auth services
  - Red: Risk/audit services
  - Purple: Support services

## Customization Tips

### Color Scheme
- **AWS Services**: `#dae8fc` (light blue)
- **Azure Services**: `#f8cecc` (light red)
- **Containers**: `#d5e8d4` (light green)
- **Databases**: `#f0f0f0` (light gray)
- **Security**: `#f8cecc` (light red)
- **Networking**: `#fff2cc` (light yellow)

### Adding New Components
1. Right-click → Insert → Shape
2. Use consistent colors for service types
3. Add connection arrows with appropriate colors
4. Include resource specifications in labels

### Performance Annotations
- Add latency requirements as text labels
- Use different arrow styles for sync vs async
- Include throughput numbers near data flows
- Mark critical path components

## Export Recommendations

- **PNG**: For presentations and documentation
- **SVG**: For web embedding and scaling
- **PDF**: For formal architecture reviews
- **VSDX**: For Microsoft Visio compatibility