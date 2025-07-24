# 🚀 TubbyAI Development Sprint Guide

## Overview

This guide provides a comprehensive approach to running development sprints for the TubbyAI platform, addressing the critical deployment issues and establishing robust CI/CD workflows.

## 🎯 Sprint Goals

1. **Fix Critical Deployment Issue** - Resolve Windows path separator incompatibility
2. **Establish Automated CI/CD** - Create reliable deployment pipelines
3. **Improve Development Workflow** - Streamline testing and deployment processes
4. **Document Everything** - Ensure team can replicate success

## 📋 Prerequisites

### Required Tools
- **AWS CLI** - For AWS service interaction
- **7-Zip** - For Unix-compatible ZIP creation (Windows)
- **Docker** - Alternative deployment method
- **Git** - Version control and deployment
- **Node.js** - Frontend development
- **Python 3.11** - Backend development

### AWS Setup
- AWS account with Elastic Beanstalk access
- IAM user with appropriate permissions
- Configured AWS credentials (`aws configure`)

## 🚀 Quick Start

### 1. Sprint Initialization
```powershell
# Start a new sprint
.\scripts\sprint-manager.ps1 -SprintAction start

# Check system health
.\scripts\sprint-manager.ps1 -SprintAction test
```

### 2. Deployment Options

#### Option A: 7-Zip Deployment (Recommended for Windows)
```powershell
# Install 7-Zip from https://7-zip.org/
# Then run deployment
.\scripts\sprint-deployment-automation.ps1 -DeploymentType 7zip
```

#### Option B: Docker Deployment (Most Reliable)
```powershell
# Requires Docker Desktop
.\scripts\deploy-docker-backend.ps1 -Environment development
```

#### Option C: Git Deployment
```powershell
# Requires clean Git repository
.\scripts\deploy_with_git.ps1
```

### 3. Full Sprint Workflow
```powershell
# Complete sprint workflow
.\scripts\sprint-manager.ps1 -SprintAction deploy -Environment development
.\scripts\sprint-manager.ps1 -SprintAction monitor
.\scripts\sprint-manager.ps1 -SprintAction cleanup
```

## 🔧 Deployment Methods

### 1. 7-Zip Method
**Pros:**
- Fast and lightweight
- No additional services required
- Works on Windows

**Cons:**
- Requires 7-Zip installation
- Windows-specific solution

**Usage:**
```powershell
.\scripts\sprint-deployment-automation.ps1 -DeploymentType 7zip
```

### 2. Docker Method
**Pros:**
- Cross-platform compatibility
- Consistent Linux environment
- Most reliable deployment

**Cons:**
- Requires Docker installation
- Slightly slower build process

**Usage:**
```powershell
.\scripts\deploy-docker-backend.ps1 -Environment development
```

### 3. Git Method
**Pros:**
- No manual ZIP creation
- Direct from repository
- Automated deployment

**Cons:**
- Requires clean repository
- Limited to Git-based workflows

**Usage:**
```powershell
.\scripts\deploy_with_git.ps1
```

## 🧪 Testing Strategy

### Frontend Testing
```powershell
# Build test
npm run build:prod

# Unit tests (if configured)
npm run test
```

### Backend Testing
```powershell
# Navigate to backend directory
cd backend

# Run tests
python -m pytest tests/ -v

# Basic functionality test
python hello_world.py
```

### Integration Testing
```powershell
# Test basic connectivity
.\scripts\sprint-manager.ps1 -SprintAction test
```

## 📊 Monitoring and Debugging

### Deployment Monitoring
```powershell
# Monitor deployment status
.\scripts\sprint-manager.ps1 -SprintAction monitor

# Check specific environment
aws elasticbeanstalk describe-environments --application-name tubbyai
```

### Log Analysis
```powershell
# View Elastic Beanstalk logs
aws elasticbeanstalk retrieve-environment-info --environment-name your-env-name

# Check application logs
aws logs describe-log-groups --log-group-name-prefix /aws/elasticbeanstalk
```

