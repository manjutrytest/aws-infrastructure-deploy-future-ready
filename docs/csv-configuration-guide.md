# CSV Configuration Guide

## Overview

The `config/customer.csv` file is the single source of truth for all infrastructure requirements. This guide explains how to configure your infrastructure by modifying this CSV file.

## CSV Structure

The CSV file has the following columns:

| Column | Description | Example |
|--------|-------------|---------|
| ResourceType | Type of AWS resource | VPC, Subnet, EC2, SecurityGroup |
| ResourceName | Unique name for the resource | MainVPC, WebServer1 |
| Action | What to do with the resource | create-new, use-existing |
| Configuration | Specific configuration parameter | CIDR, InstanceType, OperatingSystem |
| Value | Value for the configuration | 10.0.0.0/16, t3.medium, Windows2022 |
| Dependencies | Resources this depends on | MainVPC, PublicSubnet1 |
| Environment | Target environment | dev, prod, all |

## Resource Types

### VPC Configuration

Configure your Virtual Private Cloud:

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
VPC,MainVPC,create-new,CIDR,10.0.0.0/16,,all
VPC,MainVPC,create-new,AvailabilityZones,2,,all
VPC,MainVPC,create-new,EnableDnsHostnames,true,,all
VPC,MainVPC,create-new,EnableDnsSupport,true,,all
```

**Configuration Options:**
- `CIDR`: VPC CIDR block (e.g., 10.0.0.0/16, 172.16.0.0/12)
- `AvailabilityZones`: Number of AZs to use (2-4)
- `EnableDnsHostnames`: Enable DNS hostnames (true/false)
- `EnableDnsSupport`: Enable DNS support (true/false)

### Subnet Configuration

Configure public and private subnets:

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
Subnet,PublicSubnet1,create-new,Type,public,MainVPC,all
Subnet,PublicSubnet1,create-new,CIDR,10.0.1.0/24,MainVPC,all
Subnet,PublicSubnet1,create-new,AvailabilityZone,0,MainVPC,all
Subnet,PrivateSubnet1,create-new,Type,private,MainVPC,all
Subnet,PrivateSubnet1,create-new,CIDR,10.0.10.0/24,MainVPC,all
Subnet,PrivateSubnet1,create-new,AvailabilityZone,0,MainVPC,all
```

**Configuration Options:**
- `Type`: public or private
- `CIDR`: Subnet CIDR block (must be within VPC CIDR)
- `AvailabilityZone`: AZ index (0, 1, 2, 3)

### Internet Gateway Configuration

Enable internet access for public subnets:

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
InternetGateway,MainIGW,create-new,AttachToVPC,MainVPC,MainVPC,all
```

### NAT Gateway Configuration

Configure NAT Gateway for private subnet internet access:

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
NATGateway,MainNAT,create-new,Strategy,single,PublicSubnet1,all
```

**Strategy Options:**
- `none`: No NAT Gateway (no internet for private subnets)
- `single`: One NAT Gateway (cost-effective)
- `per-az`: NAT Gateway per AZ (high availability)

### Security Group Configuration

Configure security groups and rules:

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
SecurityGroup,WebSecurityGroup,create-new,Description,Web server security group,MainVPC,all
SecurityGroup,WebSecurityGroup,create-new,InboundRule,HTTP:80:0.0.0.0/0,MainVPC,all
SecurityGroup,WebSecurityGroup,create-new,InboundRule,HTTPS:443:0.0.0.0/0,MainVPC,all
SecurityGroup,WebSecurityGroup,create-new,InboundRule,RDP:3389:10.0.0.0/16,MainVPC,all
```

**InboundRule Format:** `Protocol:Port:Source`
- Protocol: HTTP, HTTPS, SSH, RDP, TCP, UDP
- Port: Port number or range
- Source: CIDR block or security group reference

### EC2 Configuration

Configure EC2 instances:

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
EC2,WebServer1,create-new,OperatingSystem,Windows2022,WebSecurityGroup,all
EC2,WebServer1,create-new,InstanceFamily,t3,WebSecurityGroup,all
EC2,WebServer1,create-new,InstanceSize,medium,WebSecurityGroup,all
EC2,WebServer1,create-new,InstanceCount,1,WebSecurityGroup,all
EC2,WebServer1,create-new,SubnetType,public,PublicSubnet1,all
EC2,WebServer1,create-new,RootVolumeSize,40,WebSecurityGroup,all
EC2,WebServer1,create-new,RootVolumeType,gp3,WebSecurityGroup,all
EC2,WebServer1,create-new,EnableSSM,true,WebSecurityGroup,all
EC2,WebServer1,create-new,KeyPairName,my-keypair,WebSecurityGroup,all
```

**Operating System Options:**
- `AmazonLinux2`, `AmazonLinux2023`
- `Ubuntu2004`, `Ubuntu2204`
- `RHEL8`, `RHEL9`
- `Windows2019`, `Windows2022`

**Instance Family Options:**
- `t3`, `t3a` (Burstable)
- `m5`, `m6i` (General Purpose)
- `c5` (Compute Optimized)
- `r5` (Memory Optimized)

