# 🚀 AWS Backend Deployment Guide

## Overview

This guide will help you deploy the Tubby AI Flask backend to AWS. We'll use **AWS Elastic Beanstalk** for the backend deployment, which is the recommended approach for Flask applications with WebSocket support.

## 🎯 **Deployment Options**

### Option 1: AWS Elastic Beanstalk (Recommended)
- ✅ **Best for Flask applications**
- ✅ **Supports WebSocket connections**
- ✅ **Auto-scaling and load balancing**
- ✅ **Easy deployment and management**

### Option 2: AWS ECS with Fargate
- ✅ **Container-based deployment**
- ✅ **More control over infrastructure**
- ✅ **Cost-effective for production**

### Option 3: AWS Lambda + API Gateway
- ❌ **Not recommended for WebSocket support**
- ❌ **Limited for long-running connections**

## 📋 **Prerequisites**

1. **AWS Account** with appropriate permissions
2. **AWS CLI** installed and configured
3. **Elastic Beanstalk CLI** installed
4. **Domain name** (api.tubbyai.com) configured

## 🛠 **Step-by-Step Deployment**

### Step 1: Install Required Tools

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install EB CLI
pip install awsebcli

# Configure AWS credentials
aws configure
```

### Step 2: Prepare Backend for Deployment

The backend is already configured for deployment with:
- ✅ `backend/app_production.py` - Production Flask app
- ✅ `backend/requirements_production.txt` - Production dependencies
- ✅ `backend/gunicorn.conf.py` - Gunicorn configuration
- ✅ `backend/Dockerfile` - Docker configuration

### Step 3: Deploy Using Script

```bash
# Make script executable
chmod +x scripts/deploy-backend-eb.sh

# Run deployment
./scripts/deploy-backend-eb.sh
```

### Step 4: Manual Deployment (Alternative)

If you prefer manual deployment:

```bash
# Create deployment package
mkdir deploy-backend
cp -r backend/* deploy-backend/
cd deploy-backend

# Initialize EB application
eb init tubby-backend --platform "Python 3.11" --region us-east-1

# Create environment
eb create tubby-backend-prod

# Deploy
eb deploy
```

## 🔧 **Configuration**

### Environment Variables

The deployment script automatically configures these environment variables:

```env
FLASK_ENV=production
SECRET_KEY=your-secret-key
SUPABASE_URL=https://bemssfbadcfrvzbgjlu.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
STRIPE_PUBLISHABLE_KEY=pk_live_your-stripe-publishable-keyOsUMH2Ie6b7SBOvZucOAUFkyPo0PqCsqZmLZq2Kqpzp3qLQa65KQ0jlrLWP3kXSRp00A1NZSjVt
STRIPE_SECRET_KEY=sk_live_your-stripe-secret-keymR9W4gkAPJSqb2xLEHtZdE76khA7tX4j7U0WZZzNy310Zi4eWdnhGQX8JTKYALrf000F7MNxVVx
STRIPE_BASIC_PRICE_ID=price_1RnI7vKoB6ANfJLNft6upLIC
STRIPE_PRO_PRICE_ID=price_1RnI8LBKoB6ANfJLNRNUyRVIX
STRIPE_ENTERPRISE_PRICE_ID=price_1RnI9FKoB6ANfJLNwZTZ5M8A
BACKEND_URL=https://api.tubbyai.com
FRONTEND_URL=https://tubbyai.com
```

### Domain Configuration

1. **Create Route 53 hosted zone** for `api.tubbyai.com`
2. **Point to Elastic Beanstalk environment**
3. **Configure SSL certificate** using AWS Certificate Manager

## 🔍 **Post-Deployment Steps**

### Step 1: Update Frontend Configuration

Update your frontend environment variables:

```env
VITE_API_URL=https://api.tubbyai.com
```

### Step 2: Test the Deployment

```bash
# Test health endpoint
curl https://api.tubbyai.com/health

# Test authentication
curl https://api.tubbyai.com/auth/user

# Test Stripe endpoint (requires authentication)
curl -X POST https://api.tubbyai.com/stripe/create-checkout-session \
  -H "Content-Type: application/json" \
  -d '{"plan_type": "basic"}'
```

### Step 3: Monitor the Application

- **AWS CloudWatch** for logs and metrics
- **Elastic Beanstalk Console** for environment health
- **Application logs** for debugging

## 🚨 **Troubleshooting**

### Common Issues

1. **Deployment Fails**
   ```bash
   # Check logs
   eb logs
   
   # Check environment health
   eb health
   ```

2. **WebSocket Connection Issues**
   - Ensure load balancer supports WebSocket
   - Check security groups allow WebSocket traffic

3. **Environment Variables Not Set**
   ```bash
   # Check environment variables
   eb printenv
   
   # Set missing variables
   eb setenv VARIABLE_NAME=value
   ```

### Performance Optimization

1. **Auto Scaling**
   - Configure auto-scaling based on CPU/memory
   - Set minimum and maximum instances

2. **Load Balancing**
   - Use Application Load Balancer
   - Configure health checks

3. **Caching**
   - Use ElastiCache for Redis
   - Configure session storage

## 💰 **Cost Optimization**

1. **Instance Types**
   - Start with t3.small for development
   - Scale up based on usage

2. **Auto Scaling**
   - Scale down during low usage
   - Use scheduled scaling for predictable patterns

3. **Reserved Instances**
   - Purchase reserved instances for production
   - Save up to 70% on costs

## 🔒 **Security Considerations**

1. **HTTPS Only**
   - Force HTTPS redirects
   - Use AWS Certificate Manager

2. **Security Groups**
   - Restrict access to necessary ports only
   - Use VPC for network isolation

3. **Environment Variables**
   - Store secrets in AWS Secrets Manager
   - Use IAM roles for service access

## 📊 **Monitoring and Logging**

1. **CloudWatch Logs**
   - Application logs
   - Access logs
   - Error logs

2. **CloudWatch Metrics**
   - CPU utilization
   - Memory usage
   - Request count

3. **Custom Metrics**
   - Stripe API calls
   - Authentication attempts
   - WebSocket connections

## 🎉 **Success Criteria**

After deployment, you should have:

- ✅ Backend accessible at `https://api.tubbyai.com`
- ✅ Health endpoint responding
- ✅ Authentication working
- ✅ Stripe checkout sessions working
- ✅ WebSocket connections working
- ✅ No CORS errors
- ✅ Proper SSL certificate

## 🔄 **Continuous Deployment**

Set up CI/CD pipeline:

1. **GitHub Actions** or **AWS CodePipeline**
2. **Automatic deployment** on main branch
3. **Environment promotion** (dev → staging → prod)
4. **Rollback capabilities**

## 📞 **Support**

If you encounter issues:

1. Check the troubleshooting section above
2. Review AWS Elastic Beanstalk documentation
3. Check application logs in CloudWatch
4. Contact AWS support if needed

---

**Next Steps:**
1. Run the deployment script
2. Configure your domain
3. Update frontend environment variables
4. Test the complete flow
5. Monitor and optimize 
