# 🚀 GitHub Actions Deployment Guide

## ✅ **Current Status**
- **OIDC Authentication**: ✅ Working (using permissive role)
- **AWS Bootstrap**: ✅ Complete (roles created)
- **CSV Configuration**: ✅ Updated (key pair fixed to 'test')
- **Infrastructure Stacks**: ✅ VPC, Subnets, IGW, NAT, Security Groups deployed
- **EC2 Stack**: 🔄 Ready for deployment with correct key pair

## 🎯 **GitHub Actions Deployment Steps**

### **Step 1: Push Latest Changes**
```bash
git push origin main
```

### **Step 2: Configure GitHub Repository**

**A. Repository Settings → Secrets and Variables → Actions:**

**Secrets**: (None needed - using OIDC)

**Variables**:
- `AWS_REGION`: `ap-south-1`

**B. Repository Settings → Environments:**
- Create `development` environment (no protection rules for now)
- Create `production` environment (with protection rules)

### **Step 3: Run GitHub Actions Workflow**

1. **Go to GitHub Repository**
2. **Click "Actions" tab**
3. **Select "Deploy AWS Infrastructure" workflow**
4. **Click "Run workflow"**
5. **Configure:**
   - **Environment**: `dev`
   - **Action**: `deploy`
   - **Stack Filter**: (leave empty for all stacks)
6. **Click "Run workflow"**

## 🔧 **What GitHub Actions Will Do**

### **Validation Job**:
- ✅ Parse CSV configuration
- ✅ Generate CloudFormation parameters
- ✅ Check template files exist
- ✅ Create deployment order

### **Deploy-Dev Job**:
- ✅ Authenticate via OIDC (using permissive role)
- ✅ Validate CloudFormation templates with AWS
- ✅ Deploy stacks in order:
  1. VPC (already exists - will skip or update)
  2. Subnets (already exists - will skip or update)
  3. IGW (already exists - will skip or update)
  4. NAT (already exists - will skip or update)
  5. Security Groups (already exists - will skip or update)
  6. **EC2 (will deploy with correct key pair 'test')**

## 🎯 **Expected Results**

After successful deployment:
- **EC2 Instance**: Windows Server 2022, t3.medium
- **Key Pair**: `test` (your existing key pair)
- **Placement**: Public subnet with public IP
- **Security**: RDP (3389), HTTP (80), HTTPS (443) access
- **Management**: SSM enabled for secure access
- **Storage**: 40GB GP3 encrypted volume

## 🔍 **Monitoring Deployment**

### **GitHub Actions Logs**:
- Real-time progress in Actions tab
- CSV parsing output
- CloudFormation deployment status
- Any error messages

### **AWS Console**:
- CloudFormation → Stacks → `dev-ec2`
- EC2 → Instances (new instance will appear)
- VPC → Your VPC resources

## 🆘 **If Deployment Fails**

### **Common Issues**:

1. **Key Pair Still Shows 'my-keypair'**:
   - CSV parsing might have cached old values
   - Check GitHub Actions logs for CSV parsing output
   - Verify the bash script is reading the updated CSV

2. **OIDC Authentication Fails**:
   - Ensure `development` environment exists in GitHub
   - Check repository name matches exactly
   - Verify you're running from `main` branch

3. **CloudFormation Template Errors**:
   - Check AWS CloudFormation console for detailed errors
   - Review template validation step in GitHub Actions

### **Debug Commands** (if needed):
```bash
# Check current stacks
aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE

# Check failed stack events
aws cloudformation describe-stack-events --stack-name dev-ec2

# Check key pairs
aws ec2 describe-key-pairs --region ap-south-1
```

## 🎉 **Success Indicators**

✅ **GitHub Actions workflow completes successfully**
✅ **All CloudFormation stacks show CREATE_COMPLETE or UPDATE_COMPLETE**
✅ **EC2 instance is running in AWS console**
✅ **Instance has public IP and security groups attached**
✅ **SSM Session Manager shows instance as available**

## 🚀 **After Successful Deployment**

### **Connect to Instance**:
1. **AWS Console → EC2 → Instances**
2. **Select your instance → Connect → Session Manager**
3. **Or use RDP with key pair 'test'**

### **Verify Infrastructure**:
- Check VPC and subnets
- Verify security group rules
- Test internet connectivity
- Confirm SSM access

### **Next Steps**:
- Deploy applications to the instance
- Set up monitoring and alerting
- Deploy to production environment
- Expand infrastructure via CSV

---

**🎯 Your CSV-driven AWS infrastructure is ready for GitHub Actions deployment!**

**Key Fix Applied**: Updated CSV to use existing key pair `test` instead of non-existent `my-keypair`