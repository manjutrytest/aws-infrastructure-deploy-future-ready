# Deployment Guide

## Prerequisites

### 1. AWS Account Setup
- AWS Account with appropriate permissions
- AWS CLI installed and configured (for bootstrap only)
- Target region selected (default: ap-south-1)

### 2. GitHub Repository Setup
- Fork or clone this repository
- Configure GitHub repository settings
- Set up GitHub Environments (development, production)

### 3. Required Tools
- Git
- AWS CLI (for bootstrap)
- jq (JSON processor)
- Bash shell (Linux/macOS/WSL)

## Bootstrap Setup (One-Time)

### Step 1: Deploy OIDC Provider

```bash
# Clone the repository
git clone <your-repo-url>
cd aws-infra

# Deploy OIDC Provider
aws cloudformation deploy \
  --template-file bootstrap/oidc-provider.yml \
  --stack-name github-oidc-provider \
  --parameter-overrides \
    GitHubOrganization=your-github-org \
    RepositoryName=aws-infra \
  --region ap-south-1
```

### Step 2: Deploy GitHub Deploy Roles

```bash
# Deploy Dev Role
aws cloudformation deploy \
  --template-file bootstrap/github-deploy-role.yml \
  --stack-name github-deploy-role-dev \
  --parameter-overrides \
    OIDCProviderStackName=github-oidc-provider \
    Environment=dev \
  --capabilities CAPABILITY_IAM \
  --region ap-south-1

# Deploy Prod Role
aws cloudformation deploy \
  --template-file bootstrap/github-deploy-role.yml \
  --stack-name github-deploy-role-prod \
  --parameter-overrides \
    OIDCProviderStackName=github-oidc-provider \
    Environment=prod \
  --capabilities CAPABILITY_IAM \
  --region ap-south-1
```

### Step 3: Configure GitHub Secrets

In your GitHub repository, go to Settings → Secrets and variables → Actions:

**Repository Secrets:**
- `AWS_ACCOUNT_ID`: Your AWS Account ID (e.g., 123456789012)

**Repository Variables:**
- `AWS_REGION`: Target AWS region (e.g., ap-south-1)

### Step 4: Configure GitHub Environments

Create two environments in GitHub:
1. **development** - for dev deployments
2. **production** - for prod deployments (with protection rules)

**Production Environment Protection:**
- Required reviewers: Add team members
- Wait timer: 5 minutes (optional)
- Deployment branches: main branch only

## Infrastructure Deployment

### Step 1: Configure Infrastructure Requirements

Edit `config/customer.csv` with your infrastructure requirements:

```csv
ResourceType,ResourceName,Action,Configuration,Value,Dependencies,Environment
VPC,MainVPC,create-new,CIDR,10.0.0.0/16,,all
VPC,MainVPC,create-new,AvailabilityZones,2,,all
# ... add your resources
```

See [CSV Configuration Guide](csv-configuration-guide.md) for detailed configuration options.

### Step 2: Deploy to Development

1. **Commit and Push Changes:**
   ```bash
   git add config/customer.csv
   git commit -m "Configure infrastructure requirements"
   git push origin main
   ```

2. **Run GitHub Actions Workflow:**
   - Go to GitHub Actions tab
   - Select "Deploy AWS Infrastructure" workflow
   - Click "Run workflow"
   - Select:
     - Environment: `dev`
     - Action: `deploy`
   - Click "Run workflow"

3. **Monitor Deployment:**
   - Watch the workflow execution
   - Check CloudFormation stacks in AWS Console
   - Review deployment summary

### Step 3: Validate Development Deployment

```bash
# Check deployed stacks
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE \
  --query 'StackSummaries[?starts_with(StackName, `dev-`)].{Name:StackName,Status:StackStatus}' \
  --region ap-south-1

# Get VPC information
aws cloudformation describe-stacks \
  --stack-name dev-vpc \
  --query 'Stacks[0].Outputs' \
  --region ap-south-1

# List EC2 instances
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" \
  --query 'Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,State:State.Name,IP:PublicIpAddress}' \
  --region ap-south-1
```

### Step 4: Deploy to Production

1. **Validate Development First:**
   - Test applications in dev environment
   - Verify all resources are working correctly
   - Review costs and resource utilization

