# Test script for CSV parsing on Windows
Write-Host "Testing CSV parsing functionality..." -ForegroundColor Green

# Test CSV parsing
Write-Host "`nRunning CSV parser..." -ForegroundColor Yellow
& ".\scripts\parse-csv.ps1" -CsvFile "config\customer.csv" -Environment "dev"

# Check if files were generated
Write-Host "`nChecking generated files..." -ForegroundColor Yellow
$expectedFiles = @(
    "generated-params\vpc-params.json",
    "generated-params\subnet-params.json",
    "generated-params\igw-params.json",
    "generated-params\nat-params.json",
    "generated-params\security-group-params.json",
    "generated-params\ec2-params.json",
    "generated-params\deployment-order.json"
)

foreach ($file in $expectedFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ $file (missing)" -ForegroundColor Red
    }
}

# Display deployment order
Write-Host "`nDeployment Order:" -ForegroundColor Yellow
if (Test-Path "generated-params\deployment-order.json") {
    $deploymentOrder = Get-Content "generated-params\deployment-order.json" | ConvertFrom-Json
    foreach ($stack in $deploymentOrder.stacks) {
        $status = if ($stack.enabled) { "ENABLED" } else { "DISABLED" }
        $color = if ($stack.enabled) { "Green" } else { "Gray" }
        Write-Host "  $($stack.name): $status" -ForegroundColor $color
    }
}

# Display VPC parameters as example
Write-Host "`nVPC Parameters:" -ForegroundColor Yellow
if (Test-Path "generated-params\vpc-params.json") {
    $vpcParams = Get-Content "generated-params\vpc-params.json" | ConvertFrom-Json
    foreach ($param in $vpcParams) {
        Write-Host "  $($param.ParameterKey): $($param.ParameterValue)" -ForegroundColor Cyan
    }
}

Write-Host "`nTesting completed!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Push this repository to GitHub"
Write-Host "2. Configure GitHub secrets and environments"
Write-Host "3. Run the GitHub Actions workflow"