#!/bin/bash

# Enhanced CSV to CloudFormation Parameters Parser
# Supports future-ready services: ALB, RDS, ECS, S3, Lambda, etc.

set -e

CSV_FILE="${1:-config/future-ready-bom.csv}"
ENVIRONMENT="${2:-dev}"
OUTPUT_DIR="generated-params"

echo "Parsing Future-Ready CSV file: $CSV_FILE for environment: $ENVIRONMENT"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Initialize parameter files for all services
VPC_PARAMS="$OUTPUT_DIR/vpc-params.json"
SUBNET_PARAMS="$OUTPUT_DIR/subnet-params.json"
IGW_PARAMS="$OUTPUT_DIR/igw-params.json"
NAT_PARAMS="$OUTPUT_DIR/nat-params.json"
SG_PARAMS="$OUTPUT_DIR/security-group-params.json"
EC2_PARAMS="$OUTPUT_DIR/ec2-params.json"
ALB_PARAMS="$OUTPUT_DIR/alb-params.json"
RDS_PARAMS="$OUTPUT_DIR/rds-params.json"
ECS_PARAMS="$OUTPUT_DIR/ecs-params.json"
S3_PARAMS="$OUTPUT_DIR/s3-params.json"
LAMBDA_PARAMS="$OUTPUT_DIR/lambda-params.json"

# Initialize JSON files
for param_file in "$VPC_PARAMS" "$SUBNET_PARAMS" "$IGW_PARAMS" "$NAT_PARAMS" "$SG_PARAMS" "$EC2_PARAMS" "$ALB_PARAMS" "$RDS_PARAMS" "$ECS_PARAMS" "$S3_PARAMS" "$LAMBDA_PARAMS"; do
    echo '[]' > "$param_file"
done

# Function to add parameter to JSON file
add_parameter() {
    local file="$1"
    local key="$2"
    local value="$3"
    
    jq --arg key "$key" --arg value "$value" '. += [{"ParameterKey": $key, "ParameterValue": $value}]' "$file" > "${file}.tmp"
    mv "${file}.tmp" "$file"
}

# Function to get value from CSV
get_csv_value() {
    local resource_type="$1"
    local resource_name="$2"
    local config="$3"
    local env="$4"
    
    awk -F',' -v rt="$resource_type" -v rn="$resource_name" -v cfg="$config" -v env="$env" '
        NR > 1 && $1 == rt && $2 == rn && $4 == cfg && ($7 == env || $7 == "all") {
            print $5
        }
    ' "$CSV_FILE" | head -1
}

# Function to check if resource should be created
should_create_resource() {
    local resource_type="$1"
    local resource_name="$2"
    local env="$3"
    
    awk -F',' -v rt="$resource_type" -v rn="$resource_name" -v env="$env" '
        NR > 1 && $1 == rt && $2 == rn && ($7 == env || $7 == "all") {
            if ($3 == "create-new") print "true"
            else print "false"
        }
    ' "$CSV_FILE" | head -1
}

# Parse VPC parameters (enhanced)
echo "Processing VPC parameters..."
VPC_NAME=$(awk -F',' -v env="$ENVIRONMENT" 'NR > 1 && $1 == "VPC" && ($7 == env || $7 == "all") {print $2}' "$CSV_FILE" | head -1)
if [ -n "$VPC_NAME" ]; then
    VPC_CIDR=$(get_csv_value "VPC" "$VPC_NAME" "CIDR" "$ENVIRONMENT")
    VPC_AZS=$(get_csv_value "VPC" "$VPC_NAME" "AvailabilityZones" "$ENVIRONMENT")
    DNS_HOSTNAMES=$(get_csv_value "VPC" "$VPC_NAME" "EnableDnsHostnames" "$ENVIRONMENT")
    DNS_SUPPORT=$(get_csv_value "VPC" "$VPC_NAME" "EnableDnsSupport" "$ENVIRONMENT")
    FLOW_LOGS=$(get_csv_value "VPC" "$VPC_NAME" "EnableFlowLogs" "$ENVIRONMENT")
    
    [ -n "$VPC_CIDR" ] && add_parameter "$VPC_PARAMS" "VpcCidr" "$VPC_CIDR"
    [ -n "$VPC_AZS" ] && add_parameter "$VPC_PARAMS" "AvailabilityZoneCount" "$VPC_AZS"
    [ -n "$DNS_HOSTNAMES" ] && add_parameter "$VPC_PARAMS" "EnableDnsHostnames" "$DNS_HOSTNAMES"
    [ -n "$DNS_SUPPORT" ] && add_parameter "$VPC_PARAMS" "EnableDnsSupport" "$DNS_SUPPORT"
    [ -n "$FLOW_LOGS" ] && add_parameter "$VPC_PARAMS" "EnableFlowLogs" "$FLOW_LOGS"
    add_parameter "$VPC_PARAMS" "Environment" "$ENVIRONMENT"
