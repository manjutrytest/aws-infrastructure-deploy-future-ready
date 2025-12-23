# AWS Infrastructure as Code - CSV-Driven Deployment

## Overview

This repository provides a CSV-driven AWS infrastructure deployment solution using CloudFormation and GitHub Actions with OIDC authentication. Customer infrastructure requirements are defined entirely through CSV configuration files.

## Key Features

- **CSV-Driven**: All infrastructure requirements defined in CSV files
- **OIDC Authentication**: Secure GitHub Actions deployment without AWS keys
- **Environment Support**: Dev and Prod environments with same CSV structure
- **Option-Driven**: Create new or use existing resources
- **Extensible**: Designed for future services (ALB, RDS, ECS, EKS, etc.)
- **Dependency Management**: Automatic stack ordering and validation

## Repository Structure

```
aws-infra/
├── .github/workflows/
│   └── deploy.yml              # Main deployment workflow
├── bootstrap/
│   ├── oidc-provider.yml       # GitHub OIDC Provider
│   └── github-deploy-role.yml  # GitHub Deployment Role
├── foundation/
│   └── vpc.yml                 # VPC foundation stack
├── network/
│   ├── subnets.yml            # Subnet configuration
│   ├── igw.yml                # Internet Gateway
│   └── nat.yml                # NAT Gateway
├── security/
│   └── security-groups.yml    # Security Groups
├── compute/
│   └── ec2.yml                # EC2 instances
├── config/
│   ├── customer.csv           # CUSTOMER MODIFIES THIS FILE
│   ├── dev.json               # Dev environment parameters
│   └── prod.json              # Prod environment parameters
├── scripts/
│   └── parse-csv.sh           # CSV to CloudFormation parameters
└── docs/
    ├── architecture.md        # Architecture documentation
    └── dependency-map.md      # Dependency documentation
```

## Quick Start

### 1. Bootstrap Setup (One-time)

```bash
# Clone repository
git clone <your-repo-url>
cd aws-infra

# Deploy OIDC Provider
aws cloudformation deploy \
  --template-file bootstrap/oidc-provider.yml \
  --stack-name github-oidc-provider \
  --parameter-overrides GitHubOrganization=your-github-org RepositoryName=aws-infra

# Deploy GitHub Deploy Role
aws cloudformation deploy \
  --template-file bootstrap/github-deploy-role.yml \
  --stack-name github-deploy-role-dev \
  --parameter-overrides Environment=dev \
  --capabilities CAPABILITY_IAM
```

### 2. Configure GitHub

**Secrets** (Repository → Settings → Secrets):
- `AWS_ACCOUNT_ID`: Your AWS Account ID

**Variables**:
- `AWS_REGION`: Target region (default: ap-south-1)

**Environments**: Create `development` and `production` environments

### 3. Deploy Infrastructure

1. **Configure**: Edit `config/customer.csv` with your requirements
2. **Commit**: Push changes to main branch
3. **Deploy**: Run "Deploy AWS Infrastructure" GitHub Action
4. **Select**: Environment (dev/prod) and action (deploy)

### 4. Access Resources

```bash
# List deployed stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE

# Get EC2 instances
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev"
```

## CSV Configuration

The `config/customer.csv` file is the single source of truth for all infrastructure requirements. Modify this file to change your infrastructure.

### Supported Options

- **VPC**: CIDR, AZ count, create new or use existing
- **Subnets**: Public/private/both, custom CIDRs
- **NAT**: None/single/per-AZ
- **EC2**: OS, instance family/size, count, placement
- **Security**: New or existing security groups

## Environment Strategy

- **Dev Environment**: Deploy first for testing
- **Prod Environment**: Same CSV structure, different parameters
- **Promotion**: Validate in dev, then deploy to prod

## Adding New Services

The architecture supports future services through CSV rows:
- ALB (Application Load Balancer)
- RDS (Relational Database Service)
- ECS (Elastic Container Service)
- EKS (Elastic Kubernetes Service)
- Auto Scaling Groups
- VPC Endpoints

## Security

- OIDC-based authentication (no AWS keys in GitHub)
- Least privilege IAM roles
- Environment-based access controls
- Manual approval gates for production

## Support

For questions or issues, refer to the documentation in the `docs/` directory.

## Original Requirements

The original customer BOM (Bill of Materials) has been preserved in `config/original-bom.csv` for reference. The infrastructure defined in `config/customer.csv` implements these requirements:

- **EC2 Instance**: t3.medium Windows Server in Asia Pacific (Hyderabad)
- **VPC**: Public IPv4 address allocation
- **Security**: RDP access, web server capabilities
- **Storage**: 40GB EBS volume
- **Management**: SSM integration for secure access

## Documentation

- [Architecture Overview](docs/architecture.md) - System design and principles
- [CSV Configuration Guide](docs/csv-configuration-guide.md) - How to modify infrastructure via CSV
- [Deployment Guide](docs/deployment-guide.md) - Step-by-step deployment instructions
- [Dependency Map](docs/dependency-map.md) - Resource dependencies and deployment order

## Repository Structure Details

- **Bootstrap**: One-time OIDC and IAM role setup
- **Foundation**: VPC and core networking (created once, reused)
- **Network**: Subnets, gateways, and routing
- **Security**: Security groups and access controls
- **Compute**: EC2 instances and auto scaling
- **Config**: CSV requirements and environment parameters
- **Scripts**: CSV parsing and parameter generation
- **Docs**: Comprehensive documentation

This solution provides a production-ready, CSV-driven AWS infrastructure deployment platform that scales from simple web servers to complex multi-tier applications.