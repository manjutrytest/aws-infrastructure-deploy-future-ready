# Simplified Bootstrap - Using Existing OIDC Provider
Write-Host "Using Existing OIDC Provider - Simplified Bootstrap" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green

Write-Host "`nExisting OIDC Provider Found:" -ForegroundColor Yellow
Write-Host "arn:aws:iam::821706771879:oidc-provider/token.actions.githubusercontent.com" -ForegroundColor Cyan

Write-Host "`n1. Deploy Dev Role (using existing OIDC):" -ForegroundColor Yellow
Write-Host "aws cloudformation deploy --template-file bootstrap/github-deploy-role-existing-oidc.yml --stack-name github-deploy-role-dev-manju --parameter-overrides GitHubOrganization=manjutrytest RepositoryName=aws-infrastructure-deploy-future-ready Environment=dev --capabilities CAPABILITY_NAMED_IAM --region ap-south-1" -ForegroundColor Cyan

Write-Host "`n2. Deploy Prod Role (using existing OIDC):" -ForegroundColor Yellow
Write-Host "aws cloudformation deploy --template-file bootstrap/github-deploy-role-existing-oidc.yml --stack-name github-deploy-role-prod-manju --parameter-overrides GitHubOrganization=manjutrytest RepositoryName=aws-infrastructure-deploy-future-ready Environment=prod --capabilities CAPABILITY_NAMED_IAM --region ap-south-1" -ForegroundColor Cyan

Write-Host "`nBenefits of using existing OIDC provider:" -ForegroundColor Green
Write-Host "✓ No conflicts with existing setup" -ForegroundColor Green
Write-Host "✓ Faster deployment" -ForegroundColor Green
Write-Host "✓ Reuses proven configuration" -ForegroundColor Green

Write-Host "`nNext: Copy and paste each command above one at a time." -ForegroundColor Yellow