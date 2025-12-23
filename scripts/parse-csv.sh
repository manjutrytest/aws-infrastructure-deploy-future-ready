#!/bin/bash

# CSV to CloudFormation Parameters Parser
# Converts customer.csv into CloudFormation parameter files

set -e

CSV_FILE="${1:-config/customer.csv}"
ENVIRONMENT="${2:-dev}"
OUTPUT_DIR="generated-params"

echo "Parsing CSV file: $CSV_FILE for environment: $ENVIRONMENT"

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Initialize parameter files
VPC_PARAMS="$OUTPUT_DIR/vpc-params.json"
SUBNET_PARAMS="$OUTPUT_DIR/subnet-params.json"
IGW_PARAMS="$OUTPUT_DIR/igw-params.json"
NAT_PARAMS="$OUTPUT_DIR/nat-params.json"
SG_PARAMS="$OUTPUT_DIR/security-group-params.json"
EC2_PARAMS="$OUTPUT_DIR/ec2-params.json"

# Initialize JSON files
echo '[]' > "$VPC_PARAMS"
echo '[]' > "$SUBNET_PARAMS"
echo '[]' > "$IGW_PARAMS"
echo '[]' > "$NAT_PARAMS"
echo '[]' > "$SG_PARAMS"
echo '[]' > "$EC2_PARAMS"

# Function to add parameter to JSON file
add_parameter() {
    local file="$1"
    local key="$2"
    local value="$3"
    
    # Create temporary file with updated parameters
    jq --arg key "$key" --arg value "$value" '. += [{"ParameterKey": $key, "ParameterValue": $value}]' "$file" > "${file}.tmp"
    mv "${file}.tmp" "$file"
}

