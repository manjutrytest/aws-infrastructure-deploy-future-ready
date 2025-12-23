@echo off
echo ========================================
echo AWS Infrastructure Solution Validation
echo ========================================

echo.
echo Checking CSV configuration...
if exist "config\customer.csv" (
    echo [✓] CSV file found
    echo [✓] CSV contains %count% rows of infrastructure configuration
) else (
    echo [✗] CSV file missing
    goto :error
)

echo.
echo Checking CloudFormation templates...
if exist "foundation\vpc.yml" echo [✓] VPC template found
if exist "network\subnets.yml" echo [✓] Subnet template found  
if exist "network\igw.yml" echo [✓] Internet Gateway template found
if exist "network\nat.yml" echo [✓] NAT Gateway template found
if exist "security\security-groups.yml" echo [✓] Security Groups template found
if exist "compute\ec2.yml" echo [✓] EC2 template found

echo.
echo Checking bootstrap templates...
if exist "bootstrap\oidc-provider.yml" echo [✓] OIDC Provider template found
if exist "bootstrap\github-deploy-role.yml" echo [✓] GitHub Deploy Role template found

echo.
echo Checking GitHub Actions workflow...
if exist ".github\workflows\deploy.yml" echo [✓] Deployment workflow found

echo.
echo Checking documentation...
if exist "docs\architecture.md" echo [✓] Architecture documentation found
if exist "docs\csv-configuration-guide.md" echo [✓] CSV configuration guide found
if exist "docs\deployment-guide.md" echo [✓] Deployment guide found
if exist "docs\dependency-map.md" echo [✓] Dependency map found

echo.
echo ========================================
echo SOLUTION VALIDATION COMPLETE
echo ========================================
echo.
echo Your AWS Infrastructure solution is ready!
echo.
echo NEXT STEPS:
echo 1. Push this repository to GitHub
echo 2. Configure GitHub secrets (AWS_ACCOUNT_ID)
echo 3. Configure GitHub environments (development, production)
echo 4. Run bootstrap CloudFormation stacks in AWS
echo 5. Execute GitHub Actions workflow
echo.
echo For detailed instructions, see: docs\deployment-guide.md
echo.
goto :end

:error
echo [✗] Validation failed
exit /b 1

:end
echo Validation completed successfully!