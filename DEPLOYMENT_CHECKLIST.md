# 🚀 AWS Infrastructure Deployment Checklist

## ✅ **Solution Complete - Ready for Deployment**

Your CSV-driven AWS infrastructure solution is ready! Follow this checklist to deploy your infrastructure.

## 📋 **Pre-Deployment Checklist**

### ✅ Repository Setup
- [x] Repository created with all 23 files
- [x] CSV configuration validated (`config/customer.csv`)
- [x] CloudFormation templates ready
- [x] GitHub Actions workflow configured
- [x] Documentation complete

### 🔧 **What's Included**
- **Infrastructure**: VPC, Subnets, IGW, NAT, Security Groups, EC2
- **Operating System**: Windows Server 2022
- **Instance Type**: t3.medium (as per your BOM)
- **Storage**: 40GB GP3 EBS volume
- **Region**: Asia Pacific (Hyderabad) - ap-south-1
- **Security**: RDP, HTTP, HTTPS access + SSM integration

## 🎯 **Deployment Steps**

### Step 1: Push to GitHub
```bash
# If you haven't already set up the remote
git remote add origin https://github.com/YOUR-USERNAME/aws-infra.git
git branch -M main
git push -u origin main
```

### Step 2: Configure GitHub Repository

**A. Repository Secrets** (Settings → Secrets and variables → Actions):
- `AWS_ACCOUNT_ID`: Your 12-digit AWS Account ID

**B. Repository Variables**:
- `AWS_REGION`: `ap-south-1` (or your preferred region)

**C. GitHub Environments** (Settings → Environments):
- Create `development` environment
- Create `production` environment
  - Add protection rules (required reviewers)
  - Restrict to main branch

### Step 3: Bootstrap AWS Account (One-time Setup)

Run these commands in your terminal with AWS CLI configured:

```bash
# 1. Deploy OIDC Provider
aws cloudformation deploy \
  --template-file bootstrap/oidc-provider.yml \
  --stack-name github-oidc-provider \
  --parameter-overrides \
    GitHubOrganization=YOUR-GITHUB-USERNAME \
    RepositoryName=aws-infra \
  --region ap-south-1

# 2. Deploy Dev Role
aws cloudformation deploy \
  --template-file bootstrap/github-deploy-role.yml \
  --stack-name github-deploy-role-dev \
  --parameter-overrides \
    OIDCProviderStackName=github-oidc-provider \
    Environment=dev \
  --capabilities CAPABILITY_IAM \
  --region ap-south-1

# 3. Deploy Prod Role
aws cloudformation deploy \
  --template-file bootstrap/github-deploy-role.yml \
  --stack-name github-deploy-role-prod \
  --parameter-overrides \
    OIDCProviderStackName=github-oidc-provider \
    Environment=prod \
  --capabilities CAPABILITY_IAM \
  --region ap-south-1
```

### Step 4: Deploy Infrastructure

1. **Go to GitHub Actions**:
   - Navigate to your repository
   - Click "Actions" tab
   - Select "Deploy AWS Infrastructure" workflow

2. **Run Workflow**:
   - Click "Run workflow"
   - Select Environment: `dev`
   - Select Action: `deploy`
   - Click "Run workflow"

3. **Monitor Deployment**:
   - Watch the workflow progress
   - Check CloudFormation stacks in AWS Console
   - Verify resources are created successfully

### Step 5: Validate Deployment

```bash
# Check deployed stacks
aws cloudformation list-stacks \
  --stack-status-filter CREATE_COMPLETE \
  --query 'StackSummaries[?starts_with(StackName, `dev-`)].{Name:StackName,Status:StackStatus}' \
  --region ap-south-1

# Get EC2 instance information
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" \
  --query 'Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,State:State.Name,PublicIP:PublicIpAddress}' \
  --region ap-south-1
```

## 🔄 **Making Changes**

To modify your infrastructure:

1. **Edit CSV**: Modify `config/customer.csv`
2. **Commit**: `git add . && git commit -m "Update infrastructure"`
3. **Push**: `git push`
4. **Deploy**: Run GitHub Actions workflow again

## 📊 **Expected Resources**

After successful deployment, you'll have:

- **VPC**: `dev-vpc` (10.0.0.0/16)
- **Subnets**: 2 public + 2 private subnets
- **Internet Gateway**: `dev-igw`
- **NAT Gateway**: `dev-nat` (single for cost optimization)
- **Security Groups**: Web access + RDP
- **EC2 Instance**: Windows Server 2022, t3.medium
- **Auto Scaling Group**: Manages instance lifecycle
- **IAM Role**: For SSM access

## 💰 **Cost Estimate**

Based on your original BOM:
- **EC2 t3.medium**: ~$139.53/month
- **VPC Public IP**: ~$3.65/month
- **NAT Gateway**: ~$45/month
- **EBS Storage**: ~$4/month (40GB GP3)
- **Total**: ~$192/month

## 🔒 **Security Features**

- ✅ OIDC authentication (no AWS keys in GitHub)
- ✅ Encrypted EBS volumes
- ✅ VPC Flow Logs
- ✅ SSM integration for secure access
- ✅ Least privilege IAM roles
- ✅ Environment isolation

## 🆘 **Troubleshooting**

### Common Issues:

1. **OIDC Authentication Failed**:
   - Verify GitHub organization/repository names
   - Check OIDC provider configuration

2. **CloudFormation Stack Failed**:
   - Check AWS Console for detailed error messages
   - Verify service limits and quotas

3. **CSV Parsing Errors**:
   - Validate CSV format and syntax
   - Check for missing dependencies

### Support Resources:
- [Architecture Documentation](docs/architecture.md)
- [CSV Configuration Guide](docs/csv-configuration-guide.md)
- [Deployment Guide](docs/deployment-guide.md)
- [Dependency Map](docs/dependency-map.md)

## 🎉 **Success Criteria**

Your deployment is successful when:
- ✅ All CloudFormation stacks show `CREATE_COMPLETE`
- ✅ EC2 instance is running and accessible via SSM
- ✅ Security groups allow required access
- ✅ VPC and networking components are operational

## 🚀 **Next Steps After Deployment**

1. **Connect to Instance**: Use AWS Systems Manager Session Manager
2. **Install Applications**: Deploy your web applications
3. **Configure Monitoring**: Set up CloudWatch alarms
4. **Production Deployment**: Deploy to prod environment
5. **Expand Infrastructure**: Add ALB, RDS, etc. via CSV

---

**🎯 Your infrastructure is now code-driven, version-controlled, and production-ready!**