# BOM CSV Schema Documentation

## Overview

The BOM (Bill of Materials) CSV file is the single source of truth for all AWS infrastructure configuration. This document describes the schema, validation rules, and usage patterns.

## CSV Structure

### Required Columns

| Column | Description | Required | Type |
|--------|-------------|----------|------|
| `resource_type` | Type of resource (network/service) | Yes | String |
| `service_name` | Name of the service | Yes* | String |
| `instance_id` | Unique instance identifier | Yes* | String |
| `template` | CloudFormation template file | Yes* | String |
| `dependency` | Resource dependency | Yes | String |

*Required for service resources only

### Network Configuration Columns

| Column | Description | Default | Valid Values |
|--------|-------------|---------|--------------|
| `vpc_cidr` | VPC CIDR block | 10.0.0.0/16 | Valid IPv4 CIDR |
| `az_count` | Number of Availability Zones | 2 | 2, 3 |
| `create_public_subnets` | Create public subnets | true | true, false |
| `create_private_subnets` | Create private subnets | true | true, false |
| `nat_gateway_type` | NAT Gateway configuration | single | none, single, per-az |

### Service Configuration Columns

| Column | Description | Default | Valid Values |
|--------|-------------|---------|--------------|
| `service_type` | Type of service | - | web, database, bastion |
| `os_type` | Operating system | linux | linux, windows |
| `instance_family` | EC2 instance family | t3 | t3, t2, m5, m4, c5, c4, r5, r4 |
| `instance_size` | EC2 instance size | medium | nano, micro, small, medium, large, xlarge, 2xlarge, 4xlarge |
| `instance_count` | Number of instances | 1 | 1-10 |
| `subnet_selection` | Subnet type | private | public, private |
| `root_volume_size` | Root volume size (GB) | 20 | 8-1000 |
| `enable_ssm` | Enable Systems Manager | true | true, false |
| `description` | Resource description | - | Free text |

## Resource Types

### Network Resource

Network resources define the foundational networking infrastructure.

**Required Fields:**
- `resource_type`: Must be "network"
- `service_name`: Must be "network-foundation"
- `instance_id`: Must be "001"
- `template`: Must be "network-foundation.yml"
- `dependency`: Must be empty

**Example:**
```csv
resource_type,service_name,instance_id,template,dependency,vpc_cidr,az_count,create_public_subnets,create_private_subnets,nat_gateway_type,description
network,network-foundation,001,network-foundation.yml,,10.0.0.0/16,2,true,true,single,Network foundation with VPC and subnets
```

### Service Resource

Service resources define compute and application infrastructure.

**Required Fields:**
- `resource_type`: Must be "service"
- `service_name`: Service identifier (e.g., "compute-web")
- `instance_id`: 3-digit number (e.g., "001")
- `template`: CloudFormation template file (e.g., "compute-web.yml")
- `dependency`: Must be "network-foundation"

**Example:**
```csv
resource_type,service_name,instance_id,template,dependency,service_type,os_type,instance_family,instance_size,instance_count,subnet_selection,root_volume_size,enable_ssm,description
service,compute-web,001,compute-web.yml,network-foundation,web,linux,t3,medium,1,public,20,true,Web server in public subnet
```

## Validation Rules

### General Rules

1. **Required Columns**: All required columns must be present
2. **No Empty Rows**: Rows with empty `resource_type` are ignored
3. **Unique Services**: Each `service_name` + `instance_id` combination must be unique
4. **Template Files**: Template names must end with `.yml`

### Network Validation

1. **Single Network**: Only one network resource is allowed
2. **VPC CIDR**: Must be valid IPv4 CIDR with prefix length /16-/28
3. **Private Networks**: VPC CIDR should be in private IP ranges
4. **AZ Count**: Must be 2 or 3
5. **Boolean Fields**: Must be "true" or "false"
6. **NAT Type**: Must be "none", "single", or "per-az"

### Service Validation

1. **Instance ID Format**: Must be 3-digit number (001-999)
2. **Service Type**: Must be "web", "database", or "bastion"
3. **OS Type**: Must be "linux" or "windows"
4. **Instance Family**: Must be valid EC2 instance family
5. **Instance Size**: Must be valid EC2 instance size
6. **Instance Count**: Must be 1-10
7. **Subnet Selection**: Must be "public" or "private"
8. **Volume Size**: Must be 8-1000 GB
9. **Dependency**: Must be "network-foundation"

