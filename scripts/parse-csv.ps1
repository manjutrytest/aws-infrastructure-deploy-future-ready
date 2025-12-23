# PowerShell version of CSV parser for Windows testing
param(
    [Parameter(Mandatory=$true)]
    [string]$CsvFile,
    
    [Parameter(Mandatory=$false)]
    [string]$Environment = "dev"
)

Write-Host "Parsing CSV file: $CsvFile for environment: $Environment"

# Create output directory
$OutputDir = "generated-params"
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force
}

# Initialize parameter files
$VpcParams = "$OutputDir/vpc-params.json"
$SubnetParams = "$OutputDir/subnet-params.json"
$IgwParams = "$OutputDir/igw-params.json"
$NatParams = "$OutputDir/nat-params.json"
$SgParams = "$OutputDir/security-group-params.json"
$Ec2Params = "$OutputDir/ec2-params.json"

# Initialize JSON files
'[]' | Out-File -FilePath $VpcParams -Encoding UTF8
'[]' | Out-File -FilePath $SubnetParams -Encoding UTF8
'[]' | Out-File -FilePath $IgwParams -Encoding UTF8
'[]' | Out-File -FilePath $NatParams -Encoding UTF8
'[]' | Out-File -FilePath $SgParams -Encoding UTF8
'[]' | Out-File -FilePath $Ec2Params -Encoding UTF8

# Function to add parameter to JSON file
function Add-Parameter {
    param($File, $Key, $Value)
    
    $content = Get-Content $File -Raw | ConvertFrom-Json
    $newParam = @{
        ParameterKey = $Key
        ParameterValue = $Value
    }
    $content += $newParam
    $content | ConvertTo-Json -Depth 10 | Out-File -FilePath $File -Encoding UTF8
}

# Read and parse CSV
$csvData = Import-Csv $CsvFile

# Function to get CSV value
function Get-CsvValue {
    param($ResourceType, $ResourceName, $Config, $Env)
    
    $result = $csvData | Where-Object { 
        $_.ResourceType -eq $ResourceType -and 
        $_.ResourceName -eq $ResourceName -and 
        $_.Configuration -eq $Config -and 
        ($_.Environment -eq $Env -or $_.Environment -eq "all")
    } | Select-Object -First 1
    
    return $result.Value
}

# Function to check if resource should be created
function Should-CreateResource {
    param($ResourceType, $ResourceName, $Env)
    
    $result = $csvData | Where-Object { 
        $_.ResourceType -eq $ResourceType -and 
        $_.ResourceName -eq $ResourceName -and 
        ($_.Environment -eq $Env -or $_.Environment -eq "all")
    } | Select-Object -First 1
    
    return ($result.Action -eq "create-new")
}

# Parse VPC parameters
Write-Host "Processing VPC parameters..."
$vpcName = ($csvData | Where-Object { $_.ResourceType -eq "VPC" -and ($_.Environment -eq $Environment -or $_.Environment -eq "all") } | Select-Object -First 1).ResourceName

if ($vpcName) {
    $vpcCidr = Get-CsvValue "VPC" $vpcName "CIDR" $Environment
    $vpcAzs = Get-CsvValue "VPC" $vpcName "AvailabilityZones" $Environment
    $dnsHostnames = Get-CsvValue "VPC" $vpcName "EnableDnsHostnames" $Environment
    $dnsSupport = Get-CsvValue "VPC" $vpcName "EnableDnsSupport" $Environment
    
    if ($vpcCidr) { Add-Parameter $VpcParams "VpcCidr" $vpcCidr }
    if ($vpcAzs) { Add-Parameter $VpcParams "AvailabilityZoneCount" $vpcAzs }
    if ($dnsHostnames) { Add-Parameter $VpcParams "EnableDnsHostnames" $dnsHostnames }
    if ($dnsSupport) { Add-Parameter $VpcParams "EnableDnsSupport" $dnsSupport }
    Add-Parameter $VpcParams "Environment" $Environment
}

# Parse Subnet parameters
Write-Host "Processing Subnet parameters..."
$publicSubnetCount = 0
$privateSubnetCount = 0
$subnetCidrs = @()

foreach ($row in $csvData) {
    if ($row.ResourceType -eq "Subnet" -and ($row.Environment -eq $Environment -or $row.Environment -eq "all")) {
        if ($row.Configuration -eq "Type") {
            if ($row.Value -eq "public") { $publicSubnetCount++ }
            elseif ($row.Value -eq "private") { $privateSubnetCount++ }
        }
        elseif ($row.Configuration -eq "CIDR") {
            $subnetCidrs += $row.Value
        }
    }
}