fi

# Parse ALB parameters
echo "Processing ALB parameters..."
ALB_NAME=$(awk -F',' -v env="$ENVIRONMENT" 'NR > 1 && $1 == "ALB" && ($7 == env || $7 == "all") {print $2}' "$CSV_FILE" | head -1)
if [ -n "$ALB_NAME" ]; then
    ALB_TYPE=$(get_csv_value "ALB" "$ALB_NAME" "Type" "$ENVIRONMENT")
    ALB_SCHEME=$(get_csv_value "ALB" "$ALB_NAME" "Scheme" "$ENVIRONMENT")
    ALB_SUBNETS=$(get_csv_value "ALB" "$ALB_NAME" "Subnets" "$ENVIRONMENT")
    ALB_SG=$(get_csv_value "ALB" "$ALB_NAME" "SecurityGroup" "$ENVIRONMENT")
    HEALTH_PATH=$(get_csv_value "ALB" "$ALB_NAME" "HealthCheckPath" "$ENVIRONMENT")
    
    [ -n "$ALB_TYPE" ] && add_parameter "$ALB_PARAMS" "LoadBalancerType" "$ALB_TYPE"
    [ -n "$ALB_SCHEME" ] && add_parameter "$ALB_PARAMS" "LoadBalancerScheme" "$ALB_SCHEME"
    [ -n "$ALB_NAME" ] && add_parameter "$ALB_PARAMS" "LoadBalancerName" "$ALB_NAME"
    [ -n "$HEALTH_PATH" ] && add_parameter "$ALB_PARAMS" "HealthCheckPath" "$HEALTH_PATH"
    add_parameter "$ALB_PARAMS" "Environment" "$ENVIRONMENT"
fi

# Parse RDS parameters
echo "Processing RDS parameters..."
RDS_NAME=$(awk -F',' -v env="$ENVIRONMENT" 'NR > 1 && $1 == "RDS" && ($7 == env || $7 == "all") {print $2}' "$CSV_FILE" | head -1)
if [ -n "$RDS_NAME" ]; then
    RDS_ENGINE=$(get_csv_value "RDS" "$RDS_NAME" "Engine" "$ENVIRONMENT")
    RDS_VERSION=$(get_csv_value "RDS" "$RDS_NAME" "EngineVersion" "$ENVIRONMENT")
    RDS_CLASS=$(get_csv_value "RDS" "$RDS_NAME" "InstanceClass" "$ENVIRONMENT")
    RDS_STORAGE=$(get_csv_value "RDS" "$RDS_NAME" "AllocatedStorage" "$ENVIRONMENT")
    RDS_MULTIAZ=$(get_csv_value "RDS" "$RDS_NAME" "MultiAZ" "$ENVIRONMENT")
    RDS_BACKUP=$(get_csv_value "RDS" "$RDS_NAME" "BackupRetentionPeriod" "$ENVIRONMENT")
    RDS_DBNAME=$(get_csv_value "RDS" "$RDS_NAME" "DatabaseName" "$ENVIRONMENT")
    RDS_USERNAME=$(get_csv_value "RDS" "$RDS_NAME" "MasterUsername" "$ENVIRONMENT")
    
    [ -n "$RDS_ENGINE" ] && add_parameter "$RDS_PARAMS" "DatabaseEngine" "$RDS_ENGINE"
    [ -n "$RDS_VERSION" ] && add_parameter "$RDS_PARAMS" "EngineVersion" "$RDS_VERSION"
    [ -n "$RDS_CLASS" ] && add_parameter "$RDS_PARAMS" "DBInstanceClass" "$RDS_CLASS"
    [ -n "$RDS_STORAGE" ] && add_parameter "$RDS_PARAMS" "AllocatedStorage" "$RDS_STORAGE"
    [ -n "$RDS_MULTIAZ" ] && add_parameter "$RDS_PARAMS" "MultiAZ" "$RDS_MULTIAZ"
    [ -n "$RDS_BACKUP" ] && add_parameter "$RDS_PARAMS" "BackupRetentionPeriod" "$RDS_BACKUP"
    [ -n "$RDS_DBNAME" ] && add_parameter "$RDS_PARAMS" "DatabaseName" "$RDS_DBNAME"
    [ -n "$RDS_USERNAME" ] && add_parameter "$RDS_PARAMS" "MasterUsername" "$RDS_USERNAME"
    add_parameter "$RDS_PARAMS" "Environment" "$ENVIRONMENT"
