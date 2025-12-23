#!/usr/bin/env python3
"""
BOM Parser - Reads and processes the customer BOM CSV file
Generates CloudFormation parameters and determines deployment requirements
"""

import csv
import json
import argparse
import sys
import os
from typing import Dict, List, Any, Optional

class BOMParser:
    def __init__(self, bom_file: str = 'bom/customer-bom.csv'):
        self.bom_file = bom_file
        self.bom_data = []
        self.network_config = None
        self.services = []
        
    def load_bom(self) -> None:
        """Load BOM CSV file"""
        try:
            with open(self.bom_file, 'r', newline='', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                self.bom_data = list(reader)
                
            if not self.bom_data:
                raise ValueError("BOM file is empty")
                
            print(f"Loaded {len(self.bom_data)} rows from BOM")
            
        except FileNotFoundError:
            print(f"ERROR: BOM file not found: {self.bom_file}")
            sys.exit(1)
        except Exception as e:
            print(f"ERROR: Failed to load BOM file: {e}")
            sys.exit(1)
    
    def parse_bom(self, customer: str, environment: str) -> None:
        """Parse BOM data and categorize resources"""
        self.network_config = None
        self.services = []
        
        for row in self.bom_data:
            resource_type = row.get('resource_type', '').strip().lower()
            
            if resource_type == 'network':
                if self.network_config is None:
                    self.network_config = row
                else:
                    print("WARNING: Multiple network configurations found, using first one")
                    
            elif resource_type == 'service':
                service_name = row.get('service_name', '').strip()
                instance_id = row.get('instance_id', '').strip()
                
                if not service_name or not instance_id:
                    print(f"WARNING: Skipping service row with missing name or instance_id: {row}")
                    continue
                    
                self.services.append(row)
            else:
                print(f"WARNING: Unknown resource type '{resource_type}' in row: {row}")
    
    def generate_network_parameters(self, customer: str, environment: str, vpc_cidr_override: Optional[str] = None) -> Dict[str, Any]:
        """Generate CloudFormation parameters for network deployment"""
        if not self.network_config:
            print("ERROR: No network configuration found in BOM")
            sys.exit(1)
        
        params = {
            'Customer': customer,
            'Environment': environment,
            'VpcCidr': vpc_cidr_override or self.network_config.get('vpc_cidr', '10.0.0.0/16'),
            'AvailabilityZoneCount': int(self.network_config.get('az_count', '2')),
            'CreatePublicSubnets': self.network_config.get('create_public_subnets', 'true').lower(),
            'CreatePrivateSubnets': self.network_config.get('create_private_subnets', 'true').lower(),
            'NatGatewayType': self.network_config.get('nat_gateway_type', 'single')
        }
        
        return params
    
    def generate_service_parameters(self, customer: str, environment: str, service_name: str, instance_id: str) -> Dict[str, Any]:
        """Generate CloudFormation parameters for service deployment"""
        service_config = None
        
        for service in self.services:
            if (service.get('service_name', '').strip() == service_name and 
                service.get('instance_id', '').strip() == instance_id):
                service_config = service
                break
        
        if not service_config:
            print(f"ERROR: Service configuration not found for {service_name}-{instance_id}")
            sys.exit(1)
        
        # Map instance family and size to instance type
        instance_family = service_config.get('instance_family', 't3').strip()
        instance_size = service_config.get('instance_size', 'medium').strip()
        instance_type = f"{instance_family}.{instance_size}"
        
        params = {
            'Customer': customer,
            'Environment': environment,
            'InstanceId': instance_id,
            'InstanceType': instance_type,
            'InstanceCount': int(service_config.get('instance_count', '1')),
            'RootVolumeSize': int(service_config.get('root_volume_size', '20')),
            'SubnetSelection': service_config.get('subnet_selection', 'private').strip(),
            'EnableSSM': service_config.get('enable_ssm', 'true').lower()
        }
        
        # Add service-specific parameters
        if service_config.get('service_type') == 'bastion':
            params['AllowedCidr'] = '0.0.0.0/0'  # Default, should be restricted in production
        
        return params
    
    def get_services_to_deploy(self) -> List[Dict[str, str]]:
        """Get list of services that need to be deployed"""
        services_to_deploy = []
        
        for service in self.services:
            service_name = service.get('service_name', '').strip()
            instance_id = service.get('instance_id', '').strip()
            template = service.get('template', '').strip()
            
            if service_name and instance_id and template:
                services_to_deploy.append({
                    'name': service_name,
                    'instance_id': instance_id,
                    'template': template
                })
        
        return services_to_deploy
    
    def check_dependencies(self) -> bool:
        """Check if all service dependencies are satisfied"""
        dependencies_ok = True
        
        for service in self.services:
            dependency = service.get('dependency', '').strip()
            if dependency and dependency != 'network-foundation':
                print(f"WARNING: Service {service.get('service_name')}-{service.get('instance_id')} has unsupported dependency: {dependency}")
                dependencies_ok = False
        
        return dependencies_ok

def main():
    parser = argparse.ArgumentParser(description='Parse BOM CSV and generate deployment parameters')
    parser.add_argument('--customer', required=True, help='Customer name')
    parser.add_argument('--environment', required=True, help='Environment (dev/staging/prod)')
    parser.add_argument('--check-only', action='store_true', help='Only check what needs to be deployed')
    parser.add_argument('--generate-network-params', action='store_true', help='Generate network parameters')
    parser.add_argument('--generate-service-params', action='store_true', help='Generate service parameters')
    parser.add_argument('--service-name', help='Service name for parameter generation')
    parser.add_argument('--instance-id', help='Instance ID for parameter generation')
    parser.add_argument('--vpc-cidr', help='Override VPC CIDR from BOM')
    
    args = parser.parse_args()
    
    # Initialize BOM parser
    bom_parser = BOMParser()
    bom_parser.load_bom()
    bom_parser.parse_bom(args.customer, args.environment)
    
    if args.check_only:
        # Check what needs to be deployed
        network_needed = bom_parser.network_config is not None
        services_to_deploy = bom_parser.get_services_to_deploy()
        dependencies_ok = bom_parser.check_dependencies()
        
        if not dependencies_ok:
            print("ERROR: Dependency check failed")
            sys.exit(1)
        
        # Output for GitHub Actions
        print(f"::set-output name=network-needed::{str(network_needed).lower()}")
        print(f"::set-output name=services-to-deploy::{json.dumps(services_to_deploy)}")
        
        print(f"Network deployment needed: {network_needed}")
        print(f"Services to deploy: {len(services_to_deploy)}")
        for service in services_to_deploy:
            print(f"  - {service['name']}-{service['instance_id']} ({service['template']})")
    
    elif args.generate_network_params:
        # Generate network parameters
        params = bom_parser.generate_network_parameters(args.customer, args.environment, args.vpc_cidr)
        
        # Convert to CloudFormation parameter format
        cf_params = []
        for key, value in params.items():
            cf_params.append({
                'ParameterKey': key,
                'ParameterValue': str(value)
            })
        
        # Write to file
        with open('network-params.json', 'w') as f:
            json.dump(cf_params, f, indent=2)
        
        print("Network parameters generated: network-params.json")
        print(json.dumps(params, indent=2))
    
    elif args.generate_service_params:
        # Generate service parameters
        if not args.service_name or not args.instance_id:
            print("ERROR: --service-name and --instance-id are required for service parameter generation")
            sys.exit(1)
        
        params = bom_parser.generate_service_parameters(args.customer, args.environment, args.service_name, args.instance_id)
        
        # Convert to CloudFormation parameter format
        cf_params = []
        for key, value in params.items():
            cf_params.append({
                'ParameterKey': key,
                'ParameterValue': str(value)
            })
        
        # Write to file
        filename = f"service-params-{args.service_name}-{args.instance_id}.json"
        with open(filename, 'w') as f:
            json.dump(cf_params, f, indent=2)
        
        print(f"Service parameters generated: {filename}")
        print(json.dumps(params, indent=2))
    
    else:
        print("ERROR: Must specify one of --check-only, --generate-network-params, or --generate-service-params")
        sys.exit(1)

if __name__ == '__main__':
    main()