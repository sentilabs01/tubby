# AWS Amplify Deployment Guide for Tubby AI

This guide will help you deploy the Tubby AI application to AWS Amplify via GitHub.

## Prerequisites

1. **AWS Account**: You need an active AWS account
2. **GitHub Repository**: Your code should be in a GitHub repository
3. **Environment Variables**: All necessary environment variables should be configured

## Step 1: Prepare Your Repository

### 1.1 Environment Variables Setup

Copy the `env.example` file to `.env` and fill in your actual values:

```bash
cp env.example .env
```

**Required Environment Variables:**

- **Supabase Configuration**: Database and authentication
- **OAuth Credentials**: Google and GitHub OAuth apps
- **Stripe Keys**: Payment processing
- **Redis Configuration**: Session and cache storage
- **CORS Origins**: Allowed frontend domains

### 1.2 Backend Services Setup

For production deployment, you'll need to set up:

1. **Supabase Database**: Configure your production database
2. **Redis Instance**: Use AWS ElastiCache or a managed Redis service
3. **Container Services**: Deploy your MCP containers separately

## Step 2: AWS Amplify Setup

### 2.1 Connect Your Repository

1. Go to [AWS Amplify Console](https://console.aws.amazon.com/amplify/)
2. Click "New app" → "Host web app"
3. Choose "GitHub" as your repository source
4. Authorize AWS Amplify to access your GitHub account
5. Select your repository and branch (usually `main`)

### 2.2 Configure Build Settings

Amplify will automatically detect the `amplify.yml` configuration file. The build process will:

1. **Frontend Build**:
   - Install Node.js dependencies
   - Build the React application
   - Deploy to Amplify hosting

2. **Backend Build**:
   - Install Python dependencies
   - Prepare the Flask application
   - Deploy to Amplify backend

### 2.3 Environment Variables in Amplify

In the Amplify console, go to "Environment variables" and add:

```
FLASK_ENV=production
SECRET_KEY=your-secure-secret-key
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GITHUB_CLIENT_ID=your-github-client-id
GITHUB_CLIENT_SECRET=your-github-client-secret
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_WEBHOOK_SECRET=your-stripe-webhook-secret
REDIS_HOST=your-redis-host
REDIS_PORT=6379
ALLOWED_ORIGINS=https://tubbyai.com,http://localhost:3001
VITE_API_URL=https://tubbyai.com
BACKEND_URL=https://api.tubbyai.com
```

## Step 3: Backend Deployment

### 3.1 Amplify Backend Setup

1. In your Amplify app, go to "Backend environments"
2. Click "Create backend environment"
3. Choose "Create a new environment"
4. Select "Python" as the runtime
5. Configure the backend settings

### 3.2 Backend Configuration

The backend will be deployed using:
- **Runtime**: Python 3.11
- **Entry Point**: `backend/start_production.py`
- **Requirements**: `backend/requirements_production.txt`

### 3.3 Health Check

The backend includes a health check endpoint at `/health` that Amplify will use to verify the deployment.

## Step 4: Frontend Configuration

### 4.1 API URL Configuration

Update your frontend to use the production API URL:

1. Set the `VITE_API_URL` environment variable in Amplify
2. The Vite configuration will automatically use this for API calls
3. Update OAuth redirect URLs in your OAuth providers

### 4.2 CORS Configuration

Ensure your backend CORS settings include your production domain:

```
ALLOWED_ORIGINS=https://tubbyai.com,http://localhost:3001
```

## Step 5: External Services Setup

### 5.1 Redis Setup

For production, you'll need a Redis instance:

1. **AWS ElastiCache**: Recommended for AWS integration
2. **Redis Cloud**: Alternative managed Redis service
3. **Self-hosted**: If you prefer to manage your own Redis

### 5.2 Container Services

Deploy your MCP containers to:
- **AWS ECS**: Container orchestration
- **AWS Lambda**: Serverless functions
- **EC2**: Traditional server deployment

### 5.3 Database Setup

1. **Supabase**: Configure production database
2. **Backup Strategy**: Set up automated backups
3. **Monitoring**: Enable database monitoring

## Step 6: Domain and SSL

### 6.1 Custom Domain (Optional)

1. In Amplify, go to "Domain management"
2. Add your custom domain
3. Configure DNS settings
4. SSL certificate will be automatically provisioned

### 6.2 SSL Configuration

Amplify automatically provides SSL certificates for:
- `*.amplifyapp.com` domains
- Custom domains (when properly configured)

## Step 7: Monitoring and Logs

### 7.1 Amplify Monitoring

- **Build Logs**: View build and deployment logs
- **Access Logs**: Monitor application access
- **Error Logs**: Track application errors

### 7.2 Application Monitoring

Consider setting up:
- **AWS CloudWatch**: Application metrics
- **Sentry**: Error tracking
- **Google Analytics**: User analytics

## Step 8: Testing Deployment

### 8.1 Health Checks

Test the following endpoints:
- `https://your-domain.com/health` - Backend health
- `https://your-domain.com/` - Frontend application

### 8.2 Feature Testing

Test all major features:
- User authentication (OAuth)
- API key management
- Payment processing
- Real-time communication

## Troubleshooting

### Common Issues

1. **Build Failures**: Check build logs in Amplify console
2. **Environment Variables**: Ensure all required variables are set
3. **CORS Errors**: Verify `ALLOWED_ORIGINS` configuration
4. **Database Connection**: Check Supabase configuration
5. **Redis Connection**: Verify Redis host and port settings

### Debug Commands

```bash
# Check build logs
amplify console

# View application logs
amplify logs

# Test health endpoint
curl https://your-domain.com/health
```

## Security Considerations

1. **Environment Variables**: Never commit sensitive data to Git
2. **API Keys**: Use environment variables for all API keys
3. **CORS**: Restrict CORS origins to your domains only
4. **SSL**: Always use HTTPS in production
5. **Secrets Management**: Consider using AWS Secrets Manager for sensitive data

## Cost Optimization

1. **Amplify Pricing**: Understand Amplify pricing model
2. **Backend Optimization**: Monitor backend usage
3. **CDN**: Leverage Amplify's global CDN
4. **Caching**: Implement proper caching strategies

## Next Steps

After successful deployment:

1. Set up monitoring and alerting
2. Configure automated backups
3. Implement CI/CD pipeline improvements
4. Plan for scaling and performance optimization
5. Set up staging environment for testing

## Support

For issues with:
- **Amplify**: Check AWS Amplify documentation
- **Application**: Review logs and error messages
- **Configuration**: Verify environment variables and settings 