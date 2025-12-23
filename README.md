# AWS Customer Infrastructure Deployment

## Overview

This repository deploys AWS infrastructure for customers using a BOM (Bill of Materials) CSV-driven approach with strict append-only deployment rules.

## Key Principles

1. **BOM CSV is the single source of truth** - All infrastructure is defined in `bom/customer-bom.csv`
2. **Network foundation first** - Network stack is created once and never modified
3. **Append-only services** - Each service deployment creates a NEW stack, never updates existing ones
4. **Manual approval required** - All deployments require manual approval via GitHub Environments
5. **No resource replacement** - Existing resources are never updated or replaced

## Repository Structure

```
aws-infra/
├── .github/workflows/deploy.yml    # GitHub Actions workflow
├── network/network-foundation.yml  # Network CloudFormation template
├── services/                       # Service CloudFormation templates
├── bom/customer-bom.csv            # Bill of Materials (source of truth)
├── scripts/                        # BOM parsing and validation scripts
├── docs/                          # Documentation
└── README.md                      # This file
```

## Deployment Phases

### Phase 1: Network Foundation (One-time)
- Creates VPC, subnets, gateways
- Stack name: `<customer>-<env>-network-foundation`
- Never updated after creation

### Phase 2: Services (Append-only)
- Each service creates a NEW stack
- Stack name: `<customer>-<env>-<service>-<instance-id>`
- Existing stacks remain untouched

## Quick Start

1. Update `bom/customer-bom.csv` with your requirements
2. Commit and push changes
3. Run "Deploy Infrastructure" workflow
4. Approve deployment in GitHub Environments
5. Monitor deployment progress

## Adding New Services

To add a new service:
1. Add a new row to `bom/customer-bom.csv`
2. Commit the change
3. Run the deployment workflow
4. A NEW stack will be created (existing stacks unchanged)

## Safety Guarantees

- Network infrastructure is immutable
- Services are append-only (no updates)
- EC2 instances are never replaced
- Manual approval prevents accidental deployments
- BOM validation prevents invalid configurations

For detailed documentation, see the `docs/` directory.