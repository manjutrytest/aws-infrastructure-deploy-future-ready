# Bootstrap AWS Account - PowerShell Commands
# Run these commands one at a time in PowerShell

Write-Host "AWS Infrastructure Bootstrap Commands" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green

Write-Host "`n1. Deploy OIDC Provider:" -ForegroundColor Yellow
Write-Host "aws cloudformation deploy --template-file bootstrap/oidc-provider.yml --stack-name github-oidc-provider-manju --parameter-overrides GitHubOrganization=manjutrytest RepositoryName=aws-infrastructure-deploy-future-ready --region ap-south-1" -ForegroundColor Cyan

Write-Host "`n2. Deploy Dev Role:" -ForegroundColor Yellow  
Write-Host "aws cloudformation deploy --template-file bootstrap/github-deploy-role.yml --stack-name github-deploy-role-dev --parameter-overrides OIDCProviderStackName=github-oidc-provider-manju Environment=dev --capabilities CAPABILITY_IAM --region ap-south-1" -ForegroundColor Cyan

Write-Host "`n3. Deploy Prod Role:" -ForegroundColor Yellow
Write-Host "aws cloudformation deploy --template-file bootstrap/github-deploy-role.yml --stack-name github-deploy-role-prod --parameter-overrides OIDCProviderStackName=github-oidc-provider-manju Environment=prod --capabilities CAPABILITY_IAM --region ap-south-1" -ForegroundColor Cyan

Write-Host "`nCopy and paste each command above into your terminal one at a time." -ForegroundColor Green