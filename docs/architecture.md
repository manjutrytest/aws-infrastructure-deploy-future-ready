# AWS Infrastructure Architecture

## Overview

This repository implements a CSV-driven AWS infrastructure deployment solution that provides a scalable, maintainable, and secure approach to infrastructure as code.

## Architecture Principles

### 1. CSV as Single Source of Truth
- All infrastructure requirements defined in `config/customer.csv`
- No hard-coded values in templates or workflows
- Customer modifications require only CSV changes

### 2. Layered Stack Architecture
```
Bootstrap Layer (One-time setup)
├── OIDC Provider
└── GitHub Deploy Roles

Foundation Layer
└── VPC (Created once, reused forever)

Network Layer
├── Subnets (Public/Private)
├── Internet Gateway
└── NAT Gateway

Security Layer
└── Security Groups

Compute Layer
└── EC2 Instances
```

### 3. Dependency Management
- Stacks deployed in dependency order
- CloudFormation Outputs/ImportValue for resource sharing
- Conditional stack deployment based on CSV configuration

## Component Details

### VPC Foundation
- **Purpose**: Network foundation for all resources
- **Lifecycle**: Created once, never destroyed
- **Exports**: VPC ID, CIDR, Availability Zones
- **Features**: DNS support, Flow Logs, Multi-AZ

### Subnets
- **Public Subnets**: Internet-accessible resources
- **Private Subnets**: Internal resources with NAT access
- **Configuration**: CIDR blocks, AZ placement via CSV
- **Routing**: Automatic route table associations

### Internet Gateway
- **Purpose**: Internet access for public subnets
- **Attachment**: Automatic VPC attachment
- **Routing**: Default route (0.0.0.0/0) to IGW

### NAT Gateway
- **Strategies**: None, Single, Per-AZ
- **Purpose**: Outbound internet for private subnets
- **Cost Optimization**: Single NAT for dev, Per-AZ for prod

### Security Groups
- **Web Security Group**: HTTP/HTTPS/RDP access
- **Database Security Group**: Database access from web tier
- **Load Balancer Security Group**: ALB access (future)
- **Rules**: Defined via CSV configuration

### EC2 Instances
- **Operating Systems**: Amazon Linux, Ubuntu, RHEL, Windows
- **Instance Types**: t3, t3a, m5, m6i, c5, r5 families
- **Features**: Auto Scaling, SSM integration, encrypted storage
- **Placement**: Public or private subnets

## Security Architecture

### OIDC Authentication
- GitHub Actions authenticate via OIDC
- No AWS access keys stored in GitHub
- Environment-specific role assumption
- Least privilege permissions

### Network Security
- Private subnets for sensitive workloads
- Security groups with minimal required access
- VPC Flow Logs for monitoring
- Encrypted EBS volumes

### IAM Security
- Separate roles for dev/prod environments
- CloudFormation deployment permissions
- SSM access for instance management

## Scalability Design

### Horizontal Scaling
- Auto Scaling Groups for EC2 instances
- Multiple Availability Zone deployment
- Load balancer ready architecture

### Service Expansion
The architecture supports future services:
- **Application Load Balancer**: Target groups, listeners
- **RDS**: Multi-AZ, read replicas, parameter groups
- **ECS**: Clusters, services, task definitions
- **EKS**: Node groups, add-ons, IRSA
- **Auto Scaling**: Policies, CloudWatch alarms
- **VPC Endpoints**: S3, DynamoDB, other services

## Environment Strategy

### Development Environment
- Single NAT Gateway (cost optimization)
- Smaller instance types
- Shorter log retention
- Relaxed monitoring

### Production Environment
- Per-AZ NAT Gateways (high availability)
- Production instance types
- Extended log retention
- Detailed monitoring and alerting

### Environment Promotion
1. Test changes in development
2. Validate infrastructure and applications
3. Deploy same CSV configuration to production
4. Environment-specific parameters via JSON files

## Monitoring and Observability

### CloudWatch Integration
- VPC Flow Logs
- EC2 detailed monitoring (prod)
- CloudFormation stack events
- Custom metrics via CloudWatch Agent

### AWS Systems Manager
- Instance management without SSH/RDP
- Patch management
- Configuration compliance
- Session Manager for secure access

## Cost Optimization

### Resource Optimization
- Right-sized instances based on CSV configuration
- GP3 volumes for better price/performance
- Single NAT Gateway in development
- Automated resource tagging for cost allocation

### Lifecycle Management
- EBS volume encryption
- Automated backups via AWS Backup
- Resource cleanup via stack deletion

## Disaster Recovery

### Multi-AZ Deployment
- Resources distributed across AZs
- Database replication (when implemented)
- Load balancer health checks

### Backup Strategy
- EBS snapshots
- Cross-region replication (configurable)
- Point-in-time recovery for databases

## Future Enhancements

### Planned Services
1. **Application Load Balancer**
   - SSL termination
   - Path-based routing
   - Health checks

2. **RDS Database**
   - Multi-AZ deployment
   - Automated backups
   - Read replicas

3. **ECS/EKS Container Platform**
   - Microservices architecture
   - Auto scaling
   - Service mesh integration

4. **Additional Security**
   - WAF integration
   - GuardDuty threat detection
   - Config compliance rules

### Automation Enhancements
- Automated testing of infrastructure
- Blue/green deployments
- Canary releases
- Infrastructure drift detection