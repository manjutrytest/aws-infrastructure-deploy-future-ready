# Infrastructure Dependency Map

## Stack Deployment Order

The infrastructure stacks must be deployed in the following order to satisfy dependencies:

```
1. Bootstrap (One-time)
   ├── OIDC Provider
   └── GitHub Deploy Role

2. Foundation
   └── VPC

3. Network (Parallel after VPC)
   ├── Subnets
   ├── Internet Gateway
   └── NAT Gateway (depends on Subnets + IGW)

4. Security (Parallel after VPC)
   └── Security Groups

5. Compute (after Network + Security)
   └── EC2 Instances
```

## Detailed Dependencies

### VPC Stack
**Dependencies**: None (Foundation)
**Exports**:
- `${StackName}-VPCId`
- `${StackName}-VPCCidr`
- `${StackName}-AvailabilityZone1`
- `${StackName}-AvailabilityZone2`
- `${StackName}-Environment`

**Used By**: All other stacks

### Subnet Stack
**Dependencies**: VPC Stack
**Imports**:
- `${VPCStackName}-VPCId`
- `${VPCStackName}-AvailabilityZone1`
- `${VPCStackName}-AvailabilityZone2`

**Exports**:
- `${StackName}-PublicSubnet1Id`
- `${StackName}-PublicSubnet2Id`
- `${StackName}-PrivateSubnet1Id`
- `${StackName}-PrivateSubnet2Id`
- `${StackName}-PublicSubnets`
- `${StackName}-PrivateSubnets`

**Used By**: IGW, NAT, EC2

### Internet Gateway Stack
**Dependencies**: VPC Stack, Subnet Stack
**Imports**:
- `${VPCStackName}-VPCId`
- `${SubnetStackName}-PublicSubnet1Id`
- `${SubnetStackName}-PublicSubnet2Id`

**Exports**:
- `${StackName}-InternetGatewayId`
- `${StackName}-PublicRouteTableId`

**Used By**: NAT Gateway (for routing)

### NAT Gateway Stack
**Dependencies**: VPC Stack, Subnet Stack, IGW Stack
**Imports**:
- `${VPCStackName}-VPCId`
- `${SubnetStackName}-PublicSubnet1Id`
- `${SubnetStackName}-PublicSubnet2Id`
- `${SubnetStackName}-PrivateSubnet1Id`
- `${SubnetStackName}-PrivateSubnet2Id`

**Exports**:
- `${StackName}-NatGateway1Id`
- `${StackName}-NatGateway2Id` (if per-AZ)
- `${StackName}-PrivateRouteTable1Id`
- `${StackName}-PrivateRouteTable2Id` (if per-AZ)

**Used By**: None (terminal for network layer)

### Security Group Stack
**Dependencies**: VPC Stack
**Imports**:
- `${VPCStackName}-VPCId`
- `${VPCStackName}-VPCCidr`

**Exports**:
- `${StackName}-WebSecurityGroupId`
- `${StackName}-DatabaseSecurityGroupId`
- `${StackName}-LoadBalancerSecurityGroupId`

**Used By**: EC2, RDS (future), ALB (future)

### EC2 Stack
**Dependencies**: VPC Stack, Subnet Stack, Security Group Stack
**Imports**:
- `${VPCStackName}-VPCId`
- `${SubnetStackName}-PublicSubnet1Id`
- `${SubnetStackName}-PublicSubnet2Id`
- `${SubnetStackName}-PrivateSubnet1Id`
- `${SubnetStackName}-PrivateSubnet2Id`
- `${SecurityGroupStackName}-WebSecurityGroupId`

**Exports**:
- `${StackName}-LaunchTemplateId`
- `${StackName}-AutoScalingGroupName`
- `${StackName}-InstanceType`
- `${StackName}-OperatingSystem`

**Used By**: ALB (future), Auto Scaling Policies (future)

## CSV-Driven Dependencies

The CSV configuration determines which stacks are deployed:

### Resource Type Dependencies
```
VPC → Required for all other resources
├── Subnet → Required for EC2, RDS, ALB
├── InternetGateway → Required for public access
├── NATGateway → Optional, depends on Subnet + IGW
├── SecurityGroup → Required for EC2, RDS, ALB
└── EC2 → Depends on Subnet + SecurityGroup
```

### Conditional Deployment
Stacks are only deployed if CSV contains relevant resources:

- **VPC Stack**: Deploy if any VPC resource in CSV
- **Subnet Stack**: Deploy if any Subnet resource in CSV
- **IGW Stack**: Deploy if any InternetGateway resource in CSV
- **NAT Stack**: Deploy if any NATGateway resource in CSV
- **Security Group Stack**: Deploy if any SecurityGroup resource in CSV
- **EC2 Stack**: Deploy if any EC2 resource in CSV

## Future Service Dependencies

### Application Load Balancer
**Dependencies**: VPC, Subnet, Security Group, EC2
**Will Import**:
- VPC ID for ALB placement
- Public subnet IDs for internet-facing ALB
- Private subnet IDs for internal ALB
- Security group for ALB traffic
- EC2 Auto Scaling Group for target registration

### RDS Database
**Dependencies**: VPC, Subnet, Security Group
**Will Import**:
- VPC ID for DB subnet group
- Private subnet IDs for database placement
- Security group for database access
- VPC CIDR for security group rules

### ECS Service
**Dependencies**: VPC, Subnet, Security Group, ALB (optional)
**Will Import**:
- VPC ID for ECS cluster
- Private subnet IDs for task placement
- Security group for container access
- ALB target group for load balancing

### EKS Cluster
**Dependencies**: VPC, Subnet, Security Group
**Will Import**:
- VPC ID for cluster placement
- Private subnet IDs for node groups
- Public subnet IDs for load balancers
- Security groups for cluster communication

## Dependency Validation

The `parse-csv.sh` script validates dependencies:

1. **Resource Existence**: Ensures dependent resources exist in CSV
2. **Deployment Order**: Generates correct stack deployment sequence
3. **Parameter Passing**: Maps CSV values to CloudFormation parameters
4. **Conditional Logic**: Enables/disables stacks based on CSV content

## Error Handling

### Missing Dependencies
If a resource depends on a missing resource:
- Script fails with clear error message
- Deployment stops before CloudFormation execution
- User must add missing dependency to CSV

### Circular Dependencies
The architecture prevents circular dependencies:
- Foundation → Network → Security/Compute
- No back-references between layers
- Clear separation of concerns

### Stack Failure Recovery
If a stack deployment fails:
- Dependent stacks are not deployed
- Failed stack can be fixed and redeployed
- CloudFormation rollback protects existing resources
- Manual intervention may be required for complex failures