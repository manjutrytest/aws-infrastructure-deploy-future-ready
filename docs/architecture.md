# AWS Infrastructure Architecture

## Overview

This repository implements a BOM (Bill of Materials) driven AWS infrastructure deployment system with strict append-only deployment rules to ensure enterprise-grade safety and immutability.

## Architecture Principles

### 1. BOM-Driven Configuration
- **Single Source of Truth**: All infrastructure is defined in `bom/customer-bom.csv`
- **No Hard-Coding**: All values come from BOM or workflow inputs
- **Change Management**: Infrastructure changes require BOM updates only

### 2. Immutable Network Foundation
- **One-Time Deployment**: Network stack is created once and never modified
- **Retention Policy**: All network resources have `DeletionPolicy: Retain`
- **Export Values**: Network outputs are exported for service consumption

### 3. Append-Only Services
- **New Stacks Only**: Each service deployment creates a NEW CloudFormation stack
- **No Updates**: Existing service stacks are never updated or replaced
- **Instance IDs**: Unique instance IDs prevent stack name collisions
- **Resource Retention**: All service resources have `DeletionPolicy: Retain`

## Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Actions Workflow                  │
├─────────────────────────────────────────────────────────────┤
│ 1. BOM Validation                                          │
│ 2. Manual Approval (GitHub Environments)                   │
│ 3. Network Foundation (if needed)                          │
│ 4. Service Deployments (parallel, new stacks only)         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     AWS Account (eu-north-1)               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │            Network Foundation Stack                 │   │
│  │  • VPC                                             │   │
│  │  • Public/Private Subnets                          │   │
│  │  • Internet Gateway                                │   │
│  │  • NAT Gateways                                    │   │
│  │  • Route Tables                                    │   │
│  │  Stack: customer-env-network-foundation            │   │
│  └─────────────────────────────────────────────────────┘   │
│                              │                             │
│                              ▼                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │              Service Stacks (Append-Only)          │   │
│  │                                                     │   │
│  │  ┌─────────────────┐  ┌─────────────────┐          │   │
│  │  │ Web Service 001 │  │ Web Service 002 │          │   │
│  │  │ • EC2 Instances │  │ • EC2 Instances │          │   │
│  │  │ • Security Grps │  │ • Security Grps │          │   │
│  │  │ • Auto Scaling  │  │ • Auto Scaling  │          │   │
│  │  └─────────────────┘  └─────────────────┘          │   │
│  │                                                     │   │
│  │  ┌─────────────────┐  ┌─────────────────┐          │   │
│  │  │ Database 001    │  │ Bastion 001     │          │   │
│  │  │ • EC2 Instance  │  │ • EC2 Instance  │          │   │
│  │  │ • EBS Volumes   │  │ • Key Pair      │          │   │
│  │  │ • S3 Backups    │  │ • CloudWatch    │          │   │
│  │  └─────────────────┘  └─────────────────┘          │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Stack Naming Convention

### Network Stack
```
<customer>-<environment>-network-foundation
```
Examples:
- `acme-dev-network-foundation`
- `contoso-prod-network-foundation`

### Service Stacks
```
<customer>-<environment>-<service-name>-<instance-id>
```
Examples:
- `acme-dev-compute-web-001`
- `acme-dev-compute-web-002`
- `acme-dev-compute-database-001`
- `acme-dev-compute-bastion-001`

## Resource Tagging Strategy

All resources are tagged with:
- **Customer**: Customer name
- **Environment**: Environment (dev/staging/prod)
- **Service**: Service type (web/database/bastion)
- **InstanceId**: Instance ID for tracking

## Security Architecture

### Network Security
- **Private Subnets**: Database and internal services
- **Public Subnets**: Web services and bastion hosts
- **Security Groups**: Least privilege access
- **NACLs**: Additional network-level protection

### Access Control
- **IAM Roles**: Service-specific roles with minimal permissions
- **SSM Access**: Secure shell access without SSH keys
- **Bastion Hosts**: Secure access to private resources

### Encryption
- **EBS Volumes**: Encrypted at rest
- **S3 Buckets**: Server-side encryption
- **CloudWatch Logs**: Encrypted log storage

## Monitoring and Logging

### CloudWatch Integration
- **Instance Monitoring**: CPU, memory, disk metrics
- **Log Aggregation**: Centralized logging per service
- **Alarms**: Automated alerting for critical metrics

### Backup Strategy
- **Database Backups**: Automated S3 backups
- **EBS Snapshots**: Point-in-time recovery
- **Retention Policies**: Automated cleanup

## Disaster Recovery

### Network Recovery
- **Immutable Design**: Network can be recreated from BOM
- **Export Values**: Service dependencies preserved
- **Multi-AZ**: High availability across zones

### Service Recovery
- **Append-Only**: Failed deployments don't affect existing services
- **Independent Stacks**: Service failures are isolated
- **Data Persistence**: EBS volumes and S3 data retained

## Scaling Strategy

### Horizontal Scaling
- **New Instance IDs**: Deploy additional service instances
- **Load Distribution**: Auto Scaling Groups handle distribution
- **Independent Scaling**: Each service scales independently

### Vertical Scaling
- **New Deployments**: Deploy new instances with larger sizes
- **Gradual Migration**: Move workloads to new instances
- **Zero Downtime**: Old instances remain during transition

## Cost Optimization

### Resource Efficiency
- **Right-Sizing**: BOM-driven instance sizing
- **Spot Instances**: Optional for non-critical workloads
- **Reserved Instances**: Long-term cost savings

### Lifecycle Management
- **Automated Cleanup**: Old backup retention policies
- **Resource Tagging**: Cost allocation and tracking
- **Usage Monitoring**: CloudWatch cost metrics

## Compliance and Governance

### Change Management
- **BOM Approval**: All changes require BOM updates
- **Manual Approval**: GitHub Environments for deployment gates
- **Audit Trail**: Complete deployment history

### Security Compliance
- **Encryption**: Data at rest and in transit
- **Access Logging**: All access attempts logged
- **Least Privilege**: Minimal required permissions

### Operational Excellence
- **Infrastructure as Code**: All resources defined in templates
- **Version Control**: Complete change history
- **Automated Testing**: BOM validation and syntax checking