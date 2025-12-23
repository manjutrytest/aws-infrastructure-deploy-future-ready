# Deploy Windows EC2 Instance using existing networking components
Write-Host "Deploying Windows EC2 Instance..." -ForegroundColor Green

# Get existing VPC ID
$VpcId = aws cloudformation describe-stacks --stack-name dev-vpc --query 'Stacks[0].Outputs[?OutputKey==`VPCId`].OutputValue' --output text --region ap-south-1
Write-Host "VPC ID: $VpcId" -ForegroundColor Cyan

# Get existing Public Subnet ID
$SubnetId = aws cloudformation describe-stacks --stack-name dev-subnets --query 'Stacks[0].Outputs[?OutputKey==`PublicSubnet1Id`].OutputValue' --output text --region ap-south-1
Write-Host "Subnet ID: $SubnetId" -ForegroundColor Cyan

# Get existing Security Group ID
$SecurityGroupId = aws cloudformation describe-stacks --stack-name dev-security-groups --query 'Stacks[0].Outputs[?OutputKey==`WebSecurityGroupId`].OutputValue' --output text --region ap-south-1
Write-Host "Security Group ID: $SecurityGroupId" -ForegroundColor Cyan

# Deploy Windows EC2 instance
Write-Host "Deploying Windows EC2 instance..." -ForegroundColor Yellow
aws cloudformation deploy `
  --template-file compute/windows-ec2.yml `
  --stack-name dev-windows-ec2 `
  --parameter-overrides `
    VPCId=$VpcId `
    SubnetId=$SubnetId `
    SecurityGroupId=$SecurityGroupId `
    InstanceName=WindowsServer2022 `
    InstanceType=t3.medium `
    RootVolumeSize=40 `
    KeyPairName=test `
    Environment=dev `
  --capabilities CAPABILITY_IAM `
  --region ap-south-1

if ($LASTEXITCODE -eq 0) {
    Write-Host "Windows EC2 instance deployed successfully!" -ForegroundColor Green
    
    # Get instance details
    Write-Host "`nInstance Details:" -ForegroundColor Yellow
    $InstanceId = aws cloudformation describe-stacks --stack-name dev-windows-ec2 --query 'Stacks[0].Outputs[?OutputKey==`WindowsInstanceId`].OutputValue' --output text --region ap-south-1
    $PublicIP = aws cloudformation describe-stacks --stack-name dev-windows-ec2 --query 'Stacks[0].Outputs[?OutputKey==`WindowsInstancePublicIP`].OutputValue' --output text --region ap-south-1
    
    Write-Host "Instance ID: $InstanceId" -ForegroundColor Cyan
    Write-Host "Public IP: $PublicIP" -ForegroundColor Cyan
    Write-Host "RDP Command: mstsc /v:$PublicIP" -ForegroundColor Green
    Write-Host "`nYou can connect via:" -ForegroundColor Yellow
    Write-Host "1. RDP using key pair 'test'" -ForegroundColor White
    Write-Host "2. AWS Systems Manager Session Manager" -ForegroundColor White
    Write-Host "3. Web browser: http://$PublicIP (IIS installed)" -ForegroundColor White
} else {
    Write-Host "Deployment failed!" -ForegroundColor Red
    Write-Host "Check CloudFormation console for details" -ForegroundColor Yellow
}