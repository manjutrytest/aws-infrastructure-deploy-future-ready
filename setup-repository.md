# Repository Setup Guide

## Prerequisites

1. **AWS Account**: Target AWS account in eu-north-1 region
2. **OIDC Provider**: Existing AWS OIDC provider configured
3. **IAM Role**: Existing deployment role with CloudFormation permissions
4. **GitHub Repository**: This repository pushed to GitHub

## Required GitHub Secrets

Configure these secrets in your GitHub repository settings:

### AWS Configuration
- `AWS_ACCOUNT_ID`: Your AWS account ID (12-digit number)
- `AWS_DEPLOYMENT_ROLE`: Name of your existing IAM deployment role

Example values:
```
AWS_ACCOUNT_ID: 123456789012
AWS_DEPLOYMENT_ROLE: GitHubActionsDeploymentRole
```

## GitHub Environment Setup

1. Go to your repository **Settings** → **Environments**
2. Create environment named: `production-approval`
3. Configure **Required reviewers**: Add team members who can approve deployments
4. Enable **Wait timer**: Optional delay before deployment
5. Save environment settings

## IAM Role Trust Policy Update

Update your existing IAM role's trust policy to allow this repository:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

Replace:
- `YOUR_ACCOUNT_ID`: Your AWS account ID
- `YOUR_GITHUB_USERNAME`: Your GitHub username/organization
- `YOUR_REPO_NAME`: This repository name

## IAM Role Permissions

Ensure your deployment role has these permissions:

### CloudFormation Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudformation:CreateStack",
        "cloudformation:DescribeStacks",
        "cloudformation:DescribeStackEvents",
        "cloudformation:DescribeStackResources",
        "cloudformation:GetTemplate",
        "cloudformation:ListStacks",
        "cloudformation:ValidateTemplate"
      ],
      "Resource": "*"
    }
  ]
}
```

### EC2 Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### IAM Permissions (for service roles)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:CreateInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:AttachRolePolicy",
        "iam:PassRole",
        "iam:GetRole",
        "iam:GetInstanceProfile",
        "iam:TagRole"
      ],
      "Resource": "*"
    }
  ]
}
```

### S3 Permissions (for database backups)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:PutBucketEncryption",
        "s3:PutBucketVersioning",
        "s3:PutLifecycleConfiguration",
        "s3:PutBucketPublicAccessBlock",
        "s3:PutBucketTagging"
      ],
      "Resource": "*"
    }
  ]
}
```

### CloudWatch Logs Permissions
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:TagLogGroup"
      ],
      "Resource": "*"
    }
  ]
}
```

## First Deployment

1. **Update BOM**: Modify `bom/customer-bom.csv` with your requirements
2. **Commit Changes**: Push BOM changes to main branch
3. **Run Workflow**: Go to Actions → "Deploy Infrastructure" → "Run workflow"
4. **Provide Inputs**:
   - Customer: Your customer name (e.g., "acme")
   - Environment: "dev" (for first deployment)
   - VPC CIDR: Optional override (e.g., "10.1.0.0/16")
5. **Approve Deployment**: Approve in the GitHub Environment when prompted
6. **Monitor Progress**: Watch the deployment in Actions tab

## Verification

After successful deployment, verify in AWS Console:

1. **CloudFormation**: Check stacks are created successfully
2. **VPC**: Verify network foundation is deployed
3. **EC2**: Check instances are running
4. **IAM**: Verify service roles are created
5. **S3**: Check backup buckets (for database services)

## Troubleshooting

### Common Issues

1. **Permission Denied**: Check IAM role permissions and trust policy
2. **Stack Already Exists**: Use different instance IDs in BOM
3. **Invalid CIDR**: Verify VPC CIDR format in BOM
4. **Template Not Found**: Ensure service templates exist

### Getting Help

1. Check workflow logs in GitHub Actions
2. Review CloudFormation events in AWS Console
3. Validate BOM using: `python scripts/validate-bom.py`
4. Check stack outputs for resource information

## Next Steps

1. **Add Services**: Update BOM to add more services
2. **Scale Up**: Deploy additional instances with new instance IDs
3. **Environment Promotion**: Deploy to staging/prod environments
4. **Monitoring**: Set up CloudWatch alarms and dashboards
5. **Backup Testing**: Verify database backup and restore procedures

## Security Recommendations

1. **Restrict CIDR**: Update bastion security groups with specific IP ranges
2. **Key Management**: Rotate EC2 key pairs regularly
3. **Access Review**: Regularly review IAM permissions
4. **Monitoring**: Enable CloudTrail and Config for compliance
5. **Encryption**: Verify all data is encrypted at rest and in transit