## Usage Patterns

### Adding New Services

To add a new service:

1. **Choose Instance ID**: Use next available 3-digit number
2. **Select Template**: Choose appropriate service template
3. **Configure Resources**: Set instance type, count, and storage
4. **Set Placement**: Choose public or private subnet
5. **Add Description**: Document the service purpose

### Scaling Services

To scale a service horizontally:

1. **New Instance ID**: Use different instance ID (e.g., 002, 003)
2. **Same Configuration**: Copy existing service configuration
3. **Adjust if Needed**: Modify instance count or size
4. **Deploy**: New stack will be created alongside existing ones

### Environment Promotion

To promote from dev to staging/prod:

1. **Copy BOM**: Use same BOM structure
2. **Update Environment**: Change environment parameter in workflow
3. **Adjust Sizing**: Increase instance sizes for production
4. **Review Security**: Ensure appropriate security groups

## Example BOM Files

### Minimal Setup
```csv
resource_type,service_name,instance_id,template,dependency,vpc_cidr,service_type,instance_family,instance_size,subnet_selection,description
network,network-foundation,001,network-foundation.yml,,10.0.0.0/16,,,,,Basic VPC with public and private subnets
service,compute-web,001,compute-web.yml,network-foundation,,web,t3,small,public,Simple web server
```

### Complete Setup
```csv
resource_type,service_name,instance_id,template,dependency,vpc_cidr,az_count,create_public_subnets,create_private_subnets,nat_gateway_type,service_type,os_type,instance_family,instance_size,instance_count,subnet_selection,root_volume_size,enable_ssm,description
network,network-foundation,001,network-foundation.yml,,10.0.0.0/16,3,true,true,per-az,,,,,,,,,Multi-AZ network with NAT gateways per AZ
service,compute-web,001,compute-web.yml,network-foundation,,,,,,,web,linux,t3,medium,2,public,20,true,Load-balanced web servers
service,compute-web,002,compute-web.yml,network-foundation,,,,,,,web,linux,t3,large,1,public,30,true,High-performance web server
service,compute-database,001,compute-database.yml,network-foundation,,,,,,,database,linux,r5,large,1,private,100,true,Primary database server
service,compute-bastion,001,compute-bastion.yml,network-foundation,,,,,,,bastion,linux,t3,micro,1,public,10,true,Secure access bastion
```

## Best Practices

### Naming Conventions

1. **Service Names**: Use descriptive names (compute-web, compute-db, storage-cache)
2. **Instance IDs**: Use sequential 3-digit numbers (001, 002, 003)
3. **Descriptions**: Include purpose and key characteristics

### Resource Planning

1. **Start Small**: Begin with smaller instance sizes
2. **Plan Growth**: Use sequential instance IDs for scaling
3. **Separate Concerns**: Different services for different functions
4. **Consider Placement**: Public vs private subnet selection

### Security Considerations

1. **Least Privilege**: Only enable required features
2. **Private by Default**: Use private subnets unless public access needed
3. **Enable SSM**: Use Systems Manager for secure access
4. **Document Access**: Clear descriptions of access requirements

### Change Management

1. **Version Control**: Commit BOM changes with clear messages
2. **Review Process**: Have changes reviewed before deployment
3. **Test First**: Deploy to dev environment first
4. **Rollback Plan**: Keep previous BOM versions for rollback

## Troubleshooting

### Common Validation Errors

1. **Missing Columns**: Ensure all required columns are present
2. **Invalid CIDR**: Check VPC CIDR format and range
3. **Duplicate Services**: Each service+instance combination must be unique
4. **Invalid Instance Types**: Verify instance family and size combinations
5. **Template Not Found**: Ensure template files exist in services/ directory

### Deployment Issues

1. **Stack Already Exists**: Use different instance ID for new deployments
2. **Network Not Found**: Ensure network stack is deployed first
3. **Subnet Not Available**: Check subnet selection matches network config
4. **Permission Denied**: Verify IAM role has required permissions