2. **Deploy to Production:**
   - Go to GitHub Actions tab
   - Select "Deploy AWS Infrastructure" workflow
   - Click "Run workflow"
   - Select:
     - Environment: `prod`
     - Action: `deploy`
   - Click "Run workflow"
   - **Approve deployment** when prompted (production protection)

3. **Monitor Production Deployment:**
   - Watch the workflow execution
   - Verify all stacks deploy successfully
   - Check resource health and connectivity

## Deployment Strategies

### Full Infrastructure Deployment
Deploy all stacks defined in CSV:
```
Environment: dev/prod
Action: deploy
Stack Filter: (leave empty)
```

### Specific Stack Deployment
Deploy only a specific stack:
```
Environment: dev/prod
Action: deploy
Stack Filter: ec2
```

### Infrastructure Updates
1. Modify `config/customer.csv`
2. Commit and push changes
3. Run deployment workflow
4. CloudFormation will update existing resources

### Infrastructure Destruction
**⚠️ WARNING: This will delete all resources**
```
Environment: dev/prod
Action: destroy
Stack Filter: (leave empty)
```

## Monitoring Deployment

### GitHub Actions Logs
- Real-time deployment progress
- CloudFormation stack events
- Error messages and troubleshooting info

### AWS CloudFormation Console
- Stack status and events
- Resource creation progress
- Rollback information on failures

### AWS CloudWatch
- VPC Flow Logs
- EC2 instance metrics
- Application logs (if configured)

## Troubleshooting

### Common Issues

#### 1. OIDC Authentication Failure
```
Error: Could not assume role with OIDC
```
**Solution:**
- Verify GitHub repository settings
- Check OIDC provider configuration
- Ensure role trust policy is correct

#### 2. CloudFormation Stack Failure
```
Error: Stack creation failed
```
**Solution:**
- Check CloudFormation events in AWS Console
- Review stack parameters and dependencies
- Verify resource limits and quotas

#### 3. CSV Parsing Errors
```
Error: Invalid CSV configuration
```
**Solution:**
- Validate CSV syntax and format
- Check for missing dependencies
- Verify configuration values

#### 4. Resource Limit Exceeded
```
Error: Cannot create resource - limit exceeded
```
**Solution:**
- Check AWS service limits
- Request limit increases if needed
- Optimize resource configuration

### Debugging Commands

```bash
# Validate CSV locally
./scripts/parse-csv.sh config/customer.csv dev

# Check generated parameters
cat generated-params/deployment-order.json

# Validate CloudFormation templates
aws cloudformation validate-template \
  --template-body file://foundation/vpc.yml

# Check stack events
aws cloudformation describe-stack-events \
  --stack-name dev-vpc \
  --region ap-south-1
```

### Recovery Procedures

#### Stack Rollback
If a stack update fails:
1. Check CloudFormation console for error details
2. Fix the issue in CSV or template
3. Redeploy the stack
4. CloudFormation will automatically rollback on failure

#### Manual Intervention
For complex failures:
1. Access AWS Console
2. Review CloudFormation stack events
3. Fix resources manually if needed
4. Update CSV to match current state
5. Redeploy to synchronize

## Best Practices

### Development Workflow
1. **Test in Dev First**: Always deploy to dev before prod
2. **Small Changes**: Make incremental changes
3. **Validate Resources**: Test functionality after deployment
4. **Monitor Costs**: Review AWS billing regularly

### Production Deployment
1. **Scheduled Maintenance**: Deploy during maintenance windows
2. **Backup Critical Data**: Ensure backups before changes
3. **Rollback Plan**: Have rollback procedures ready
4. **Team Communication**: Notify team of deployments

### Security
1. **Least Privilege**: Use minimal required permissions
2. **Environment Separation**: Keep dev/prod isolated
3. **Access Control**: Limit who can deploy to production
4. **Audit Trail**: Monitor all deployment activities

### Cost Optimization
1. **Right-Sizing**: Use appropriate instance types
2. **Resource Cleanup**: Remove unused resources
3. **Monitoring**: Set up billing alerts
4. **Scheduling**: Stop dev resources when not needed

## Support and Maintenance

### Regular Tasks
- Review and update AMI mappings
- Update CloudFormation templates
- Monitor AWS service changes
- Review security configurations

### Documentation Updates
- Keep CSV configuration guide current
- Update architecture documentation
- Document any custom modifications
- Maintain troubleshooting guides