# Function to get value from CSV for specific resource and configuration
get_csv_value() {
    local resource_type="$1"
    local resource_name="$2"
    local config="$3"
    local env="$4"
    
    # Skip header line and filter by resource type, name, configuration, and environment
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

# Parse VPC parameters
echo "Processing VPC parameters..."
VPC_NAME=$(awk -F',' -v env="$ENVIRONMENT" 'NR > 1 && $1 == "VPC" && ($7 == env || $7 == "all") {print $2}' "$CSV_FILE" | head -1)
if [ -n "$VPC_NAME" ]; then
    VPC_CIDR=$(get_csv_value "VPC" "$VPC_NAME" "CIDR" "$ENVIRONMENT")
    VPC_AZS=$(get_csv_value "VPC" "$VPC_NAME" "AvailabilityZones" "$ENVIRONMENT")
    DNS_HOSTNAMES=$(get_csv_value "VPC" "$VPC_NAME" "EnableDnsHostnames" "$ENVIRONMENT")
    DNS_SUPPORT=$(get_csv_value "VPC" "$VPC_NAME" "EnableDnsSupport" "$ENVIRONMENT")
    
    [ -n "$VPC_CIDR" ] && add_parameter "$VPC_PARAMS" "VpcCidr" "$VPC_CIDR"
    [ -n "$VPC_AZS" ] && add_parameter "$VPC_PARAMS" "AvailabilityZoneCount" "$VPC_AZS"
    [ -n "$DNS_HOSTNAMES" ] && add_parameter "$VPC_PARAMS" "EnableDnsHostnames" "$DNS_HOSTNAMES"
    [ -n "$DNS_SUPPORT" ] && add_parameter "$VPC_PARAMS" "EnableDnsSupport" "$DNS_SUPPORT"
    add_parameter "$VPC_PARAMS" "Environment" "$ENVIRONMENT"
fi

# Parse Subnet parameters
echo "Processing Subnet parameters..."
SUBNET_CIDRS=""
PUBLIC_SUBNET_COUNT=0
PRIVATE_SUBNET_COUNT=0

while IFS=',' read -r resource_type resource_name action config value deps env; do
    if [ "$resource_type" = "Subnet" ] && ([ "$env" = "$ENVIRONMENT" ] || [ "$env" = "all" ]); then
        if [ "$config" = "Type" ]; then
            if [ "$value" = "public" ]; then
                PUBLIC_SUBNET_COUNT=$((PUBLIC_SUBNET_COUNT + 1))
            elif [ "$value" = "private" ]; then
                PRIVATE_SUBNET_COUNT=$((PRIVATE_SUBNET_COUNT + 1))
            fi
        elif [ "$config" = "CIDR" ]; then
            if [ -z "$SUBNET_CIDRS" ]; then
                SUBNET_CIDRS="$value"
            else
                SUBNET_CIDRS="$SUBNET_CIDRS,$value"
            fi
        fi
    fi
done < <(tail -n +2 "$CSV_FILE")

[ "$PUBLIC_SUBNET_COUNT" -gt 0 ] && add_parameter "$SUBNET_PARAMS" "PublicSubnetCount" "$PUBLIC_SUBNET_COUNT"
[ "$PRIVATE_SUBNET_COUNT" -gt 0 ] && add_parameter "$SUBNET_PARAMS" "PrivateSubnetCount" "$PRIVATE_SUBNET_COUNT"
[ -n "$SUBNET_CIDRS" ] && add_parameter "$SUBNET_PARAMS" "SubnetCidrs" "$SUBNET_CIDRS"
add_parameter "$SUBNET_PARAMS" "Environment" "$ENVIRONMENT"

# Parse NAT Gateway parameters
echo "Processing NAT Gateway parameters..."
NAT_STRATEGY=$(get_csv_value "NATGateway" "MainNAT" "Strategy" "$ENVIRONMENT")
if [ -n "$NAT_STRATEGY" ]; then
    add_parameter "$NAT_PARAMS" "NatGatewayStrategy" "$NAT_STRATEGY"
    add_parameter "$NAT_PARAMS" "Environment" "$ENVIRONMENT"
fi

# Parse Security Group parameters
echo "Processing Security Group parameters..."
SG_COUNT=0
while IFS=',' read -r resource_type resource_name action config value deps env; do
    if [ "$resource_type" = "SecurityGroup" ] && ([ "$env" = "$ENVIRONMENT" ] || [ "$env" = "all" ]); then
        if [ "$config" = "Description" ]; then
            SG_COUNT=$((SG_COUNT + 1))
            add_parameter "$SG_PARAMS" "SecurityGroup${SG_COUNT}Name" "$resource_name"
            add_parameter "$SG_PARAMS" "SecurityGroup${SG_COUNT}Description" "$value"
        fi
    fi
done < <(tail -n +2 "$CSV_FILE")
add_parameter "$SG_PARAMS" "Environment" "$ENVIRONMENT"

# Parse EC2 parameters
echo "Processing EC2 parameters..."
EC2_INSTANCES=""
while IFS=',' read -r resource_type resource_name action config value deps env; do
    if [ "$resource_type" = "EC2" ] && ([ "$env" = "$ENVIRONMENT" ] || [ "$env" = "all" ]); then
        if [ "$config" = "OperatingSystem" ]; then
            OS="$value"
        elif [ "$config" = "InstanceFamily" ]; then
            FAMILY="$value"
        elif [ "$config" = "InstanceSize" ]; then
            SIZE="$value"
        elif [ "$config" = "InstanceCount" ]; then
            COUNT="$value"
        elif [ "$config" = "SubnetType" ]; then
            SUBNET_TYPE="$value"
        elif [ "$config" = "RootVolumeSize" ]; then
            VOLUME_SIZE="$value"
        elif [ "$config" = "RootVolumeType" ]; then
            VOLUME_TYPE="$value"
        elif [ "$config" = "EnableSSM" ]; then
            SSM_ENABLED="$value"
        elif [ "$config" = "KeyPairName" ]; then
            KEY_PAIR="$value"
            
            # Add all collected parameters for this instance
            add_parameter "$EC2_PARAMS" "InstanceName" "$resource_name"
            add_parameter "$EC2_PARAMS" "OperatingSystem" "$OS"
            add_parameter "$EC2_PARAMS" "InstanceType" "${FAMILY}.${SIZE}"
            add_parameter "$EC2_PARAMS" "InstanceCount" "$COUNT"
            add_parameter "$EC2_PARAMS" "SubnetType" "$SUBNET_TYPE"
            add_parameter "$EC2_PARAMS" "RootVolumeSize" "$VOLUME_SIZE"
            add_parameter "$EC2_PARAMS" "RootVolumeType" "$VOLUME_TYPE"
            add_parameter "$EC2_PARAMS" "EnableSSM" "$SSM_ENABLED"
            add_parameter "$EC2_PARAMS" "KeyPairName" "$KEY_PAIR"
        fi
    fi
done < <(tail -n +2 "$CSV_FILE")
add_parameter "$EC2_PARAMS" "Environment" "$ENVIRONMENT"

# Create deployment order file
cat > "$OUTPUT_DIR/deployment-order.json" << EOF
{
  "stacks": [
    {
      "name": "vpc",
      "template": "foundation/vpc.yml",
      "parameters": "generated-params/vpc-params.json",
      "enabled": $(should_create_resource "VPC" "$VPC_NAME" "$ENVIRONMENT")
    },
    {
      "name": "subnets",
      "template": "network/subnets.yml",
      "parameters": "generated-params/subnet-params.json",
      "enabled": true,
      "depends_on": ["vpc"]
    },
    {
      "name": "igw",
      "template": "network/igw.yml",
      "parameters": "generated-params/igw-params.json",
      "enabled": true,
      "depends_on": ["vpc"]
    },
    {
      "name": "nat",
      "template": "network/nat.yml",
      "parameters": "generated-params/nat-params.json",
      "enabled": $([ -n "$NAT_STRATEGY" ] && echo true || echo false),
      "depends_on": ["subnets", "igw"]
    },
    {
      "name": "security-groups",
      "template": "security/security-groups.yml",
      "parameters": "generated-params/security-group-params.json",
      "enabled": $([ "$SG_COUNT" -gt 0 ] && echo true || echo false),
      "depends_on": ["vpc"]
    },
    {
      "name": "ec2",
      "template": "compute/ec2.yml",
      "parameters": "generated-params/ec2-params.json",
      "enabled": true,
      "depends_on": ["subnets", "security-groups"]
    }
  ]
}
EOF

echo "CSV parsing completed. Parameter files generated in $OUTPUT_DIR/"
echo "Deployment order: $OUTPUT_DIR/deployment-order.json"