if ($publicSubnetCount -gt 0) { Add-Parameter $SubnetParams "PublicSubnetCount" $publicSubnetCount }
if ($privateSubnetCount -gt 0) { Add-Parameter $SubnetParams "PrivateSubnetCount" $privateSubnetCount }
if ($subnetCidrs.Count -gt 0) { Add-Parameter $SubnetParams "SubnetCidrs" ($subnetCidrs -join ",") }
Add-Parameter $SubnetParams "Environment" $Environment

# Parse NAT Gateway parameters
Write-Host "Processing NAT Gateway parameters..."
$natStrategy = Get-CsvValue "NATGateway" "MainNAT" "Strategy" $Environment
if ($natStrategy) {
    Add-Parameter $NatParams "NatGatewayStrategy" $natStrategy
    Add-Parameter $NatParams "Environment" $Environment
}

# Parse Security Group parameters
Write-Host "Processing Security Group parameters..."
$sgCount = 0
foreach ($row in $csvData) {
    if ($row.ResourceType -eq "SecurityGroup" -and ($row.Environment -eq $Environment -or $row.Environment -eq "all")) {
        if ($row.Configuration -eq "Description") {
            $sgCount++
            Add-Parameter $SgParams "SecurityGroup${sgCount}Name" $row.ResourceName
            Add-Parameter $SgParams "SecurityGroup${sgCount}Description" $row.Value
        }
    }
}
Add-Parameter $SgParams "Environment" $Environment

# Parse EC2 parameters
Write-Host "Processing EC2 parameters..."
$ec2Resources = $csvData | Where-Object { $_.ResourceType -eq "EC2" -and ($_.Environment -eq $Environment -or $_.Environment -eq "all") } | Group-Object ResourceName

foreach ($ec2Group in $ec2Resources) {
    $instanceName = $ec2Group.Name
    $configs = @{}
    
    foreach ($config in $ec2Group.Group) {
        $configs[$config.Configuration] = $config.Value
    }
    
    if ($configs.ContainsKey("OperatingSystem")) {
        Add-Parameter $Ec2Params "InstanceName" $instanceName
        Add-Parameter $Ec2Params "OperatingSystem" $configs["OperatingSystem"]
        Add-Parameter $Ec2Params "InstanceType" "$($configs["InstanceFamily"]).$($configs["InstanceSize"])"
        Add-Parameter $Ec2Params "InstanceCount" $configs["InstanceCount"]
        Add-Parameter $Ec2Params "SubnetType" $configs["SubnetType"]
        Add-Parameter $Ec2Params "RootVolumeSize" $configs["RootVolumeSize"]
        Add-Parameter $Ec2Params "RootVolumeType" $configs["RootVolumeType"]
        Add-Parameter $Ec2Params "EnableSSM" $configs["EnableSSM"]
        Add-Parameter $Ec2Params "KeyPairName" $configs["KeyPairName"]
    }
}
Add-Parameter $Ec2Params "Environment" $Environment

# Create deployment order file
$deploymentOrder = @{
    stacks = @(
        @{
            name = "vpc"
            template = "foundation/vpc.yml"
            parameters = "generated-params/vpc-params.json"
            enabled = $(Should-CreateResource "VPC" $vpcName $Environment)
        },
        @{
            name = "subnets"
            template = "network/subnets.yml"
            parameters = "generated-params/subnet-params.json"
            enabled = $true
            depends_on = @("vpc")
        },
        @{
            name = "igw"
            template = "network/igw.yml"
            parameters = "generated-params/igw-params.json"
            enabled = $true
            depends_on = @("vpc")
        },
        @{
            name = "nat"
            template = "network/nat.yml"
            parameters = "generated-params/nat-params.json"
            enabled = $($natStrategy -ne $null -and $natStrategy -ne "")
            depends_on = @("subnets", "igw")
        },
        @{
            name = "security-groups"
            template = "security/security-groups.yml"
            parameters = "generated-params/security-group-params.json"
            enabled = $($sgCount -gt 0)
            depends_on = @("vpc")
        },
        @{
            name = "ec2"
            template = "compute/ec2.yml"
            parameters = "generated-params/ec2-params.json"
            enabled = $true
            depends_on = @("subnets", "security-groups")
        }
    )
}

$deploymentOrder | ConvertTo-Json -Depth 10 | Out-File -FilePath "$OutputDir/deployment-order.json" -Encoding UTF8

Write-Host "CSV parsing completed. Parameter files generated in $OutputDir/"
Write-Host "Deployment order: $OutputDir/deployment-order.json"