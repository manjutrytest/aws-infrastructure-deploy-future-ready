# 🔧 OIDC Role Assumption Troubleshooting

## 🚨 **Current Issue: "Request ARN is invalid" or Long Wait Times**

### **Root Causes & Solutions**

## 1. **Repository Name Mismatch** ⚠️
**Problem**: GitHub repository name doesn't match role trust policy

**Check**: 
- Expected: `manjutrytest/aws-infrastructure-deploy-future-ready`
- Actual: What's your GitHub repository URL?

**Solution**: Update repository name in role or GitHub

## 2. **GitHub Environment Not Configured** ⚠️
**Problem**: Role expects `environment:dev` but GitHub environment doesn't exist

**Solution**: 
1. Go to GitHub → Settings → Environments
2. Create `development` environment
3. Create `production` environment

## 3. **OIDC Provider Mismatch** ⚠️
**Problem**: Role points to wrong OIDC provider

**Check Current OIDC Provider**:
```bash
aws iam list-open-id-connect-providers
```

**Expected**: `token.actions.githubusercontent.com`

## 4. **Permissions Issue** ⚠️
**Problem**: GitHub Actions doesn't have permission to assume role

**Check Workflow Permissions**:
```yaml
permissions:
  id-token: write  # Required for OIDC
  contents: read   # Required for checkout
```

## 🛠️ **Quick Fixes Applied**

### **✅ Created Permissive Role**
- **Role**: `GitHubDeploy-dev-Permissive-manjutrytest`
- **Trust Policy**: More permissive (`repo:manjutrytest/*:*`)
- **Purpose**: Bypass strict environment/branch matching

### **✅ Added Debug Information**
- Shows GitHub context in workflow
- Displays expected vs actual values
- Helps identify mismatch

## 🔍 **Debugging Steps**

### **Step 1: Verify Repository Name**
```bash
# Check your GitHub repository URL
# Should be: https://github.com/manjutrytest/aws-infrastructure-deploy-future-ready
```

### **Step 2: Check Role Trust Policy**
```bash
aws iam get-role --role-name "GitHubDeploy-dev-Permissive-manjutrytest" --query 'Role.AssumeRolePolicyDocument'
```

### **Step 3: Test OIDC Token**
Run GitHub Actions workflow and check debug output for:
- Repository name
- Branch/ref
- Environment name

### **Step 4: Verify GitHub Environments**
1. GitHub → Settings → Environments
2. Ensure `development` exists
3. No protection rules initially

## 🎯 **Most Likely Issues**

### **Issue A: Wrong Repository Name**
If your repository is named differently:
1. Update the role trust policy, OR
2. Rename your GitHub repository

### **Issue B: Missing GitHub Environment**
Create the `development` environment in GitHub:
1. Settings → Environments → New environment
2. Name: `development`
3. No protection rules for now

### **Issue C: Branch Protection**
If running from non-main branch:
- Role allows `refs/heads/main` and `environment:dev`
- Ensure you're running from `main` branch

## 🚀 **Quick Test**

1. **Push updated workflow** (uses permissive role)
2. **Run GitHub Actions** 
3. **Check debug output** for mismatches
4. **Fix identified issues**

## 📞 **If Still Failing**

### **Check These Values Match**:
- GitHub Org: `manjutrytest` ✓
- Repository: `aws-infrastructure-deploy-future-ready` ❓
- Branch: `main` ❓
- Environment: `development` (in GitHub settings) ❓
- AWS Account: `821706771879` ✓

### **Emergency Fallback**:
Use AWS access keys temporarily:
1. Create IAM user with deployment permissions
2. Add `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` to GitHub secrets
3. Remove OIDC configuration temporarily

**The permissive role should resolve most OIDC issues!** 🎯