**Instance Size Options:**
- `micro`, `small`, `medium`, `large`, `xlarge`

**Volume Type Options:**
- `gp2`, `gp3` (General Purpose SSD)
- `io1`, `io2` (Provisioned IOPS SSD)

## Environment Configuration

### Environment-Specific Resources

Use the Environment column to target specific environments:

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
EC2,DevServer,create-new,InstanceSize,small,WebSecurityGroup,dev
EC2,ProdServer,create-new,InstanceSize,large,WebSecurityGroup,prod
```

### Universal Resources

Use `all` for resources needed in all environments:

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
VPC,MainVPC,create-new,CIDR,10.0.0.0/16,,all
```

## Action Types

### create-new
Creates a new resource with the specified configuration.

### use-existing
References an existing resource (future feature).

## Dependencies

Specify dependencies in the Dependencies column:

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
Subnet,PublicSubnet1,create-new,Type,public,MainVPC,all
EC2,WebServer1,create-new,OperatingSystem,Windows2022,WebSecurityGroup,all
```

## Example Configurations

### Basic Web Server Setup

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
VPC,MainVPC,create-new,CIDR,10.0.0.0/16,,all
VPC,MainVPC,create-new,AvailabilityZones,2,,all
Subnet,PublicSubnet1,create-new,Type,public,MainVPC,all
Subnet,PublicSubnet1,create-new,CIDR,10.0.1.0/24,MainVPC,all
InternetGateway,MainIGW,create-new,AttachToVPC,MainVPC,MainVPC,all
SecurityGroup,WebSG,create-new,Description,Web server access,MainVPC,all
SecurityGroup,WebSG,create-new,InboundRule,HTTP:80:0.0.0.0/0,MainVPC,all
SecurityGroup,WebSG,create-new,InboundRule,HTTPS:443:0.0.0.0/0,MainVPC,all
EC2,WebServer,create-new,OperatingSystem,AmazonLinux2023,WebSG,all
EC2,WebServer,create-new,InstanceFamily,t3,WebSG,all
EC2,WebServer,create-new,InstanceSize,small,WebSG,all
EC2,WebServer,create-new,SubnetType,public,PublicSubnet1,all
```

### Multi-Tier Application

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
VPC,AppVPC,create-new,CIDR,10.0.0.0/16,,all
Subnet,PublicSubnet1,create-new,Type,public,AppVPC,all
Subnet,PublicSubnet1,create-new,CIDR,10.0.1.0/24,AppVPC,all
Subnet,PrivateSubnet1,create-new,Type,private,AppVPC,all
Subnet,PrivateSubnet1,create-new,CIDR,10.0.10.0/24,AppVPC,all
InternetGateway,AppIGW,create-new,AttachToVPC,AppVPC,AppVPC,all
NATGateway,AppNAT,create-new,Strategy,single,PublicSubnet1,all
SecurityGroup,WebSG,create-new,Description,Web tier,AppVPC,all
SecurityGroup,WebSG,create-new,InboundRule,HTTP:80:0.0.0.0/0,AppVPC,all
SecurityGroup,AppSG,create-new,Description,App tier,AppVPC,all
SecurityGroup,AppSG,create-new,InboundRule,TCP:8080:WebSG,AppVPC,all
EC2,WebServer,create-new,OperatingSystem,Ubuntu2204,WebSG,all
EC2,WebServer,create-new,InstanceFamily,t3,WebSG,all
EC2,WebServer,create-new,InstanceSize,medium,WebSG,all
EC2,WebServer,create-new,SubnetType,public,PublicSubnet1,all
EC2,AppServer,create-new,OperatingSystem,Ubuntu2204,AppSG,all
EC2,AppServer,create-new,InstanceFamily,m5,AppSG,all
EC2,AppServer,create-new,InstanceSize,large,AppSG,all
EC2,AppServer,create-new,SubnetType,private,PrivateSubnet1,all
```

## Validation Rules

The CSV parser validates:

1. **Required Fields**: All columns must have values
2. **Dependencies**: Referenced resources must exist
3. **CIDR Blocks**: Must be valid and non-overlapping
4. **Instance Types**: Must be valid AWS instance types
5. **Regions**: AMI mappings must exist for target region

## Best Practices

1. **Naming Convention**: Use consistent, descriptive names
2. **CIDR Planning**: Plan IP address ranges carefully
3. **Security**: Follow least privilege for security groups
4. **Environment Separation**: Use environment column effectively
5. **Dependencies**: Clearly define resource dependencies
6. **Documentation**: Comment complex configurations

## Troubleshooting

### Common Issues

1. **Missing Dependencies**: Ensure all referenced resources exist in CSV
2. **CIDR Conflicts**: Check for overlapping IP ranges
3. **Invalid Values**: Verify configuration values are valid
4. **Environment Mismatch**: Check environment column values

### Validation Commands

```bash
# Parse and validate CSV
./scripts/parse-csv.sh config/customer.csv dev

# Check generated parameters
cat generated-params/deployment-order.json
```