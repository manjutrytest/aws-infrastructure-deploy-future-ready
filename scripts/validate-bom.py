#!/usr/bin/env python3
"""
BOM Validator - Validates the customer BOM CSV file structure and content
Ensures all required fields are present and values are valid
"""

import csv
import sys
import re
import ipaddress
from typing import Dict, List, Set, Optional

class BOMValidator:
    def __init__(self, bom_file: str = 'bom/customer-bom.csv'):
        self.bom_file = bom_file
        self.bom_data = []
        self.errors = []
        self.warnings = []
        
        # Define required columns
        self.required_columns = {
            'resource_type', 'service_name', 'instance_id', 'template', 'dependency'
        }
        
        # Define valid values
        self.valid_resource_types = {'network', 'service'}
        self.valid_service_types = {'web', 'database', 'bastion'}
        self.valid_os_types = {'linux', 'windows'}
        self.valid_instance_families = {'t3', 't2', 'm5', 'm4', 'c5', 'c4', 'r5', 'r4'}
        self.valid_instance_sizes = {'nano', 'micro', 'small', 'medium', 'large', 'xlarge', '2xlarge', '4xlarge'}
        self.valid_subnet_selections = {'public', 'private'}
        self.valid_nat_types = {'none', 'single', 'per-az'}
        self.valid_boolean_values = {'true', 'false'}
    
    def load_bom(self) -> bool:
        """Load and parse BOM CSV file"""
        try:
            with open(self.bom_file, 'r', newline='', encoding='utf-8') as file:
                reader = csv.DictReader(file)
                self.bom_data = list(reader)
                
            if not self.bom_data:
                self.errors.append("BOM file is empty")
                return False
                
            print(f"Loaded {len(self.bom_data)} rows from BOM")
            return True
            
        except FileNotFoundError:
            self.errors.append(f"BOM file not found: {self.bom_file}")
            return False
        except Exception as e:
            self.errors.append(f"Failed to load BOM file: {e}")
            return False
    
    def validate_columns(self) -> bool:
        """Validate that all required columns are present"""
        if not self.bom_data:
            return False
        
        actual_columns = set(self.bom_data[0].keys())
        missing_columns = self.required_columns - actual_columns
        
        if missing_columns:
            self.errors.append(f"Missing required columns: {', '.join(missing_columns)}")
            return False
        
        return True
    
    def validate_vpc_cidr(self, cidr: str) -> bool:
        """Validate VPC CIDR format and range"""
        if not cidr:
            return False
        
        try:
            network = ipaddress.IPv4Network(cidr, strict=False)
            
            # Check if it's a valid private network
            if not network.is_private:
                self.warnings.append(f"VPC CIDR {cidr} is not a private network")
            
            # Check prefix length (should be between /16 and /28)
            if network.prefixlen < 16 or network.prefixlen > 28:
                self.errors.append(f"VPC CIDR {cidr} prefix length should be between /16 and /28")
                return False
            
            return True
            
        except ipaddress.AddressValueError:
            self.errors.append(f"Invalid VPC CIDR format: {cidr}")
            return False
    
    def validate_instance_type(self, family: str, size: str, row_num: int) -> bool:
        """Validate instance family and size combination"""
        valid = True
        
        if family and family not in self.valid_instance_families:
            self.errors.append(f"Row {row_num}: Invalid instance family '{family}'. Valid options: {', '.join(self.valid_instance_families)}")
            valid = False
        
        if size and size not in self.valid_instance_sizes:
            self.errors.append(f"Row {row_num}: Invalid instance size '{size}'. Valid options: {', '.join(self.valid_instance_sizes)}")
            valid = False
        
        return valid
    
    def validate_numeric_field(self, value: str, field_name: str, min_val: int, max_val: int, row_num: int) -> bool:
        """Validate numeric field within range"""
        if not value:
            return True  # Optional field
        
        try:
            num_val = int(value)
            if num_val < min_val or num_val > max_val:
                self.errors.append(f"Row {row_num}: {field_name} must be between {min_val} and {max_val}, got {num_val}")
                return False
            return True
        except ValueError:
            self.errors.append(f"Row {row_num}: {field_name} must be a number, got '{value}'")
            return False
    
    def validate_boolean_field(self, value: str, field_name: str, row_num: int) -> bool:
        """Validate boolean field"""
        if not value:
            return True  # Optional field
        
        if value.lower() not in self.valid_boolean_values:
            self.errors.append(f"Row {row_num}: {field_name} must be 'true' or 'false', got '{value}'")
            return False
        
        return True
    
    def validate_network_row(self, row: Dict[str, str], row_num: int) -> bool:
        """Validate network configuration row"""
        valid = True
        
        # Validate VPC CIDR
        vpc_cidr = row.get('vpc_cidr', '').strip()
        if vpc_cidr and not self.validate_vpc_cidr(vpc_cidr):
            valid = False
        
        # Validate AZ count
        az_count = row.get('az_count', '').strip()
        if not self.validate_numeric_field(az_count, 'az_count', 2, 3, row_num):
            valid = False
        
        # Validate boolean fields
        for field in ['create_public_subnets', 'create_private_subnets']:
            if not self.validate_boolean_field(row.get(field, '').strip(), field, row_num):
                valid = False
        
        # Validate NAT gateway type
        nat_type = row.get('nat_gateway_type', '').strip().lower()
        if nat_type and nat_type not in self.valid_nat_types:
            self.errors.append(f"Row {row_num}: Invalid nat_gateway_type '{nat_type}'. Valid options: {', '.join(self.valid_nat_types)}")
            valid = False
        
        return valid
    
    def validate_service_row(self, row: Dict[str, str], row_num: int) -> bool:
        """Validate service configuration row"""
        valid = True
        
        # Validate required fields for services
        service_name = row.get('service_name', '').strip()
        instance_id = row.get('instance_id', '').strip()
        template = row.get('template', '').strip()
        
        if not service_name:
            self.errors.append(f"Row {row_num}: service_name is required for service resources")
            valid = False
        
        if not instance_id:
            self.errors.append(f"Row {row_num}: instance_id is required for service resources")
            valid = False
        elif not re.match(r'^[0-9]{3}$', instance_id):
            self.errors.append(f"Row {row_num}: instance_id must be a 3-digit number (e.g., '001'), got '{instance_id}'")
            valid = False
        
        if not template:
            self.errors.append(f"Row {row_num}: template is required for service resources")
            valid = False
        elif not template.endswith('.yml'):
            self.errors.append(f"Row {row_num}: template must end with '.yml', got '{template}'")
            valid = False
        
        # Validate service type
        service_type = row.get('service_type', '').strip().lower()
        if service_type and service_type not in self.valid_service_types:
            self.errors.append(f"Row {row_num}: Invalid service_type '{service_type}'. Valid options: {', '.join(self.valid_service_types)}")
            valid = False
        
        # Validate OS type
        os_type = row.get('os_type', '').strip().lower()
        if os_type and os_type not in self.valid_os_types:
            self.errors.append(f"Row {row_num}: Invalid os_type '{os_type}'. Valid options: {', '.join(self.valid_os_types)}")
            valid = False
        
        # Validate instance type
        instance_family = row.get('instance_family', '').strip().lower()
        instance_size = row.get('instance_size', '').strip().lower()
        if not self.validate_instance_type(instance_family, instance_size, row_num):
            valid = False
        
        # Validate numeric fields
        if not self.validate_numeric_field(row.get('instance_count', '').strip(), 'instance_count', 1, 10, row_num):
            valid = False
        
        if not self.validate_numeric_field(row.get('root_volume_size', '').strip(), 'root_volume_size', 8, 1000, row_num):
            valid = False
        
        # Validate subnet selection
        subnet_selection = row.get('subnet_selection', '').strip().lower()
        if subnet_selection and subnet_selection not in self.valid_subnet_selections:
            self.errors.append(f"Row {row_num}: Invalid subnet_selection '{subnet_selection}'. Valid options: {', '.join(self.valid_subnet_selections)}")
            valid = False
        
        # Validate boolean fields
        if not self.validate_boolean_field(row.get('enable_ssm', '').strip(), 'enable_ssm', row_num):
            valid = False
        
        return valid
    
    def validate_dependencies(self) -> bool:
        """Validate service dependencies"""
        valid = True
        network_exists = False
        service_names = set()
        
        # Check if network foundation exists
        for row in self.bom_data:
            resource_type = row.get('resource_type', '').strip().lower()
            if resource_type == 'network':
                network_exists = True
                break
        
        # Validate service dependencies
        for i, row in enumerate(self.bom_data, 1):
            resource_type = row.get('resource_type', '').strip().lower()
            
            if resource_type == 'service':
                dependency = row.get('dependency', '').strip()
                service_name = row.get('service_name', '').strip()
                instance_id = row.get('instance_id', '').strip()
                
                # Check for duplicate service names + instance IDs
                service_key = f"{service_name}-{instance_id}"
                if service_key in service_names:
                    self.errors.append(f"Row {i}: Duplicate service name and instance ID combination: {service_key}")
                    valid = False
                else:
                    service_names.add(service_key)
                
                # Check dependency
                if dependency == 'network-foundation' and not network_exists:
                    self.errors.append(f"Row {i}: Service depends on network-foundation but no network configuration found")
                    valid = False
                elif dependency and dependency != 'network-foundation':
                    self.warnings.append(f"Row {i}: Unsupported dependency '{dependency}'. Only 'network-foundation' is supported")
        
        return valid
    
    def validate_row_data(self) -> bool:
        """Validate each row's data"""
        valid = True
        
        for i, row in enumerate(self.bom_data, 1):
            resource_type = row.get('resource_type', '').strip().lower()
            
            # Validate resource type
            if not resource_type:
                self.errors.append(f"Row {i}: resource_type is required")
                valid = False
                continue
            
            if resource_type not in self.valid_resource_types:
                self.errors.append(f"Row {i}: Invalid resource_type '{resource_type}'. Valid options: {', '.join(self.valid_resource_types)}")
                valid = False
                continue
            
            # Validate based on resource type
            if resource_type == 'network':
                if not self.validate_network_row(row, i):
                    valid = False
            elif resource_type == 'service':
                if not self.validate_service_row(row, i):
                    valid = False
        
        return valid
    
    def validate(self) -> bool:
        """Run all validations"""
        print("Validating BOM file...")
        
        # Load BOM file
        if not self.load_bom():
            return False
        
        # Validate structure
        if not self.validate_columns():
            return False
        
        # Validate data
        data_valid = self.validate_row_data()
        deps_valid = self.validate_dependencies()
        
        return data_valid and deps_valid
    
    def print_results(self) -> None:
        """Print validation results"""
        if self.errors:
            print("\n❌ VALIDATION ERRORS:")
            for error in self.errors:
                print(f"  - {error}")
        
        if self.warnings:
            print("\n⚠️  VALIDATION WARNINGS:")
            for warning in self.warnings:
                print(f"  - {warning}")
        
        if not self.errors and not self.warnings:
            print("\n✅ BOM validation passed - no issues found")
        elif not self.errors:
            print(f"\n✅ BOM validation passed - {len(self.warnings)} warnings")
        else:
            print(f"\n❌ BOM validation failed - {len(self.errors)} errors, {len(self.warnings)} warnings")

def main():
    validator = BOMValidator()
    
    if validator.validate():
        validator.print_results()
        if validator.warnings:
            sys.exit(0)  # Warnings are OK
        else:
            sys.exit(0)  # Success
    else:
        validator.print_results()
        sys.exit(1)  # Validation failed

if __name__ == '__main__':
    main()