### Health Checks
```powershell
# Check environment health
aws elasticbeanstalk describe-environments --application-name tubbyai --query 'Environments[].{Name:EnvironmentName,Health:Health,Status:Status}'
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow
The project includes a comprehensive GitHub Actions workflow (`.github/workflows/deploy-sprint.yml`) that:

1. **Runs Tests** - Validates code quality
2. **Builds Applications** - Creates deployment packages
3. **Deploys Backend** - Uses Linux-based ZIP creation
4. **Deploys Frontend** - Uses AWS Amplify
5. **Notifies Team** - Provides deployment summaries

### Manual Trigger
```bash
# Trigger deployment from GitHub
gh workflow run deploy-sprint.yml -f deployment_type=7zip -f environment=development
```

### Automated Triggers
- **Push to main** - Automatic deployment to production
- **Push to develop** - Automatic deployment to staging
- **Pull Request** - Runs tests only

## 🛠️ Troubleshooting

### Common Issues

#### 1. 7-Zip Not Found
```powershell
# Solution: Install 7-Zip
# Download from: https://7-zip.org/
# Install to default location: C:\Program Files\7-Zip\
```

#### 2. AWS Credentials Not Configured
```powershell
# Solution: Configure AWS CLI
aws configure
# Enter your AWS Access Key ID, Secret Access Key, Region, and Output format
```

#### 3. Docker Not Available
```powershell
# Solution: Install Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop/
# Start Docker Desktop before running deployment
```

#### 4. Deployment Fails with ZIP Error
```powershell
# Solution: Use Docker deployment instead
.\scripts\deploy-docker-backend.ps1
```

### Debug Commands
```powershell
# Check system health
.\scripts\sprint-manager.ps1 -SprintAction start

# Test deployment without actual deployment
.\scripts\sprint-deployment-automation.ps1 -DeploymentType 7zip -SkipTests

# Monitor deployment in real-time
.\scripts\sprint-manager.ps1 -SprintAction monitor
```

## 📈 Sprint Metrics

### Success Criteria
- [ ] **Deployment Success Rate** > 95%
- [ ] **Deployment Time** < 30 minutes
- [ ] **Test Coverage** > 80%
- [ ] **Zero Critical Issues** in production

### Key Performance Indicators
- **Build Time** - Time to create deployment package
- **Deployment Time** - Time from package to live environment
- **Success Rate** - Percentage of successful deployments
- **Rollback Time** - Time to revert failed deployments

## 🔄 Sprint Workflow

### Phase 1: Preparation
1. **System Health Check**
   ```powershell
   .\scripts\sprint-manager.ps1 -SprintAction start
   ```

2. **Code Review**
   - Ensure all tests pass
   - Review deployment configuration
   - Check environment variables

### Phase 2: Deployment
1. **Choose Deployment Method**
   - 7-Zip (Windows, fast)
   - Docker (cross-platform, reliable)
   - Git (automated, clean)

2. **Execute Deployment**
   ```powershell
   .\scripts\sprint-manager.ps1 -SprintAction deploy
   ```

### Phase 3: Validation
1. **Monitor Deployment**
   ```powershell
   .\scripts\sprint-manager.ps1 -SprintAction monitor
   ```

2. **Health Checks**
   - Verify application endpoints
   - Check error logs
   - Validate functionality

### Phase 4: Cleanup
1. **Remove Temporary Files**
   ```powershell
   .\scripts\sprint-manager.ps1 -SprintAction cleanup
   ```

2. **Document Results**
   - Update deployment logs
   - Record any issues
   - Plan improvements

## 📚 Additional Resources

### Documentation
- [Deployment Instructions.md](Deployment Instructions.md) - Detailed deployment guide
- [DEVELOPMENT_STATUS_UPDATE.md](DEVELOPMENT_STATUS_UPDATE.md) - Current status
- [BUG_BOUNTY_ELASTIC_BEANSTALK_DEPLOYMENT_CRITICAL.md](BUG_BOUNTY_ELASTIC_BEANSTALK_DEPLOYMENT_CRITICAL.md) - Issue analysis

### Scripts
- `scripts/sprint-manager.ps1` - Main sprint orchestration
- `scripts/sprint-deployment-automation.ps1` - Comprehensive deployment
- `scripts/deploy-docker-backend.ps1` - Docker-based deployment
- `scripts/create_unix_zip_with_7zip.ps1` - 7-Zip deployment

### AWS Resources
- [Elastic Beanstalk Documentation](https://docs.aws.amazon.com/elasticbeanstalk/)
- [Amplify Documentation](https://docs.aws.amazon.com/amplify/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/)

## 🎯 Next Steps

### Immediate Actions
1. **Install 7-Zip** on all development machines
2. **Test deployment** using provided scripts
3. **Document any issues** encountered
4. **Train team** on new deployment process

### Long-term Improvements
1. **Implement full CI/CD** pipeline
2. **Add comprehensive testing** suite
3. **Create staging environment** for testing
4. **Automate monitoring** and alerting

---

## 📞 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review the deployment logs
3. Consult the AWS documentation
4. Contact the development team

**Remember:** Always test deployments in development environment before production! 