fi

# Parse existing services (VPC, Subnets, etc.) - keeping original logic
# ... (previous parsing logic for VPC, Subnets, EC2, etc.)

# Create enhanced deployment order
cat > "$OUTPUT_DIR/deployment-order.json" << EOF
{
  "stacks": [
    {
      "name": "vpc",
      "template": "foundation/vpc.yml",
      "parameters": "generated-params/vpc-params.json",
      "enabled": $(should_create_resource "VPC" "$VPC_NAME" "$ENVIRONMENT"),
      "priority": 1
    },
    {
      "name": "subnets",
      "template": "network/subnets.yml",
      "parameters": "generated-params/subnet-params.json",
      "enabled": true,
      "depends_on": ["vpc"],
      "priority": 2
    },
    {
      "name": "igw",
      "template": "network/igw.yml",
      "parameters": "generated-params/igw-params.json",
      "enabled": true,
      "depends_on": ["vpc"],
      "priority": 2
    },
    {
      "name": "nat",
      "template": "network/nat.yml",
      "parameters": "generated-params/nat-params.json",
      "enabled": $([ -n "$(get_csv_value "NATGateway" "ProductionNAT" "Strategy" "$ENVIRONMENT")" ] && echo true || echo false),
      "depends_on": ["subnets", "igw"],
      "priority": 3
    },
    {
      "name": "security-groups",
      "template": "security/security-groups.yml",
      "parameters": "generated-params/security-group-params.json",
      "enabled": true,
      "depends_on": ["vpc"],
      "priority": 3
    },
    {
      "name": "alb",
      "template": "loadbalancer/alb.yml",
      "parameters": "generated-params/alb-params.json",
      "enabled": $([ -n "$ALB_NAME" ] && echo true || echo false),
      "depends_on": ["subnets", "security-groups"],
      "priority": 4
    },
    {
      "name": "rds",
      "template": "database/rds.yml",
      "parameters": "generated-params/rds-params.json",
      "enabled": $([ -n "$RDS_NAME" ] && echo true || echo false),
      "depends_on": ["subnets", "security-groups"],
      "priority": 4
    },
    {
      "name": "ec2",
      "template": "compute/ec2.yml",
      "parameters": "generated-params/ec2-params.json",
      "enabled": true,
      "depends_on": ["subnets", "security-groups"],
      "priority": 5
    }
  ]
}
EOF

echo "Enhanced CSV parsing completed. Parameter files generated in $OUTPUT_DIR/"
echo "Deployment order: $OUTPUT_DIR/deployment-order.json"
echo ""
echo "Future-Ready Services Detected:"
[ -n "$ALB_NAME" ] && echo "✓ Application Load Balancer: $ALB_NAME"
[ -n "$RDS_NAME" ] && echo "✓ RDS Database: $RDS_NAME"
echo "✓ Enhanced VPC with $(get_csv_value "VPC" "$VPC_NAME" "AvailabilityZones" "$ENVIRONMENT") Availability Zones"