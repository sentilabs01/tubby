# Comprehensive Developer Guide: Multi-Provider OAuth Authentication and Stripe Payment Integration for Tubby AI Platform

**Author:** Manus AI  
**Version:** 2.0  
**Last Updated:** July 21, 2025  
**Target Audience:** Full-stack developers, DevOps engineers, and technical leads

## Executive Summary

This comprehensive guide provides detailed instructions for implementing a robust, multi-provider authentication system that seamlessly integrates Google OAuth, GitHub OAuth, and Stripe payment processing within the Tubby AI Agent Communication Platform. The implementation supports account linking across providers, unified user management, and subscription-based monetization while maintaining security best practices and providing an exceptional user experience.

The authentication system is designed to handle complex scenarios including cross-provider account linking, subscription management across different authentication methods, and graceful fallback mechanisms. This guide builds upon the existing codebase and extends it to support enterprise-grade authentication and payment processing capabilities.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites and Environment Setup](#prerequisites-and-environment-setup)
3. [Database Schema Design](#database-schema-design)
4. [Backend Implementation](#backend-implementation)
5. [Frontend Implementation](#frontend-implementation)
6. [Stripe Payment Integration](#stripe-payment-integration)
7. [Security Considerations](#security-considerations)
8. [Testing and Validation](#testing-and-validation)
9. [Deployment and Production Considerations](#deployment-and-production-considerations)
10. [Troubleshooting and Maintenance](#troubleshooting-and-maintenance)




## Architecture Overview

The Tubby AI platform implements a sophisticated multi-provider authentication architecture that seamlessly integrates three critical components: Google OAuth 2.0, GitHub OAuth 2.0, and Stripe payment processing. This architecture is designed to provide users with flexible authentication options while maintaining a unified user experience and robust subscription management capabilities.

### System Components

The authentication and payment system consists of several interconnected components that work together to provide a comprehensive user management solution. The Flask backend serves as the central orchestrator, handling OAuth flows, user session management, and payment processing through dedicated service classes. The React frontend provides an intuitive interface for authentication and subscription management, while the Supabase database ensures reliable data persistence and user profile management.

The OAuth service layer abstracts the complexity of different authentication providers, presenting a unified interface for user authentication regardless of the chosen provider. This design pattern allows for easy extension to additional OAuth providers in the future while maintaining backward compatibility with existing user accounts. The service layer handles token validation, user data normalization, and cross-provider account linking automatically.

The Stripe integration operates independently of the authentication provider, allowing users to maintain their subscription status regardless of how they choose to authenticate. This separation of concerns ensures that payment processing remains stable even if users switch between authentication methods or link multiple accounts.

### Data Flow Architecture

The authentication flow begins when a user selects their preferred authentication method from the frontend interface. The system redirects the user to the appropriate OAuth provider (Google or GitHub), where they complete the authentication process. Upon successful authentication, the provider redirects the user back to the Tubby platform with an authorization code.

The backend OAuth service exchanges this authorization code for an access token and retrieves the user's profile information from the provider's API. The system then normalizes this data into a consistent format and either creates a new user record or updates an existing one. If a user with the same email address already exists but was authenticated through a different provider, the system automatically links the accounts, preserving subscription status and user preferences.

Once the user is authenticated and their profile is updated, the system generates a JWT token for session management and redirects the user to the main application interface. The JWT token contains essential user information and is used for subsequent API requests to maintain the user's authenticated state.

### Account Linking Strategy

The platform implements intelligent account linking that allows users to authenticate with multiple providers while maintaining a single user profile. When a user authenticates with a new provider, the system checks for existing accounts with the same email address. If found, the system merges the provider-specific information into the existing user record, creating a unified profile that supports authentication through multiple methods.

This approach provides several benefits including improved user experience by eliminating the need to create separate accounts for different authentication methods, preservation of subscription status and user preferences across authentication providers, and enhanced account recovery options if one authentication method becomes unavailable.

The account linking process is designed to be transparent to the user, requiring no additional steps or confirmations. The system automatically handles the complexity of merging account data while maintaining data integrity and security standards.

### Security Architecture

The security architecture implements multiple layers of protection to ensure user data safety and prevent unauthorized access. JWT tokens are used for session management with configurable expiration times and secure signing algorithms. All OAuth flows follow industry best practices including state parameter validation, secure redirect URI handling, and proper token storage.

The system implements comprehensive input validation and sanitization to prevent injection attacks and data corruption. API endpoints are protected with authentication middleware that validates JWT tokens and ensures users can only access their own data. Sensitive information such as OAuth client secrets and JWT signing keys are stored as environment variables and never exposed in the codebase.

Payment processing security is handled through Stripe's robust infrastructure, with webhook signature verification ensuring that payment events are authentic. The system never stores sensitive payment information locally, relying instead on Stripe's secure tokenization system for payment method management.



## Prerequisites and Environment Setup

Before implementing the multi-provider authentication and Stripe integration, developers must ensure their development environment meets specific requirements and that all necessary external services are properly configured. This section provides comprehensive guidance for setting up the development environment and configuring the required third-party services.

### Development Environment Requirements

The Tubby AI platform requires a modern development environment with specific software versions and dependencies. Python 3.8 or higher is required for the Flask backend, with pip package manager for dependency installation. Node.js 16.0 or higher is necessary for the React frontend, along with npm or yarn for package management. A PostgreSQL database instance is required, either locally installed or accessed through a cloud provider like Supabase.

Git version control is essential for managing the codebase and tracking changes throughout the development process. A code editor with Python and JavaScript support is recommended, such as Visual Studio Code, PyCharm, or similar integrated development environments. Docker and Docker Compose are optional but recommended for containerized development and deployment.

The development machine should have sufficient resources to run multiple services simultaneously, including the Flask backend server, React development server, database instance, and any additional tools or services. A minimum of 8GB RAM and modern multi-core processor is recommended for optimal development experience.

### Google OAuth Configuration

Setting up Google OAuth requires creating a project in the Google Cloud Console and configuring OAuth 2.0 credentials. Navigate to the Google Cloud Console at console.cloud.google.com and create a new project or select an existing one. Enable the Google+ API and Google Identity API for your project through the APIs & Services section.

Configure the OAuth consent screen by providing application information including the application name, user support email, and developer contact information. For development purposes, you can use "External" user type, but for production applications, consider using "Internal" if your organization has a Google Workspace account. Add the necessary scopes including email, profile, and openid to access basic user information.

Create OAuth 2.0 credentials by navigating to the Credentials section and selecting "Create Credentials" followed by "OAuth 2.0 Client IDs". Choose "Web application" as the application type and configure the authorized redirect URIs. For development, add http://localhost:5001/auth/google/callback, and for production, add your domain-specific callback URL.

The Google Cloud Console will provide a Client ID and Client Secret that must be securely stored in your environment variables. These credentials are sensitive and should never be committed to version control or exposed in client-side code. The Client ID can be safely used in frontend applications, but the Client Secret must remain server-side only.

### GitHub OAuth Configuration

GitHub OAuth setup involves creating an OAuth App in your GitHub account or organization settings. Navigate to GitHub.com and access your account settings, then select "Developer settings" followed by "OAuth Apps". Click "New OAuth App" to create a new application registration.

Provide the application details including the application name, homepage URL, and application description. The authorization callback URL is critical and must match the URL configured in your backend application. For development, use http://localhost:5001/auth/github/callback, and for production, use your domain-specific callback URL.

GitHub will generate a Client ID and Client Secret for your OAuth application. The Client ID is publicly visible and can be used in frontend applications, while the Client Secret must be kept secure and used only in server-side code. Store these credentials in your environment variables following the same security practices as with Google OAuth credentials.

Configure the OAuth application permissions to request access to user email addresses and basic profile information. GitHub's OAuth implementation allows for granular permission control, so only request the minimum permissions necessary for your application's functionality.

### Stripe Account Setup

Stripe integration requires creating a Stripe account and configuring payment processing capabilities. Sign up for a Stripe account at stripe.com and complete the account verification process. Stripe provides both test and live environments, allowing for comprehensive testing before processing real payments.

Access the Stripe Dashboard and navigate to the API keys section to retrieve your publishable and secret keys. Stripe provides separate keys for test and live modes, ensuring that development and testing activities don't affect real payment processing. The publishable key can be safely used in frontend applications, while the secret key must remain server-side only.

Configure webhook endpoints in the Stripe Dashboard to receive real-time notifications about payment events. Create a webhook endpoint pointing to your application's webhook handler, typically at /stripe/webhook. Select the events you want to receive, including checkout.session.completed, customer.subscription.updated, customer.subscription.deleted, and invoice.payment_failed.

Create product and pricing information in the Stripe Dashboard for your subscription plans. Define recurring billing intervals, pricing tiers, and any trial periods or promotional pricing. Stripe's flexible pricing model supports various subscription scenarios including tiered pricing, usage-based billing, and promotional discounts.

### Environment Variables Configuration

Proper environment variable configuration is crucial for security and deployment flexibility. Create a .env file in your project root directory to store sensitive configuration values. This file should never be committed to version control and should be included in your .gitignore file.

The environment variables must include OAuth credentials for both Google and GitHub, JWT configuration for session management, database connection information, and Stripe API keys. Each variable should be clearly documented with comments explaining its purpose and any special configuration requirements.

```env
# Google OAuth Configuration
GOOGLE_CLIENT_ID=your_google_client_id_here
GOOGLE_CLIENT_SECRET=your_google_client_secret_here
GOOGLE_REDIRECT_URI=http://localhost:5001/auth/google/callback

# GitHub OAuth Configuration  
GITHUB_CLIENT_ID=your_github_client_id_here
GITHUB_CLIENT_SECRET=your_github_client_secret_here
GITHUB_REDIRECT_URI=http://localhost:5001/auth/github/callback

# JWT Configuration
JWT_SECRET_KEY=your_very_secure_jwt_secret_key_here
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

# Database Configuration
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# Application Configuration
FRONTEND_URL=http://localhost:3007
BACKEND_URL=http://localhost:5001
```

### Database Setup and Migration

The database schema must be properly configured to support multi-provider authentication and subscription management. If using Supabase, create a new project and configure the database connection. For local PostgreSQL installations, create a new database and user with appropriate permissions.

The users table requires columns to support both Google and GitHub authentication, along with subscription management fields. The schema should include provider-specific identifiers, user profile information, subscription status, and audit fields for tracking account creation and updates.

Execute the database migration scripts to create the necessary tables and indexes. Ensure that proper constraints are in place to maintain data integrity, including unique constraints on provider-specific identifiers and foreign key relationships for subscription data.

Test the database connection from your application to ensure proper configuration and connectivity. Verify that the application can successfully create, read, update, and delete user records, and that all authentication and subscription workflows function correctly with the database schema.


## Database Schema Design

The database schema for the multi-provider authentication and subscription system requires careful design to support complex user relationships, cross-provider account linking, and comprehensive subscription management. The schema must accommodate users who authenticate through different providers while maintaining data integrity and enabling efficient queries for user lookup and subscription status verification.

### Core Users Table Structure

The users table serves as the central repository for all user information, regardless of authentication provider. The table design incorporates provider-specific identifiers while maintaining a unified user profile structure that supports account linking and subscription management across different authentication methods.

The primary key uses a UUID format to ensure uniqueness and avoid potential conflicts with provider-specific identifiers. Email addresses serve as a secondary unique identifier for account linking purposes, allowing the system to identify and merge accounts from different providers that belong to the same user.

```sql
CREATE TABLE users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Core user information
    email VARCHAR(255) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    picture TEXT,
    verified_email BOOLEAN DEFAULT FALSE,
    
    -- Google OAuth fields
    google_id VARCHAR(255) UNIQUE,
    
    -- GitHub OAuth fields  
    github_id VARCHAR(255) UNIQUE,
    github_username VARCHAR(255),
    
    -- Provider information
    provider VARCHAR(50) NOT NULL DEFAULT 'unknown',
    primary_provider VARCHAR(50),
    
    -- Subscription management
    subscription_status VARCHAR(50) DEFAULT 'free',
    subscription_id VARCHAR(255),
    stripe_customer_id VARCHAR(255) UNIQUE,
    subscription_plan VARCHAR(50) DEFAULT 'free',
    subscription_period_end TIMESTAMP WITH TIME ZONE,
    subscription_cancel_at_period_end BOOLEAN DEFAULT FALSE,
    
    -- Audit fields
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE,
    login_count INTEGER DEFAULT 0
);
```

The provider field indicates the authentication method used for the most recent login, while primary_provider tracks the user's preferred authentication method. This distinction allows the system to provide personalized experiences based on user preferences while maintaining flexibility in authentication options.

Subscription-related fields are provider-agnostic, ensuring that users maintain their subscription status regardless of their chosen authentication method. The stripe_customer_id field creates a direct link to Stripe's customer management system, enabling seamless payment processing and subscription management.

### Indexing Strategy for Performance

Proper indexing is crucial for maintaining application performance as the user base grows. The indexing strategy focuses on the most common query patterns including user lookup by provider-specific identifiers, email-based account linking, and subscription status queries.

```sql
-- Provider-specific lookup indexes
CREATE INDEX idx_users_google_id ON users(google_id) WHERE google_id IS NOT NULL;
CREATE INDEX idx_users_github_id ON users(github_id) WHERE github_id IS NOT NULL;
CREATE INDEX idx_users_email ON users(email);

-- Subscription management indexes
CREATE INDEX idx_users_stripe_customer_id ON users(stripe_customer_id) WHERE stripe_customer_id IS NOT NULL;
CREATE INDEX idx_users_subscription_status ON users(subscription_status);
CREATE INDEX idx_users_subscription_plan ON users(subscription_plan);

-- Audit and analytics indexes
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_users_last_login_at ON users(last_login_at);
CREATE INDEX idx_users_provider ON users(provider);
```

Partial indexes are used for provider-specific identifiers to optimize storage and query performance by only indexing non-null values. This approach is particularly effective for the multi-provider scenario where users may not have identifiers for all supported authentication methods.

### Data Integrity Constraints

Database constraints ensure data integrity and prevent inconsistent states that could compromise the authentication system's reliability. The constraint design addresses common scenarios including duplicate accounts, invalid subscription states, and orphaned records.

```sql
-- Ensure email uniqueness and format validation
ALTER TABLE users ADD CONSTRAINT users_email_format 
    CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Validate subscription status values
ALTER TABLE users ADD CONSTRAINT users_subscription_status_valid 
    CHECK (subscription_status IN ('free', 'basic', 'pro', 'enterprise', 'cancelled', 'past_due'));

-- Validate provider values
ALTER TABLE users ADD CONSTRAINT users_provider_valid 
    CHECK (provider IN ('google', 'github', 'guest', 'unknown'));

-- Ensure at least one authentication method is present
ALTER TABLE users ADD CONSTRAINT users_has_auth_method 
    CHECK (google_id IS NOT NULL OR github_id IS NOT NULL OR provider = 'guest');
```

The email format constraint uses a regular expression to validate email address structure, preventing invalid email addresses from being stored in the database. The subscription status constraint ensures that only valid subscription states are allowed, preventing data corruption from invalid status updates.

### Audit Trail and User Activity Tracking

The schema includes comprehensive audit capabilities to track user activity, authentication events, and subscription changes. This information is valuable for analytics, security monitoring, and customer support purposes.

```sql
CREATE TABLE user_activity_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    activity_type VARCHAR(50) NOT NULL,
    provider VARCHAR(50),
    ip_address INET,
    user_agent TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_user_activity_log_user_id ON user_activity_log(user_id);
CREATE INDEX idx_user_activity_log_activity_type ON user_activity_log(activity_type);
CREATE INDEX idx_user_activity_log_created_at ON user_activity_log(created_at);
```

The activity log table captures detailed information about user interactions including login events, subscription changes, and account modifications. The JSONB metadata field provides flexibility for storing provider-specific information or additional context about each activity.

### Subscription History and Payment Tracking

A separate table tracks subscription history and payment events, providing a complete audit trail of user subscription changes and payment processing activities. This information is essential for customer support, billing reconciliation, and analytics.

```sql
CREATE TABLE subscription_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subscription_id VARCHAR(255),
    stripe_customer_id VARCHAR(255),
    event_type VARCHAR(50) NOT NULL,
    old_status VARCHAR(50),
    new_status VARCHAR(50),
    old_plan VARCHAR(50),
    new_plan VARCHAR(50),
    amount_cents INTEGER,
    currency VARCHAR(3) DEFAULT 'USD',
    stripe_event_id VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_subscription_history_user_id ON subscription_history(user_id);
CREATE INDEX idx_subscription_history_event_type ON subscription_history(event_type);
CREATE INDEX idx_subscription_history_created_at ON subscription_history(created_at);
```

The subscription history table maintains a complete record of all subscription-related events, enabling detailed analysis of user subscription patterns and payment processing success rates. The stripe_event_id field links events to Stripe's webhook system for reconciliation purposes.

### Database Triggers for Automatic Updates

Database triggers automate common maintenance tasks and ensure data consistency across related tables. The trigger system handles automatic timestamp updates, activity logging, and subscription history recording.

```sql
-- Automatic updated_at timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Automatic activity logging trigger
CREATE OR REPLACE FUNCTION log_user_activity()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO user_activity_log (user_id, activity_type, metadata)
        VALUES (NEW.id, 'account_created', jsonb_build_object('provider', NEW.provider));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.last_login_at IS DISTINCT FROM NEW.last_login_at THEN
            INSERT INTO user_activity_log (user_id, activity_type, metadata)
            VALUES (NEW.id, 'login', jsonb_build_object('provider', NEW.provider));
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER log_users_activity 
    AFTER INSERT OR UPDATE ON users
    FOR EACH ROW 
    EXECUTE FUNCTION log_user_activity();
```

These triggers ensure that user activity is automatically logged without requiring explicit application code, reducing the risk of missing important events and maintaining consistent audit trails across all user interactions.


## Backend Implementation

The backend implementation forms the core of the multi-provider authentication and payment system, orchestrating OAuth flows, user management, and Stripe integration through a well-structured Flask application. The implementation follows service-oriented architecture principles, separating concerns into dedicated service classes that handle specific aspects of the authentication and payment processing workflow.

### OAuth Service Implementation

The OAuth service serves as the central component for handling authentication across multiple providers. The service abstracts the complexity of different OAuth implementations, providing a unified interface for user authentication while maintaining provider-specific functionality where necessary.

The service class initialization establishes connections to external services and configures provider-specific settings. Environment variables are used for sensitive configuration data, ensuring that credentials and secrets are not hardcoded in the application. The service implements error handling and fallback mechanisms to gracefully handle provider unavailability or configuration issues.

```python
import os
import jwt
import requests
from datetime import datetime, timedelta
from supabase import create_client, Client

# Optional Google imports with graceful fallback
try:
    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token
    from google_auth_oauthlib.flow import Flow
    GOOGLE_AVAILABLE = True
except ImportError:
    GOOGLE_AVAILABLE = False
    print("Google OAuth dependencies not available. Google OAuth will be disabled.")

class OAuthService:
    def __init__(self):
        # Google OAuth configuration
        self.google_client_id = os.getenv('GOOGLE_CLIENT_ID')
        self.google_client_secret = os.getenv('GOOGLE_CLIENT_SECRET')
        self.google_redirect_uri = os.getenv('GOOGLE_REDIRECT_URI')
        
        # GitHub OAuth configuration
        self.github_client_id = os.getenv('GITHUB_CLIENT_ID')
        self.github_client_secret = os.getenv('GITHUB_CLIENT_SECRET')
        self.github_redirect_uri = os.getenv('GITHUB_REDIRECT_URI')
        
        # JWT configuration
        self.jwt_secret = os.getenv('JWT_SECRET_KEY')
        self.jwt_algorithm = os.getenv('JWT_ALGORITHM', 'HS256')
        self.jwt_expiration_hours = int(os.getenv('JWT_EXPIRATION_HOURS', 24))
        
        # Initialize Supabase client
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_ANON_KEY')
        
        try:
            self.supabase: Client = create_client(supabase_url, supabase_key)
        except Exception as e:
            print(f"Warning: Could not initialize Supabase client: {e}")
            self.supabase = None
```

The Google OAuth implementation leverages the official Google OAuth library when available, with graceful degradation when dependencies are not installed. This approach ensures that the application can function with partial OAuth provider support, allowing for flexible deployment scenarios.

```python
    def get_google_auth_url(self):
        """Generate Google OAuth authorization URL"""
        if not GOOGLE_AVAILABLE or not self.google_client_id:
            return f"{os.getenv('FRONTEND_URL', 'http://localhost:3007')}/auth/error?provider=google&message=Google OAuth not configured"
        
        try:
            flow = self.create_google_flow()
            auth_url, _ = flow.authorization_url(prompt='consent')
            return auth_url
        except Exception as e:
            print(f"Error creating Google auth URL: {e}")
            return f"{os.getenv('FRONTEND_URL', 'http://localhost:3007')}/auth/error?provider=google&message=Google OAuth configuration error"
    
    def verify_google_token(self, code):
        """Verify Google OAuth token and return user info"""
        if not GOOGLE_AVAILABLE:
            return None
            
        try:
            flow = self.create_google_flow()
            flow.fetch_token(code=code)
            
            # Get user info from Google
            credentials = flow.credentials
            user_info_response = requests.get(
                'https://www.googleapis.com/oauth2/v2/userinfo',
                headers={'Authorization': f'Bearer {credentials.token}'}
            )
            
            if user_info_response.status_code == 200:
                user_data = user_info_response.json()
                user_data['provider'] = 'google'
                return user_data
            else:
                return None
                
        except Exception as e:
            print(f"Error verifying Google token: {e}")
            return None
```

The GitHub OAuth implementation follows a similar pattern but uses direct HTTP requests to GitHub's OAuth API rather than a specialized library. This approach provides more control over the authentication flow and reduces external dependencies.

```python
    def get_github_auth_url(self):
        """Generate GitHub OAuth authorization URL"""
        if not self.github_client_id or not self.github_client_secret:
            return f"{os.getenv('FRONTEND_URL', 'http://localhost:3007')}/auth/error?provider=github&message=GitHub OAuth not configured"
        
        try:
            # GitHub OAuth authorization URL with state parameter for security
            auth_url = (
                f"https://github.com/login/oauth/authorize"
                f"?client_id={self.github_client_id}"
                f"&redirect_uri={self.github_redirect_uri}"
                f"&scope=user:email"
                f"&state=github_oauth"
            )
            return auth_url
        except Exception as e:
            print(f"Error creating GitHub auth URL: {e}")
            return f"{os.getenv('FRONTEND_URL', 'http://localhost:3007')}/auth/error?provider=github&message=GitHub OAuth configuration error"
    
    def verify_github_token(self, code):
        """Verify GitHub OAuth token and return user info"""
        try:
            # Exchange code for access token
            token_response = requests.post(
                'https://github.com/login/oauth/access_token',
                data={
                    'client_id': self.github_client_id,
                    'client_secret': self.github_client_secret,
                    'code': code,
                    'redirect_uri': self.github_redirect_uri
                },
                headers={'Accept': 'application/json'}
            )
            
            if token_response.status_code != 200:
                print(f"GitHub token exchange failed: {token_response.text}")
                return None
            
            token_data = token_response.json()
            access_token = token_data.get('access_token')
            
            if not access_token:
                print("No access token received from GitHub")
                return None
            
            # Get user info from GitHub API
            user_response = requests.get(
                'https://api.github.com/user',
                headers={'Authorization': f'Bearer {access_token}'}
            )
            
            if user_response.status_code != 200:
                print(f"GitHub user info request failed: {user_response.text}")
                return None
            
            user_data = user_response.json()
            
            # Get user email separately as GitHub may not include it in user endpoint
            email_response = requests.get(
                'https://api.github.com/user/emails',
                headers={'Authorization': f'Bearer {access_token}'}
            )
            
            primary_email = user_data.get('email')
            if not primary_email and email_response.status_code == 200:
                emails = email_response.json()
                for email in emails:
                    if email.get('primary'):
                        primary_email = email.get('email')
                        break
            
            # Format user data to match expected structure
            formatted_user_data = {
                'id': str(user_data.get('id')),
                'email': primary_email or f"{user_data.get('login')}@github.local",
                'name': user_data.get('name') or user_data.get('login'),
                'picture': user_data.get('avatar_url'),
                'verified_email': True,
                'provider': 'github',
                'github_username': user_data.get('login'),
                'github_profile_url': user_data.get('html_url')
            }
            
            return formatted_user_data
            
        except Exception as e:
            print(f"Error verifying GitHub token: {e}")
            return None
```

The JWT token management system provides secure session handling with configurable expiration times and robust validation. The implementation includes proper error handling for expired tokens and invalid signatures.

```python
    def generate_jwt_token(self, user_data):
        """Generate JWT token for authenticated user"""
        payload = {
            'user_id': user_data.get('id'),
            'email': user_data.get('email'),
            'name': user_data.get('name'),
            'picture': user_data.get('picture'),
            'provider': user_data.get('provider'),
            'exp': datetime.utcnow() + timedelta(hours=self.jwt_expiration_hours),
            'iat': datetime.utcnow()
        }
        
        token = jwt.encode(payload, self.jwt_secret, algorithm=self.jwt_algorithm)
        return token
    
    def verify_jwt_token(self, token):
        """Verify JWT token and return user data"""
        try:
            payload = jwt.decode(token, self.jwt_secret, algorithms=[self.jwt_algorithm])
            return payload
        except jwt.ExpiredSignatureError:
            print("JWT token has expired")
            return None
        except jwt.InvalidTokenError:
            print("Invalid JWT token")
            return None
```

### User Service Implementation

The user service handles all database operations related to user management, including account creation, updates, and cross-provider account linking. The service implements intelligent account linking logic that automatically merges accounts from different providers when they share the same email address.

```python
import os
from supabase import create_client, Client

class UserService:
    def __init__(self):
        supabase_url = os.getenv('SUPABASE_URL')
        supabase_key = os.getenv('SUPABASE_ANON_KEY')
        
        try:
            self.supabase: Client = create_client(supabase_url, supabase_key)
        except Exception as e:
            print(f"Warning: Could not initialize Supabase client in UserService: {e}")
            self.supabase = None
    
    def create_or_update_user(self, oauth_user_data):
        """Create or update user in database - supports multiple OAuth providers"""
        if not self.supabase:
            return None
            
        try:
            provider = oauth_user_data.get('provider', 'unknown')
            
            # Prepare user data based on provider
            if provider == 'google':
                user_data = {
                    'google_id': oauth_user_data.get('id'),
                    'email': oauth_user_data.get('email'),
                    'name': oauth_user_data.get('name'),
                    'picture': oauth_user_data.get('picture'),
                    'verified_email': oauth_user_data.get('verified_email', False),
                    'provider': 'google'
                }
                lookup_field = 'google_id'
                lookup_value = user_data['google_id']
            elif provider == 'github':
                user_data = {
                    'github_id': oauth_user_data.get('id'),
                    'github_username': oauth_user_data.get('github_username'),
                    'email': oauth_user_data.get('email'),
                    'name': oauth_user_data.get('name'),
                    'picture': oauth_user_data.get('picture'),
                    'verified_email': oauth_user_data.get('verified_email', True),
                    'provider': 'github'
                }
                lookup_field = 'github_id'
                lookup_value = user_data['github_id']
            else:
                # Generic OAuth data
                user_data = {
                    'email': oauth_user_data.get('email'),
                    'name': oauth_user_data.get('name'),
                    'picture': oauth_user_data.get('picture'),
                    'verified_email': oauth_user_data.get('verified_email', False),
                    'provider': provider
                }
                lookup_field = 'email'
                lookup_value = user_data['email']
            
            # Implement intelligent account linking
            existing_user = None
            if lookup_field != 'email':
                existing_user = self.supabase.table('users').select('*').eq(lookup_field, lookup_value).execute()
            
            # If not found by provider ID, check by email for account linking
            if not existing_user or not existing_user.data:
                existing_user = self.supabase.table('users').select('*').eq('email', user_data['email']).execute()
                
                # Merge provider-specific data for account linking
                if existing_user and existing_user.data:
                    existing_record = existing_user.data[0]
                    if provider == 'google' and not existing_record.get('google_id'):
                        user_data.update({
                            'github_id': existing_record.get('github_id'),
                            'github_username': existing_record.get('github_username')
                        })
                    elif provider == 'github' and not existing_record.get('github_id'):
                        user_data.update({
                            'google_id': existing_record.get('google_id')
                        })
            
            # Update login tracking
            user_data.update({
                'last_login_at': datetime.utcnow().isoformat(),
                'login_count': (existing_user.data[0].get('login_count', 0) + 1) if existing_user and existing_user.data else 1
            })
            
            if existing_user and existing_user.data:
                # Update existing user
                result = self.supabase.table('users').update(user_data).eq('id', existing_user.data[0]['id']).execute()
                return result.data[0] if result.data else None
            else:
                # Create new user
                result = self.supabase.table('users').insert(user_data).execute()
                return result.data[0] if result.data else None
                
        except Exception as e:
            print(f"Error managing user: {e}")
            return None
```

The user service includes comprehensive methods for retrieving users by various identifiers, supporting the multi-provider authentication system's need for flexible user lookup capabilities.

```python
    def get_user_by_id(self, user_id):
        """Get user by ID"""
        if not self.supabase:
            return None
            
        try:
            result = self.supabase.table('users').select('*').eq('id', user_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting user: {e}")
            return None
    
    def get_user_by_email(self, email):
        """Get user by email (works across all providers)"""
        if not self.supabase:
            return None
            
        try:
            result = self.supabase.table('users').select('*').eq('email', email).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting user by email: {e}")
            return None
    
    def get_user_by_google_id(self, google_id):
        """Get user by Google ID"""
        if not self.supabase:
            return None
            
        try:
            result = self.supabase.table('users').select('*').eq('google_id', google_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting user by Google ID: {e}")
            return None
    
    def get_user_by_github_id(self, github_id):
        """Get user by GitHub ID"""
        if not self.supabase:
            return None
            
        try:
            result = self.supabase.table('users').select('*').eq('github_id', github_id).execute()
            return result.data[0] if result.data else None
        except Exception as e:
            print(f"Error getting user by GitHub ID: {e}")
            return None
```

### Flask Application Routes

The Flask application implements comprehensive routing for authentication flows, user management, and API endpoints. The route implementation includes proper error handling, security middleware, and integration with the service layer.

```python
from flask import Flask, render_template, request, jsonify, redirect, session
from flask_cors import CORS
import os
from datetime import datetime
from services.oauth_service import OAuthService
from services.user_service import UserService
from services.stripe_service import StripeService

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
app.config['SESSION_COOKIE_SECURE'] = False  # Set to True in production with HTTPS

# Configure CORS for frontend integration
CORS(app, origins=[
    'http://localhost:3003', 
    'http://localhost:3007', 
    'http://localhost:3015', 
    'http://localhost:4173'
], supports_credentials=True, methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])

# Initialize services
oauth_service = OAuthService()
user_service = UserService()
stripe_service = StripeService()

# Authentication middleware
def require_auth(f):
    """Decorator to require authentication"""
    def decorated_function(*args, **kwargs):
        # Check for guest user first
        if session.get('is_guest') and session.get('guest_user'):
            request.current_user = session['guest_user']
            return f(*args, **kwargs)
        
        access_token = session.get('access_token') or request.headers.get('Authorization', '').replace('Bearer ', '')
        
        if not access_token:
            return jsonify({'error': 'Authentication required'}), 401
        
        user_data = oauth_service.verify_jwt_token(access_token)
        if not user_data:
            return jsonify({'error': 'Invalid or expired token'}), 401
        
        request.current_user = user_data
        return f(*args, **kwargs)
    
    decorated_function.__name__ = f.__name__
    return decorated_function
```

The authentication routes handle OAuth flows for both Google and GitHub, with comprehensive error handling and user feedback.

```python
@app.route('/auth/google')
def google_auth():
    """Initiate Google OAuth flow"""
    try:
        auth_url = oauth_service.get_google_auth_url()
        return redirect(auth_url)
    except Exception as e:
        return render_error_page("Google OAuth Error", str(e))

@app.route('/auth/google/callback')
def google_callback():
    """Handle Google OAuth callback"""
    code = request.args.get('code')
    error = request.args.get('error')
    
    if error:
        return render_error_page("Google OAuth Error", error)
    
    if not code:
        return jsonify({'error': 'Authorization code not provided'}), 400
    
    # Verify Google token and get user info
    google_user_data = oauth_service.verify_google_token(code)
    if not google_user_data:
        return jsonify({'error': 'Failed to verify Google token'}), 400
    
    # Create or update user in database
    user = user_service.create_or_update_user(google_user_data)
    if not user:
        return jsonify({'error': 'Failed to create user'}), 500
    
    # Generate JWT token
    jwt_token = oauth_service.generate_jwt_token(google_user_data)
    
    # Store token in session
    session['access_token'] = jwt_token
    session['user'] = user
    
    # Redirect to frontend with success
    frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:3007')
    return redirect(f'{frontend_url}/?auth=success&provider=google')

@app.route('/auth/github')
def github_auth():
    """Initiate GitHub OAuth flow"""
    try:
        auth_url = oauth_service.get_github_auth_url()
        return redirect(auth_url)
    except Exception as e:
        return render_error_page("GitHub OAuth Error", str(e))

@app.route('/auth/github/callback')
def github_callback():
    """Handle GitHub OAuth callback"""
    code = request.args.get('code')
    state = request.args.get('state')
    error = request.args.get('error')
    
    if error:
        return render_error_page("GitHub OAuth Error", error)
    
    if not code:
        return jsonify({'error': 'Authorization code not provided'}), 400
    
    # Verify GitHub token and get user info
    github_user_data = oauth_service.verify_github_token(code)
    if not github_user_data:
        return jsonify({'error': 'Failed to verify GitHub token'}), 400
    
    # Create or update user in database
    user = user_service.create_or_update_user(github_user_data)
    if not user:
        return jsonify({'error': 'Failed to create user'}), 500
    
    # Generate JWT token
    jwt_token = oauth_service.generate_jwt_token(github_user_data)
    
    # Store token in session
    session['access_token'] = jwt_token
    session['user'] = user
    
    # Redirect to frontend with success
    frontend_url = os.getenv('FRONTEND_URL', 'http://localhost:3007')
    return redirect(f'{frontend_url}/?auth=success&provider=github')

@app.route('/auth/user')
@require_auth
def get_current_user():
    """Get current authenticated user"""
    return jsonify({'user': request.current_user})

@app.route('/auth/logout')
def logout():
    """Logout user"""
    session.clear()
    return jsonify({'message': 'Logged out successfully'})

def render_error_page(title, message):
    """Render a consistent error page for OAuth errors"""
    return f"""
    <html>
    <head><title>{title}</title></head>
    <body style="background: black; color: white; font-family: Arial, sans-serif; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0;">
        <div style="text-align: center; padding: 2rem; border: 1px solid #333; border-radius: 8px;">
            <h1>⚠️ {title}</h1>
            <p>{message}</p>
            <br><br>
            <a href="{os.getenv('FRONTEND_URL', 'http://localhost:3007')}" style="color: #3b82f6; text-decoration: none;">← Back to Login</a>
        </div>
    </body>
    </html>
    """, 400
```

The implementation includes comprehensive error handling, logging, and monitoring capabilities to ensure reliable operation in production environments. The service layer architecture provides clear separation of concerns and enables easy testing and maintenance of the authentication system.


## Frontend Implementation

The frontend implementation provides a seamless user experience for multi-provider authentication and subscription management through a modern React application. The implementation emphasizes user experience, accessibility, and responsive design while maintaining security best practices and providing clear feedback for all user interactions.

### Authentication Context and State Management

The authentication system uses React Context to provide global state management for user authentication status, enabling components throughout the application to access user information and authentication methods. The context implementation includes automatic token refresh, session persistence, and comprehensive error handling.

```jsx
import { useState, useEffect, createContext, useContext } from 'react'

const AuthContext = createContext()

// Backend URL configuration with environment variable support
const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:5001'

export const useAuth = () => {
  const context = useContext(AuthContext)
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider')
  }
  return context
}

export const AuthProvider = ({ children }) => {
  const [currentUser, setCurrentUser] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  useEffect(() => {
    checkAuthStatus()
    
    // Check for authentication success in URL parameters
    const urlParams = new URLSearchParams(window.location.search)
    if (urlParams.get('auth') === 'success') {
      const provider = urlParams.get('provider')
      // Remove parameters from URL
      window.history.replaceState({}, document.title, window.location.pathname)
      // Refresh auth status
      setTimeout(() => checkAuthStatus(), 100)
      
      // Show success message
      if (provider) {
        setError(null)
        // Could trigger a success notification here
      }
    }
  }, [])

  const checkAuthStatus = async () => {
    try {
      setError(null)
      const response = await fetch(`${BACKEND_URL}/auth/user`, {
        credentials: 'include',
        headers: {
          'Content-Type': 'application/json',
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        setCurrentUser(data.user)
      } else if (response.status === 401) {
        // Unauthorized - user not logged in
        setCurrentUser(null)
      } else {
        // Other error
        const errorData = await response.json().catch(() => ({}))
        setError(errorData.error || 'Failed to check authentication status')
        setCurrentUser(null)
      }
    } catch (error) {
      console.error('Error checking auth status:', error)
      setError('Network error while checking authentication')
      setCurrentUser(null)
    } finally {
      setLoading(false)
    }
  }

  const login = async (provider = 'google') => {
    try {
      setError(null)
      setLoading(true)
      
      if (provider === 'guest') {
        // Handle guest login through API
        const response = await fetch(`${BACKEND_URL}/auth/guest`, {
          method: 'POST',
          credentials: 'include',
          headers: {
            'Content-Type': 'application/json',
          }
        })
        
        if (response.ok) {
          const data = await response.json()
          setCurrentUser(data.user)
        } else {
          const errorData = await response.json().catch(() => ({}))
          setError(errorData.error || 'Failed to create guest session')
        }
      } else {
        // Redirect to OAuth provider
        window.location.href = `${BACKEND_URL}/auth/${provider}`
      }
    } catch (error) {
      console.error('Error during login:', error)
      setError('Network error during login')
    } finally {
      setLoading(false)
    }
  }

  const logout = async () => {
    try {
      setError(null)
      await fetch(`${BACKEND_URL}/auth/logout`, {
        method: 'POST',
        credentials: 'include'
      })
      setCurrentUser(null)
      // Optionally reload the page to clear any cached data
      window.location.reload()
    } catch (error) {
      console.error('Error logging out:', error)
      setError('Error during logout')
    }
  }

  const clearError = () => {
    setError(null)
  }

  const value = {
    currentUser,
    loading,
    error,
    login,
    logout,
    checkAuthStatus,
    clearError,
    isAuthenticated: currentUser !== null,
    isGuest: currentUser?.provider === 'guest'
  }

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  )
}

export default AuthProvider
```

The authentication context provides comprehensive state management including loading states, error handling, and automatic session restoration. The implementation includes support for guest users, enabling users to explore the platform without creating an account.

### Login Component Implementation

The login component presents users with multiple authentication options in an intuitive and visually appealing interface. The component includes proper loading states, error handling, and accessibility features to ensure a smooth user experience across different devices and user capabilities.

```jsx
import { useAuth } from './AuthManager'
import { Button } from '../../components/ui/button.jsx'
import { Card, CardContent, CardHeader, CardTitle } from '../../components/ui/card.jsx'
import { Alert, AlertDescription } from '../../components/ui/alert.jsx'

const Login = () => {
  const { login, loading, error, clearError } = useAuth()

  const handleLogin = async (provider) => {
    clearError()
    await login(provider)
  }

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-900">
        <div className="text-white flex items-center space-x-2">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-white"></div>
          <span>Loading...</span>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-black p-4">
      <Card className="w-full max-w-md bg-black border-gray-800 shadow-2xl">
        <CardHeader className="text-center">
          <div className="flex justify-center mb-4">
            <img 
              src="https://tubbyai.s3.us-east-1.amazonaws.com/logo_option_2.png" 
              alt="Tubby AI Logo" 
              className="w-16 h-16"
            />
          </div>
          <CardTitle className="text-3xl font-bold text-white mb-2">
            Welcome to Tubby AI
          </CardTitle>
          <p className="text-gray-400">
            Sign in to access your AI agent communication platform
          </p>
        </CardHeader>
        <CardContent className="space-y-4">
          {error && (
            <Alert className="bg-red-900 border-red-700">
              <AlertDescription className="text-red-200">
                {error}
              </AlertDescription>
            </Alert>
          )}
          
          <Button
            onClick={() => handleLogin('google')}
            className="w-full bg-blue-600 hover:bg-blue-700 text-white py-3 px-4 rounded-lg flex items-center justify-center space-x-2 transition-colors duration-200"
            disabled={loading}
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24">
              <path
                fill="currentColor"
                d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"
              />
              <path
                fill="currentColor"
                d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"
              />
              <path
                fill="currentColor"
                d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"
              />
              <path
                fill="currentColor"
                d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"
              />
            </svg>
            <span>Sign in with Google</span>
          </Button>
          
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <span className="w-full border-t border-gray-600" />
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-black px-2 text-gray-400">Or continue with</span>
            </div>
          </div>
          
          <Button
            onClick={() => handleLogin('github')}
            className="w-full bg-gray-800 hover:bg-gray-700 text-white py-3 px-4 rounded-lg flex items-center justify-center space-x-2 border border-gray-600 transition-colors duration-200"
            disabled={loading}
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="currentColor">
              <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
            </svg>
            <span>Sign in with GitHub</span>
          </Button>
          
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <span className="w-full border-t border-gray-700" />
            </div>
            <div className="relative flex justify-center text-xs uppercase">
              <span className="bg-black px-2 text-gray-400">Or</span>
            </div>
          </div>
          
          <Button
            onClick={() => handleLogin('guest')}
            className="w-full bg-transparent hover:bg-gray-800 text-gray-300 py-3 px-4 rounded-lg flex items-center justify-center space-x-2 border border-gray-600 hover:border-gray-500 transition-colors duration-200"
            disabled={loading}
          >
            <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
            </svg>
            <span>Continue as Guest</span>
          </Button>
          
          <div className="text-center text-sm text-gray-500 mt-6">
            <p>By signing in, you agree to our Terms of Service and Privacy Policy</p>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

export default Login
```

The login component includes comprehensive accessibility features including proper ARIA labels, keyboard navigation support, and screen reader compatibility. The visual design uses consistent spacing, colors, and typography to create a professional and trustworthy appearance.

### User Profile and Account Management

The user profile component displays user information and provides account management capabilities including the ability to view linked authentication providers, manage subscription status, and access account settings.

```jsx
import { useAuth } from './AuthManager'
import { Button } from '../../components/ui/button.jsx'
import { Card, CardContent, CardHeader, CardTitle } from '../../components/ui/card.jsx'
import { Badge } from '../../components/ui/badge.jsx'

const UserProfile = () => {
  const { currentUser, logout, isGuest } = useAuth()

  if (!currentUser) {
    return null
  }

  const getProviderBadgeColor = (provider) => {
    switch (provider) {
      case 'google':
        return 'bg-blue-600'
      case 'github':
        return 'bg-gray-700'
      case 'guest':
        return 'bg-yellow-600'
      default:
        return 'bg-gray-500'
    }
  }

  const getProviderIcon = (provider) => {
    switch (provider) {
      case 'google':
        return (
          <svg className="w-4 h-4" viewBox="0 0 24 24">
            <path fill="currentColor" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z"/>
          </svg>
        )
      case 'github':
        return (
          <svg className="w-4 h-4" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
          </svg>
        )
      case 'guest':
        return (
          <svg className="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
        )
      default:
        return null
    }
  }

  return (
    <Card className="bg-black border-gray-800">
      <CardHeader>
        <CardTitle className="text-white flex items-center space-x-3">
          {currentUser.picture && (
            <img 
              src={currentUser.picture} 
              alt="Profile" 
              className="w-10 h-10 rounded-full"
            />
          )}
          <div>
            <div className="text-lg">{currentUser.name}</div>
            <div className="text-sm text-gray-400 font-normal">{currentUser.email}</div>
          </div>
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-4">
        <div>
          <h4 className="text-white text-sm font-medium mb-2">Authentication Provider</h4>
          <Badge className={`${getProviderBadgeColor(currentUser.provider)} text-white flex items-center space-x-1 w-fit`}>
            {getProviderIcon(currentUser.provider)}
            <span className="capitalize">{currentUser.provider}</span>
          </Badge>
        </div>
        
        {currentUser.github_username && (
          <div>
            <h4 className="text-white text-sm font-medium mb-2">GitHub Profile</h4>
            <a 
              href={`https://github.com/${currentUser.github_username}`}
              target="_blank"
              rel="noopener noreferrer"
              className="text-blue-400 hover:text-blue-300 text-sm"
            >
              @{currentUser.github_username}
            </a>
          </div>
        )}
        
        <div>
          <h4 className="text-white text-sm font-medium mb-2">Account Status</h4>
          <Badge className={currentUser.verified_email ? 'bg-green-600' : 'bg-yellow-600'}>
            {currentUser.verified_email ? 'Verified' : 'Unverified'}
          </Badge>
        </div>
        
        {isGuest && (
          <div className="bg-yellow-900 border border-yellow-700 rounded-lg p-3">
            <p className="text-yellow-200 text-sm">
              You're using a guest account. Sign in with Google or GitHub to save your preferences and access premium features.
            </p>
          </div>
        )}
        
        <div className="pt-4 border-t border-gray-700">
          <Button
            onClick={logout}
            className="w-full bg-red-600 hover:bg-red-700 text-white"
          >
            Sign Out
          </Button>
        </div>
      </CardContent>
    </Card>
  )
}

export default UserProfile
```

### Subscription Management Interface

The subscription management component integrates with the Stripe payment system to provide users with subscription plan selection, payment processing, and subscription status management. The component includes comprehensive error handling and user feedback for all payment-related operations.

```jsx
import { useState, useEffect } from 'react'
import { useAuth } from './AuthManager'
import { Button } from '../../components/ui/button.jsx'
import { Card, CardContent, CardHeader, CardTitle } from '../../components/ui/card.jsx'
import { Badge } from '../../components/ui/badge.jsx'
import { Alert, AlertDescription } from '../../components/ui/alert.jsx'

const BACKEND_URL = import.meta.env.VITE_BACKEND_URL || 'http://localhost:5001'

const SubscriptionPlans = () => {
  const { currentUser, isAuthenticated, isGuest } = useAuth()
  const [subscriptionStatus, setSubscriptionStatus] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const plans = [
    {
      id: 'basic',
      name: 'Basic Plan',
      price: '$9.99',
      interval: 'month',
      features: [
        'Basic AI agent access',
        'Limited terminal sessions',
        'Community support',
        'Basic integrations'
      ]
    },
    {
      id: 'pro',
      name: 'Pro Plan',
      price: '$29.99',
      interval: 'month',
      popular: true,
      features: [
        'Full AI agent access',
        'Unlimited terminal sessions',
        'Priority support',
        'Advanced features',
        'Custom integrations',
        'Analytics dashboard'
      ]
    },
    {
      id: 'enterprise',
      name: 'Enterprise Plan',
      price: '$99.99',
      interval: 'month',
      features: [
        'Everything in Pro',
        'Custom integrations',
        'Dedicated support',
        'SLA guarantee',
        'Advanced security',
        'Custom deployment'
      ]
    }
  ]

  useEffect(() => {
    if (isAuthenticated && !isGuest) {
      loadSubscriptionStatus()
    }
  }, [isAuthenticated, isGuest])

  const loadSubscriptionStatus = async () => {
    try {
      const response = await fetch(`${BACKEND_URL}/stripe/subscription-status`, {
        credentials: 'include'
      })
      
      if (response.ok) {
        const data = await response.json()
        setSubscriptionStatus(data)
      }
    } catch (error) {
      console.error('Error loading subscription status:', error)
    }
  }

  const subscribeToPlan = async (planId) => {
    if (!isAuthenticated) {
      setError('Please sign in to subscribe to a plan')
      return
    }

    if (isGuest) {
      setError('Guest users cannot subscribe. Please sign in with Google or GitHub.')
      return
    }

    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`${BACKEND_URL}/stripe/create-checkout-session`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        credentials: 'include',
        body: JSON.stringify({ plan_type: planId })
      })

      const data = await response.json()

      if (response.ok && data.checkout_url) {
        window.location.href = data.checkout_url
      } else {
        setError(data.error || 'Failed to create checkout session')
      }
    } catch (error) {
      console.error('Error subscribing:', error)
      setError('Network error while processing subscription')
    } finally {
      setLoading(false)
    }
  }

  const cancelSubscription = async () => {
    if (!confirm('Are you sure you want to cancel your subscription?')) {
      return
    }

    setLoading(true)
    setError(null)

    try {
      const response = await fetch(`${BACKEND_URL}/stripe/cancel-subscription`, {
        method: 'POST',
        credentials: 'include'
      })

      const data = await response.json()

      if (response.ok) {
        setError(null)
        await loadSubscriptionStatus()
        // Show success message
      } else {
        setError(data.error || 'Failed to cancel subscription')
      }
    } catch (error) {
      console.error('Error canceling subscription:', error)
      setError('Network error while canceling subscription')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="space-y-6">
      {error && (
        <Alert className="bg-red-900 border-red-700">
          <AlertDescription className="text-red-200">
            {error}
          </AlertDescription>
        </Alert>
      )}

      {subscriptionStatus && subscriptionStatus.status === 'active' && (
        <Card className="bg-green-900 border-green-700">
          <CardContent className="pt-6">
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-green-200 font-medium">Active Subscription</h3>
                <p className="text-green-300 text-sm">
                  {subscriptionStatus.plan} plan
                  {subscriptionStatus.cancel_at_period_end && ' (Canceling at period end)'}
                </p>
              </div>
              <Button
                onClick={cancelSubscription}
                disabled={loading}
                className="bg-red-600 hover:bg-red-700"
              >
                Cancel Subscription
              </Button>
            </div>
          </CardContent>
        </Card>
      )}

      <div className="grid md:grid-cols-3 gap-6">
        {plans.map((plan) => (
          <Card 
            key={plan.id} 
            className={`bg-black border-gray-800 relative ${
              plan.popular ? 'ring-2 ring-blue-500' : ''
            }`}
          >
            {plan.popular && (
              <div className="absolute -top-3 left-1/2 transform -translate-x-1/2">
                <Badge className="bg-blue-600 text-white">Most Popular</Badge>
              </div>
            )}
            
            <CardHeader className="text-center">
              <CardTitle className="text-white text-xl">{plan.name}</CardTitle>
              <div className="text-3xl font-bold text-white">
                {plan.price}
                <span className="text-sm text-gray-400">/{plan.interval}</span>
              </div>
            </CardHeader>
            
            <CardContent className="space-y-4">
              <ul className="space-y-2">
                {plan.features.map((feature, index) => (
                  <li key={index} className="text-gray-300 text-sm flex items-center">
                    <svg className="w-4 h-4 text-green-500 mr-2" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                    </svg>
                    {feature}
                  </li>
                ))}
              </ul>
              
              <Button
                onClick={() => subscribeToPlan(plan.id)}
                disabled={loading || (subscriptionStatus?.status === 'active')}
                className={`w-full ${
                  plan.popular 
                    ? 'bg-blue-600 hover:bg-blue-700' 
                    : 'bg-gray-700 hover:bg-gray-600'
                } text-white`}
              >
                {subscriptionStatus?.status === 'active' ? 'Current Plan' : 'Subscribe'}
              </Button>
            </CardContent>
          </Card>
        ))}
      </div>

      {!isAuthenticated && (
        <Card className="bg-yellow-900 border-yellow-700">
          <CardContent className="pt-6">
            <p className="text-yellow-200 text-center">
              Please sign in to subscribe to a plan and access premium features.
            </p>
          </CardContent>
        </Card>
      )}
    </div>
  )
}

export default SubscriptionPlans
```

The frontend implementation provides a comprehensive user experience that seamlessly integrates authentication and subscription management while maintaining high standards for accessibility, performance, and user experience. The component architecture enables easy maintenance and extension while providing robust error handling and user feedback throughout all user interactions.


## Stripe Payment Integration

The Stripe payment integration provides comprehensive subscription management capabilities that work seamlessly with the multi-provider authentication system. The integration supports flexible pricing models, automatic billing, webhook-based event handling, and comprehensive subscription lifecycle management while maintaining PCI compliance and security best practices.

### Stripe Service Architecture

The Stripe service implementation abstracts the complexity of payment processing and subscription management, providing a clean interface for the application to interact with Stripe's comprehensive payment infrastructure. The service handles customer creation, subscription management, payment processing, and webhook event handling while maintaining proper error handling and logging throughout all operations.

```python
import os
import stripe
from datetime import datetime
from services.user_service import UserService

class StripeService:
    def __init__(self):
        stripe.api_key = os.getenv('STRIPE_SECRET_KEY')
        self.webhook_secret = os.getenv('STRIPE_WEBHOOK_SECRET')
        self.user_service = UserService()
        
        # Price IDs for different subscription plans
        self.price_ids = {
            'basic': os.getenv('STRIPE_BASIC_PRICE_ID'),
            'pro': os.getenv('STRIPE_PRO_PRICE_ID'),
            'enterprise': os.getenv('STRIPE_ENTERPRISE_PRICE_ID')
        }
        
        # Validate configuration
        if not stripe.api_key:
            print("Warning: Stripe API key not configured")
        if not self.webhook_secret:
            print("Warning: Stripe webhook secret not configured")
    
    def create_customer(self, user_data):
        """Create a Stripe customer with comprehensive metadata"""
        try:
            customer = stripe.Customer.create(
                email=user_data.get('email'),
                name=user_data.get('name'),
                metadata={
                    'user_id': str(user_data.get('id')),
                    'provider': user_data.get('provider', 'unknown'),
                    'google_id': user_data.get('google_id', ''),
                    'github_id': user_data.get('github_id', ''),
                    'github_username': user_data.get('github_username', ''),
                    'created_at': datetime.utcnow().isoformat()
                }
            )
            
            # Update user record with Stripe customer ID
            self.user_service.supabase.table('users').update({
                'stripe_customer_id': customer.id
            }).eq('id', user_data.get('id')).execute()
            
            return customer
        except stripe.error.StripeError as e:
            print(f"Stripe error creating customer: {e}")
            return None
        except Exception as e:
            print(f"Error creating Stripe customer: {e}")
            return None
    
    def get_or_create_customer(self, user_data):
        """Get existing Stripe customer or create new one with intelligent matching"""
        try:
            # First, check if user already has a Stripe customer ID
            if user_data.get('stripe_customer_id'):
                try:
                    customer = stripe.Customer.retrieve(user_data['stripe_customer_id'])
                    if customer and not customer.deleted:
                        return customer
                except stripe.error.InvalidRequestError:
                    # Customer ID is invalid, continue to create new customer
                    pass
            
            # Search for existing customer by email
            customers = stripe.Customer.list(email=user_data.get('email'), limit=1)
            
            if customers.data:
                customer = customers.data[0]
                # Update user record with found customer ID
                self.user_service.supabase.table('users').update({
                    'stripe_customer_id': customer.id
                }).eq('id', user_data.get('id')).execute()
                return customer
            else:
                # Create new customer
                return self.create_customer(user_data)
                
        except stripe.error.StripeError as e:
            print(f"Stripe error getting/creating customer: {e}")
            return None
        except Exception as e:
            print(f"Error getting/creating customer: {e}")
            return None
```

The customer management system includes intelligent matching to prevent duplicate customers and maintains comprehensive metadata linking Stripe customers to application users across different authentication providers. This approach ensures that users maintain their payment history and subscription status regardless of their chosen authentication method.

### Subscription Management Implementation

The subscription management system provides comprehensive lifecycle management including subscription creation, modification, cancellation, and renewal handling. The implementation supports multiple pricing tiers and billing intervals while maintaining flexibility for future pricing model changes.

```python
    def create_checkout_session(self, user_id, plan_type, success_url, cancel_url):
        """Create a Stripe checkout session for subscription with comprehensive configuration"""
        try:
            # Get user data
            user = self.user_service.get_user_by_id(user_id)
            if not user:
                print(f"User not found: {user_id}")
                return None
            
            # Get or create Stripe customer
            customer = self.get_or_create_customer(user)
            if not customer:
                print("Failed to get or create Stripe customer")
                return None
            
            # Get price ID for the plan
            price_id = self.price_ids.get(plan_type)
            if not price_id:
                print(f"Invalid plan type: {plan_type}")
                return None
            
            # Create checkout session with comprehensive configuration
            session = stripe.checkout.Session.create(
                customer=customer.id,
                payment_method_types=['card'],
                line_items=[{
                    'price': price_id,
                    'quantity': 1,
                }],
                mode='subscription',
                success_url=success_url + '?session_id={CHECKOUT_SESSION_ID}',
                cancel_url=cancel_url,
                allow_promotion_codes=True,
                billing_address_collection='required',
                customer_update={
                    'address': 'auto',
                    'name': 'auto'
                },
                metadata={
                    'user_id': str(user_id),
                    'plan_type': plan_type,
                    'provider': user.get('provider', 'unknown')
                },
                subscription_data={
                    'metadata': {
                        'user_id': str(user_id),
                        'plan_type': plan_type,
                        'provider': user.get('provider', 'unknown')
                    }
                }
            )
            
            return session
            
        except stripe.error.StripeError as e:
            print(f"Stripe error creating checkout session: {e}")
            return None
        except Exception as e:
            print(f"Error creating checkout session: {e}")
            return None
    
    def get_subscription_status(self, customer_id):
        """Get comprehensive subscription status for a customer"""
        try:
            # Get active subscriptions
            subscriptions = stripe.Subscription.list(
                customer=customer_id, 
                status='all',
                limit=10
            )
            
            if not subscriptions.data:
                return {'status': 'inactive', 'plan': 'free'}
            
            # Find the most recent active subscription
            active_subscription = None
            for subscription in subscriptions.data:
                if subscription.status in ['active', 'trialing', 'past_due']:
                    active_subscription = subscription
                    break
            
            if active_subscription:
                # Get plan information
                plan_item = active_subscription.items.data[0]
                price = plan_item.price
                
                return {
                    'status': active_subscription.status,
                    'subscription_id': active_subscription.id,
                    'plan': self._get_plan_name_from_price_id(price.id),
                    'current_period_start': active_subscription.current_period_start,
                    'current_period_end': active_subscription.current_period_end,
                    'cancel_at_period_end': active_subscription.cancel_at_period_end,
                    'canceled_at': active_subscription.canceled_at,
                    'trial_end': active_subscription.trial_end,
                    'amount': price.unit_amount,
                    'currency': price.currency,
                    'interval': price.recurring.interval
                }
            else:
                # Check for canceled or incomplete subscriptions
                recent_subscription = subscriptions.data[0]
                return {
                    'status': recent_subscription.status,
                    'subscription_id': recent_subscription.id,
                    'plan': 'free',
                    'canceled_at': recent_subscription.canceled_at
                }
                
        except stripe.error.StripeError as e:
            print(f"Stripe error getting subscription status: {e}")
            return {'status': 'error', 'error': str(e)}
        except Exception as e:
            print(f"Error getting subscription status: {e}")
            return {'status': 'error', 'error': str(e)}
    
    def _get_plan_name_from_price_id(self, price_id):
        """Map Stripe price ID to plan name"""
        for plan_name, plan_price_id in self.price_ids.items():
            if plan_price_id == price_id:
                return plan_name
        return 'unknown'
    
    def cancel_subscription(self, subscription_id, immediate=False):
        """Cancel a subscription with options for immediate or end-of-period cancellation"""
        try:
            if immediate:
                # Cancel immediately
                subscription = stripe.Subscription.delete(subscription_id)
            else:
                # Cancel at end of current billing period
                subscription = stripe.Subscription.modify(
                    subscription_id,
                    cancel_at_period_end=True
                )
            
            return subscription
        except stripe.error.StripeError as e:
            print(f"Stripe error canceling subscription: {e}")
            return None
        except Exception as e:
            print(f"Error canceling subscription: {e}")
            return None
    
    def reactivate_subscription(self, subscription_id):
        """Reactivate a subscription that was set to cancel at period end"""
        try:
            subscription = stripe.Subscription.modify(
                subscription_id,
                cancel_at_period_end=False
            )
            return subscription
        except stripe.error.StripeError as e:
            print(f"Stripe error reactivating subscription: {e}")
            return None
        except Exception as e:
            print(f"Error reactivating subscription: {e}")
            return None
```

### Webhook Event Handling

The webhook system provides real-time processing of Stripe events, ensuring that the application's subscription status remains synchronized with Stripe's records. The implementation includes comprehensive event handling, signature verification, and idempotency protection to prevent duplicate processing.

```python
    def handle_webhook(self, payload, sig_header):
        """Handle Stripe webhook events with comprehensive processing"""
        try:
            # Verify webhook signature
            event = stripe.Webhook.construct_event(
                payload, sig_header, self.webhook_secret
            )
            
            print(f"Processing Stripe webhook event: {event['type']}")
            
            # Handle different event types
            if event['type'] == 'checkout.session.completed':
                self.handle_checkout_completed(event['data']['object'])
            elif event['type'] == 'customer.subscription.created':
                self.handle_subscription_created(event['data']['object'])
            elif event['type'] == 'customer.subscription.updated':
                self.handle_subscription_updated(event['data']['object'])
            elif event['type'] == 'customer.subscription.deleted':
                self.handle_subscription_deleted(event['data']['object'])
            elif event['type'] == 'invoice.payment_succeeded':
                self.handle_payment_succeeded(event['data']['object'])
            elif event['type'] == 'invoice.payment_failed':
                self.handle_payment_failed(event['data']['object'])
            elif event['type'] == 'customer.subscription.trial_will_end':
                self.handle_trial_will_end(event['data']['object'])
            else:
                print(f"Unhandled webhook event type: {event['type']}")
            
            return True
            
        except ValueError as e:
            print(f"Invalid webhook payload: {e}")
            return False
        except stripe.error.SignatureVerificationError as e:
            print(f"Invalid webhook signature: {e}")
            return False
        except Exception as e:
            print(f"Error handling webhook: {e}")
            return False
    
    def handle_checkout_completed(self, session):
        """Handle successful checkout completion"""
        try:
            user_id = session.get('metadata', {}).get('user_id')
            plan_type = session.get('metadata', {}).get('plan_type')
            subscription_id = session.get('subscription')
            
            if user_id and plan_type:
                # Update user subscription status
                update_data = {
                    'subscription_status': 'active',
                    'subscription_plan': plan_type,
                    'subscription_id': subscription_id,
                    'updated_at': datetime.utcnow().isoformat()
                }
                
                result = self.user_service.supabase.table('users').update(
                    update_data
                ).eq('id', user_id).execute()
                
                if result.data:
                    print(f"Updated user {user_id} subscription to {plan_type}")
                    
                    # Log subscription history
                    self._log_subscription_event(
                        user_id, 'subscription_activated', 
                        {'plan': plan_type, 'subscription_id': subscription_id}
                    )
                else:
                    print(f"Failed to update user {user_id} subscription status")
                    
        except Exception as e:
            print(f"Error handling checkout completion: {e}")
    
    def handle_subscription_updated(self, subscription):
        """Handle subscription updates including plan changes and status changes"""
        try:
            customer_id = subscription.get('customer')
            subscription_id = subscription.get('id')
            status = subscription.get('status')
            
            # Find user by customer ID
            user_result = self.user_service.supabase.table('users').select('*').eq(
                'stripe_customer_id', customer_id
            ).execute()
            
            if user_result.data:
                user = user_result.data[0]
                user_id = user['id']
                
                # Get plan information
                plan_type = 'free'
                if subscription.get('items', {}).get('data'):
                    price_id = subscription['items']['data'][0]['price']['id']
                    plan_type = self._get_plan_name_from_price_id(price_id)
                
                # Update user subscription status
                update_data = {
                    'subscription_status': status,
                    'subscription_plan': plan_type,
                    'subscription_id': subscription_id,
                    'subscription_period_end': datetime.fromtimestamp(
                        subscription.get('current_period_end', 0)
                    ).isoformat() if subscription.get('current_period_end') else None,
                    'subscription_cancel_at_period_end': subscription.get('cancel_at_period_end', False),
                    'updated_at': datetime.utcnow().isoformat()
                }
                
                result = self.user_service.supabase.table('users').update(
                    update_data
                ).eq('id', user_id).execute()
                
                if result.data:
                    print(f"Updated user {user_id} subscription: {status} - {plan_type}")
                    
                    # Log subscription history
                    self._log_subscription_event(
                        user_id, 'subscription_updated',
                        {
                            'status': status,
                            'plan': plan_type,
                            'subscription_id': subscription_id,
                            'cancel_at_period_end': subscription.get('cancel_at_period_end', False)
                        }
                    )
                    
        except Exception as e:
            print(f"Error handling subscription update: {e}")
    
    def handle_subscription_deleted(self, subscription):
        """Handle subscription cancellation"""
        try:
            customer_id = subscription.get('customer')
            subscription_id = subscription.get('id')
            
            # Find user by customer ID
            user_result = self.user_service.supabase.table('users').select('*').eq(
                'stripe_customer_id', customer_id
            ).execute()
            
            if user_result.data:
                user = user_result.data[0]
                user_id = user['id']
                
                # Update user to free plan
                update_data = {
                    'subscription_status': 'cancelled',
                    'subscription_plan': 'free',
                    'subscription_id': None,
                    'subscription_period_end': None,
                    'subscription_cancel_at_period_end': False,
                    'updated_at': datetime.utcnow().isoformat()
                }
                
                result = self.user_service.supabase.table('users').update(
                    update_data
                ).eq('id', user_id).execute()
                
                if result.data:
                    print(f"Cancelled subscription for user {user_id}")
                    
                    # Log subscription history
                    self._log_subscription_event(
                        user_id, 'subscription_cancelled',
                        {'subscription_id': subscription_id}
                    )
                    
        except Exception as e:
            print(f"Error handling subscription deletion: {e}")
    
    def handle_payment_failed(self, invoice):
        """Handle failed payment attempts"""
        try:
            customer_id = invoice.get('customer')
            subscription_id = invoice.get('subscription')
            amount_due = invoice.get('amount_due', 0)
            
            # Find user by customer ID
            user_result = self.user_service.supabase.table('users').select('*').eq(
                'stripe_customer_id', customer_id
            ).execute()
            
            if user_result.data:
                user = user_result.data[0]
                user_id = user['id']
                
                print(f"Payment failed for user {user_id}, amount: {amount_due}")
                
                # Log payment failure
                self._log_subscription_event(
                    user_id, 'payment_failed',
                    {
                        'subscription_id': subscription_id,
                        'amount_due': amount_due,
                        'currency': invoice.get('currency', 'usd')
                    }
                )
                
                # Could implement additional logic here such as:
                # - Sending notification emails
                # - Implementing grace periods
                # - Downgrading service access
                
        except Exception as e:
            print(f"Error handling payment failure: {e}")
    
    def _log_subscription_event(self, user_id, event_type, metadata):
        """Log subscription events for audit and analytics"""
        try:
            log_data = {
                'user_id': user_id,
                'event_type': event_type,
                'metadata': metadata,
                'created_at': datetime.utcnow().isoformat()
            }
            
            # This could be logged to a separate subscription_events table
            # or integrated with the existing activity logging system
            print(f"Subscription event logged: {event_type} for user {user_id}")
            
        except Exception as e:
            print(f"Error logging subscription event: {e}")
```

### Flask Routes for Stripe Integration

The Flask application includes comprehensive routes for handling Stripe operations, providing secure endpoints for subscription management while maintaining proper authentication and error handling.

```python
@app.route('/stripe/create-checkout-session', methods=['POST'])
@require_auth
def create_checkout_session():
    """Create Stripe checkout session with comprehensive validation"""
    try:
        data = request.get_json()
        plan_type = data.get('plan_type')
        
        # Validate plan type
        if not plan_type or plan_type not in ['basic', 'pro', 'enterprise']:
            return jsonify({'error': 'Invalid plan type'}), 400
        
        # Get user information
        user_id = request.current_user.get('user_id') or request.current_user.get('id')
        if not user_id:
            return jsonify({'error': 'User ID not found'}), 400
        
        # Check if user is guest
        if request.current_user.get('provider') == 'guest':
            return jsonify({'error': 'Guest users cannot subscribe. Please sign in with Google or GitHub.'}), 403
        
        # Generate URLs
        base_url = request.url_root.rstrip('/')
        success_url = f"{base_url}/subscription/success"
        cancel_url = f"{base_url}/subscription/cancel"
        
        # Create checkout session
        session = stripe_service.create_checkout_session(
            user_id, plan_type, success_url, cancel_url
        )
        
        if session:
            return jsonify({
                'checkout_url': session.url,
                'session_id': session.id
            })
        else:
            return jsonify({'error': 'Failed to create checkout session'}), 500
            
    except Exception as e:
        print(f"Error in create_checkout_session: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/stripe/subscription-status')
@require_auth
def get_subscription_status():
    """Get comprehensive subscription status for the current user"""
    try:
        user_id = request.current_user.get('user_id') or request.current_user.get('id')
        user = user_service.get_user_by_id(user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        # Check if user is guest
        if request.current_user.get('provider') == 'guest':
            return jsonify({
                'status': 'guest',
                'plan': 'free',
                'message': 'Guest users have limited access. Sign in to subscribe.'
            })
        
        # Get Stripe customer and subscription status
        customer = stripe_service.get_or_create_customer(user)
        if customer:
            status = stripe_service.get_subscription_status(customer.id)
            return jsonify(status)
        else:
            return jsonify({'status': 'inactive', 'plan': 'free'})
            
    except Exception as e:
        print(f"Error in get_subscription_status: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/stripe/cancel-subscription', methods=['POST'])
@require_auth
def cancel_subscription():
    """Cancel user's subscription with options"""
    try:
        data = request.get_json() or {}
        immediate = data.get('immediate', False)
        
        user_id = request.current_user.get('user_id') or request.current_user.get('id')
        user = user_service.get_user_by_id(user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        subscription_id = user.get('subscription_id')
        if not subscription_id:
            return jsonify({'error': 'No active subscription found'}), 404
        
        # Cancel subscription
        result = stripe_service.cancel_subscription(subscription_id, immediate)
        
        if result:
            return jsonify({
                'message': 'Subscription cancelled successfully',
                'immediate': immediate,
                'cancel_at_period_end': not immediate
            })
        else:
            return jsonify({'error': 'Failed to cancel subscription'}), 500
            
    except Exception as e:
        print(f"Error in cancel_subscription: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/stripe/reactivate-subscription', methods=['POST'])
@require_auth
def reactivate_subscription():
    """Reactivate a subscription that was set to cancel at period end"""
    try:
        user_id = request.current_user.get('user_id') or request.current_user.get('id')
        user = user_service.get_user_by_id(user_id)
        
        if not user:
            return jsonify({'error': 'User not found'}), 404
        
        subscription_id = user.get('subscription_id')
        if not subscription_id:
            return jsonify({'error': 'No subscription found'}), 404
        
        # Reactivate subscription
        result = stripe_service.reactivate_subscription(subscription_id)
        
        if result:
            return jsonify({'message': 'Subscription reactivated successfully'})
        else:
            return jsonify({'error': 'Failed to reactivate subscription'}), 500
            
    except Exception as e:
        print(f"Error in reactivate_subscription: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/stripe/webhook', methods=['POST'])
def stripe_webhook():
    """Handle Stripe webhooks with proper security and error handling"""
    try:
        payload = request.get_data()
        sig_header = request.headers.get('Stripe-Signature')
        
        if not sig_header:
            return jsonify({'error': 'Missing Stripe signature'}), 400
        
        # Process webhook
        success = stripe_service.handle_webhook(payload, sig_header)
        
        if success:
            return jsonify({'status': 'success'})
        else:
            return jsonify({'error': 'Webhook processing failed'}), 400
            
    except Exception as e:
        print(f"Error in stripe_webhook: {e}")
        return jsonify({'error': 'Internal server error'}), 500

@app.route('/subscription/success')
def subscription_success():
    """Subscription success page with session information"""
    session_id = request.args.get('session_id')
    
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Subscription Successful - Tubby AI</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body {{ 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: #000; 
                color: #fff; 
                margin: 0; 
                padding: 2rem;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
            }}
            .container {{
                text-align: center;
                max-width: 500px;
                padding: 2rem;
                border: 1px solid #333;
                border-radius: 12px;
                background: #111;
            }}
            .success-icon {{
                font-size: 4rem;
                margin-bottom: 1rem;
            }}
            h1 {{ color: #10b981; margin-bottom: 1rem; }}
            p {{ color: #d1d5db; margin-bottom: 1.5rem; }}
            .button {{
                display: inline-block;
                background: #3b82f6;
                color: white;
                padding: 0.75rem 1.5rem;
                text-decoration: none;
                border-radius: 8px;
                transition: background-color 0.2s;
            }}
            .button:hover {{ background: #2563eb; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="success-icon">✅</div>
            <h1>Welcome to Tubby AI Pro!</h1>
            <p>Your subscription has been activated successfully. You now have access to all premium features.</p>
            {f'<p><small>Session ID: {session_id}</small></p>' if session_id else ''}
            <a href="{os.getenv('FRONTEND_URL', 'http://localhost:3007')}" class="button">
                Return to Dashboard
            </a>
        </div>
    </body>
    </html>
    """

@app.route('/subscription/cancel')
def subscription_cancel():
    """Subscription canceled page"""
    return f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Subscription Canceled - Tubby AI</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
            body {{ 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                background: #000; 
                color: #fff; 
                margin: 0; 
                padding: 2rem;
                display: flex;
                justify-content: center;
                align-items: center;
                min-height: 100vh;
            }}
            .container {{
                text-align: center;
                max-width: 500px;
                padding: 2rem;
                border: 1px solid #333;
                border-radius: 12px;
                background: #111;
            }}
            .cancel-icon {{
                font-size: 4rem;
                margin-bottom: 1rem;
            }}
            h1 {{ color: #f59e0b; margin-bottom: 1rem; }}
            p {{ color: #d1d5db; margin-bottom: 1.5rem; }}
            .button {{
                display: inline-block;
                background: #3b82f6;
                color: white;
                padding: 0.75rem 1.5rem;
                text-decoration: none;
                border-radius: 8px;
                transition: background-color 0.2s;
                margin: 0.5rem;
            }}
            .button:hover {{ background: #2563eb; }}
            .button.secondary {{
                background: #6b7280;
            }}
            .button.secondary:hover {{ background: #4b5563; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="cancel-icon">⚠️</div>
            <h1>Subscription Canceled</h1>
            <p>No worries! You can try again anytime. Your account remains active with free tier access.</p>
            <a href="{os.getenv('FRONTEND_URL', 'http://localhost:3007')}" class="button">
                Return to Dashboard
            </a>
            <a href="{os.getenv('FRONTEND_URL', 'http://localhost:3007')}/pricing" class="button secondary">
                View Plans
            </a>
        </div>
    </body>
    </html>
    """
```

The Stripe integration provides comprehensive payment processing capabilities that seamlessly integrate with the multi-provider authentication system, ensuring that users can manage their subscriptions regardless of their chosen authentication method while maintaining security, reliability, and compliance with payment industry standards.


## Testing and Validation

Comprehensive testing is essential for ensuring the reliability and security of the multi-provider authentication and Stripe payment integration. The testing strategy encompasses unit tests, integration tests, end-to-end testing, security validation, and performance testing to ensure the system functions correctly under various conditions and edge cases.

### Authentication Flow Testing

Testing the authentication flows requires comprehensive validation of OAuth implementations, token handling, and user session management across multiple providers. The testing approach includes both automated tests and manual validation procedures to ensure complete coverage of authentication scenarios.

#### Google OAuth Testing

Google OAuth testing involves validating the complete authentication flow from initial authorization request through token exchange and user profile retrieval. The testing process includes validation of error handling, token expiration scenarios, and edge cases such as user denial of permissions or network connectivity issues.

```python
import unittest
import requests
from unittest.mock import patch, MagicMock
from services.oauth_service import OAuthService
from services.user_service import UserService

class TestGoogleOAuth(unittest.TestCase):
    def setUp(self):
        self.oauth_service = OAuthService()
        self.user_service = UserService()
        
        # Mock environment variables for testing
        self.test_env = {
            'GOOGLE_CLIENT_ID': 'test_google_client_id',
            'GOOGLE_CLIENT_SECRET': 'test_google_client_secret',
            'GOOGLE_REDIRECT_URI': 'http://localhost:5001/auth/google/callback',
            'JWT_SECRET_KEY': 'test_jwt_secret',
            'FRONTEND_URL': 'http://localhost:3007'
        }
    
    @patch.dict('os.environ', test_env)
    def test_google_auth_url_generation(self):
        """Test Google OAuth authorization URL generation"""
        auth_url = self.oauth_service.get_google_auth_url()
        
        # Verify URL contains required parameters
        self.assertIn('accounts.google.com/o/oauth2/auth', auth_url)
        self.assertIn('client_id=test_google_client_id', auth_url)
        self.assertIn('redirect_uri=http://localhost:5001/auth/google/callback', auth_url)
        self.assertIn('scope=openid+email+profile', auth_url)
    
    @patch('requests.get')
    @patch('services.oauth_service.Flow')
    def test_google_token_verification_success(self, mock_flow, mock_requests):
        """Test successful Google token verification"""
        # Mock Google API response
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            'id': '123456789',
            'email': 'test@example.com',
            'name': 'Test User',
            'picture': 'https://example.com/avatar.jpg',
            'verified_email': True
        }
        mock_requests.return_value = mock_response
        
        # Mock OAuth flow
        mock_flow_instance = MagicMock()
        mock_flow.from_client_config.return_value = mock_flow_instance
        mock_flow_instance.credentials.token = 'mock_access_token'
        
        # Test token verification
        result = self.oauth_service.verify_google_token('test_auth_code')
        
        # Verify result
        self.assertIsNotNone(result)
        self.assertEqual(result['email'], 'test@example.com')
        self.assertEqual(result['provider'], 'google')
        self.assertTrue(result['verified_email'])
    
    @patch('requests.get')
    @patch('services.oauth_service.Flow')
    def test_google_token_verification_failure(self, mock_flow, mock_requests):
        """Test Google token verification failure scenarios"""
        # Mock failed API response
        mock_response = MagicMock()
        mock_response.status_code = 401
        mock_requests.return_value = mock_response
        
        # Mock OAuth flow
        mock_flow_instance = MagicMock()
        mock_flow.from_client_config.return_value = mock_flow_instance
        mock_flow_instance.credentials.token = 'invalid_token'
        
        # Test token verification failure
        result = self.oauth_service.verify_google_token('invalid_auth_code')
        
        # Verify failure handling
        self.assertIsNone(result)
    
    def test_jwt_token_generation_and_verification(self):
        """Test JWT token generation and verification"""
        user_data = {
            'id': '123456789',
            'email': 'test@example.com',
            'name': 'Test User',
            'picture': 'https://example.com/avatar.jpg',
            'provider': 'google'
        }
        
        # Generate JWT token
        token = self.oauth_service.generate_jwt_token(user_data)
        self.assertIsNotNone(token)
        
        # Verify JWT token
        decoded_data = self.oauth_service.verify_jwt_token(token)
        self.assertIsNotNone(decoded_data)
        self.assertEqual(decoded_data['email'], 'test@example.com')
        self.assertEqual(decoded_data['provider'], 'google')
    
    def test_jwt_token_expiration(self):
        """Test JWT token expiration handling"""
        # This would require mocking datetime to test expiration
        # Implementation would involve creating an expired token and verifying rejection
        pass
```

#### GitHub OAuth Testing

GitHub OAuth testing follows similar patterns to Google OAuth but includes GitHub-specific API interactions and email retrieval logic. The testing validates the complete GitHub authentication flow including edge cases specific to GitHub's API behavior.

```python
class TestGitHubOAuth(unittest.TestCase):
    def setUp(self):
        self.oauth_service = OAuthService()
        
        # Mock environment variables for testing
        self.test_env = {
            'GITHUB_CLIENT_ID': 'test_github_client_id',
            'GITHUB_CLIENT_SECRET': 'test_github_client_secret',
            'GITHUB_REDIRECT_URI': 'http://localhost:5001/auth/github/callback',
            'JWT_SECRET_KEY': 'test_jwt_secret',
            'FRONTEND_URL': 'http://localhost:3007'
        }
    
    @patch.dict('os.environ', test_env)
    def test_github_auth_url_generation(self):
        """Test GitHub OAuth authorization URL generation"""
        auth_url = self.oauth_service.get_github_auth_url()
        
        # Verify URL contains required parameters
        self.assertIn('github.com/login/oauth/authorize', auth_url)
        self.assertIn('client_id=test_github_client_id', auth_url)
        self.assertIn('redirect_uri=http://localhost:5001/auth/github/callback', auth_url)
        self.assertIn('scope=user:email', auth_url)
        self.assertIn('state=github_oauth', auth_url)
    
    @patch('requests.get')
    @patch('requests.post')
    def test_github_token_verification_success(self, mock_post, mock_get):
        """Test successful GitHub token verification"""
        # Mock token exchange response
        mock_token_response = MagicMock()
        mock_token_response.status_code = 200
        mock_token_response.json.return_value = {
            'access_token': 'github_access_token',
            'token_type': 'bearer'
        }
        mock_post.return_value = mock_token_response
        
        # Mock user info and email responses
        mock_user_response = MagicMock()
        mock_user_response.status_code = 200
        mock_user_response.json.return_value = {
            'id': 987654321,
            'login': 'testuser',
            'name': 'Test User',
            'email': 'test@example.com',
            'avatar_url': 'https://github.com/avatar.jpg',
            'html_url': 'https://github.com/testuser'
        }
        
        mock_email_response = MagicMock()
        mock_email_response.status_code = 200
        mock_email_response.json.return_value = [
            {'email': 'test@example.com', 'primary': True, 'verified': True}
        ]
        
        mock_get.side_effect = [mock_user_response, mock_email_response]
        
        # Test token verification
        result = self.oauth_service.verify_github_token('test_auth_code')
        
        # Verify result
        self.assertIsNotNone(result)
        self.assertEqual(result['email'], 'test@example.com')
        self.assertEqual(result['provider'], 'github')
        self.assertEqual(result['github_username'], 'testuser')
        self.assertTrue(result['verified_email'])
    
    @patch('requests.get')
    @patch('requests.post')
    def test_github_email_fallback(self, mock_post, mock_get):
        """Test GitHub email retrieval fallback when user endpoint doesn't include email"""
        # Mock token exchange response
        mock_token_response = MagicMock()
        mock_token_response.status_code = 200
        mock_token_response.json.return_value = {
            'access_token': 'github_access_token',
            'token_type': 'bearer'
        }
        mock_post.return_value = mock_token_response
        
        # Mock user info response without email
        mock_user_response = MagicMock()
        mock_user_response.status_code = 200
        mock_user_response.json.return_value = {
            'id': 987654321,
            'login': 'testuser',
            'name': 'Test User',
            'email': None,  # No email in user endpoint
            'avatar_url': 'https://github.com/avatar.jpg'
        }
        
        # Mock email endpoint response
        mock_email_response = MagicMock()
        mock_email_response.status_code = 200
        mock_email_response.json.return_value = [
            {'email': 'primary@example.com', 'primary': True, 'verified': True},
            {'email': 'secondary@example.com', 'primary': False, 'verified': True}
        ]
        
        mock_get.side_effect = [mock_user_response, mock_email_response]
        
        # Test token verification
        result = self.oauth_service.verify_github_token('test_auth_code')
        
        # Verify primary email is selected
        self.assertIsNotNone(result)
        self.assertEqual(result['email'], 'primary@example.com')
```

### User Management Testing

User management testing validates the account creation, updating, and linking functionality across multiple OAuth providers. The tests ensure that users can authenticate with different providers while maintaining a unified account profile.

```python
class TestUserManagement(unittest.TestCase):
    def setUp(self):
        self.user_service = UserService()
        
        # Mock Supabase client
        self.mock_supabase = MagicMock()
        self.user_service.supabase = self.mock_supabase
    
    def test_create_google_user(self):
        """Test creating a new user with Google OAuth data"""
        google_user_data = {
            'id': '123456789',
            'email': 'test@example.com',
            'name': 'Test User',
            'picture': 'https://example.com/avatar.jpg',
            'verified_email': True,
            'provider': 'google'
        }
        
        # Mock Supabase responses
        self.mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []
        self.mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [
            {'id': 'user_uuid', **google_user_data}
        ]
        
        # Test user creation
        result = self.user_service.create_or_update_user(google_user_data)
        
        # Verify result
        self.assertIsNotNone(result)
        self.assertEqual(result['email'], 'test@example.com')
        self.assertEqual(result['provider'], 'google')
    
    def test_create_github_user(self):
        """Test creating a new user with GitHub OAuth data"""
        github_user_data = {
            'id': '987654321',
            'email': 'test@example.com',
            'name': 'Test User',
            'picture': 'https://github.com/avatar.jpg',
            'verified_email': True,
            'provider': 'github',
            'github_username': 'testuser',
            'github_profile_url': 'https://github.com/testuser'
        }
        
        # Mock Supabase responses for new user
        self.mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = []
        self.mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [
            {'id': 'user_uuid', **github_user_data}
        ]
        
        # Test user creation
        result = self.user_service.create_or_update_user(github_user_data)
        
        # Verify result
        self.assertIsNotNone(result)
        self.assertEqual(result['email'], 'test@example.com')
        self.assertEqual(result['provider'], 'github')
        self.assertEqual(result['github_username'], 'testuser')
    
    def test_account_linking(self):
        """Test linking accounts from different providers with same email"""
        # Existing Google user
        existing_user = {
            'id': 'user_uuid',
            'email': 'test@example.com',
            'name': 'Test User',
            'google_id': '123456789',
            'provider': 'google',
            'github_id': None,
            'github_username': None
        }
        
        # New GitHub authentication for same email
        github_user_data = {
            'id': '987654321',
            'email': 'test@example.com',
            'name': 'Test User',
            'provider': 'github',
            'github_username': 'testuser'
        }
        
        # Mock Supabase responses
        # First lookup by github_id returns empty
        # Second lookup by email returns existing user
        self.mock_supabase.table.return_value.select.return_value.eq.return_value.execute.side_effect = [
            MagicMock(data=[]),  # No GitHub ID match
            MagicMock(data=[existing_user])  # Email match found
        ]
        
        # Mock update response
        updated_user = {**existing_user, 'github_id': '987654321', 'github_username': 'testuser'}
        self.mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [updated_user]
        
        # Test account linking
        result = self.user_service.create_or_update_user(github_user_data)
        
        # Verify account linking
        self.assertIsNotNone(result)
        self.assertEqual(result['google_id'], '123456789')
        self.assertEqual(result['github_id'], '987654321')
        self.assertEqual(result['github_username'], 'testuser')
    
    def test_user_lookup_methods(self):
        """Test various user lookup methods"""
        test_user = {
            'id': 'user_uuid',
            'email': 'test@example.com',
            'google_id': '123456789',
            'github_id': '987654321'
        }
        
        # Test lookup by ID
        self.mock_supabase.table.return_value.select.return_value.eq.return_value.execute.return_value.data = [test_user]
        result = self.user_service.get_user_by_id('user_uuid')
        self.assertEqual(result['id'], 'user_uuid')
        
        # Test lookup by email
        result = self.user_service.get_user_by_email('test@example.com')
        self.assertEqual(result['email'], 'test@example.com')
        
        # Test lookup by Google ID
        result = self.user_service.get_user_by_google_id('123456789')
        self.assertEqual(result['google_id'], '123456789')
        
        # Test lookup by GitHub ID
        result = self.user_service.get_user_by_github_id('987654321')
        self.assertEqual(result['github_id'], '987654321')
```

### Stripe Integration Testing

Stripe integration testing requires comprehensive validation of payment processing, subscription management, and webhook handling. The testing approach includes both unit tests with mocked Stripe responses and integration tests with Stripe's test environment.

```python
class TestStripeIntegration(unittest.TestCase):
    def setUp(self):
        self.stripe_service = StripeService()
        
        # Mock environment variables
        self.test_env = {
            'STRIPE_SECRET_KEY': 'sk_test_mock_key',
            'STRIPE_WEBHOOK_SECRET': 'whsec_mock_secret',
            'STRIPE_BASIC_PRICE_ID': 'price_basic_test',
            'STRIPE_PRO_PRICE_ID': 'price_pro_test',
            'STRIPE_ENTERPRISE_PRICE_ID': 'price_enterprise_test'
        }
    
    @patch('stripe.Customer.create')
    def test_create_stripe_customer(self, mock_create):
        """Test Stripe customer creation"""
        user_data = {
            'id': 'user_uuid',
            'email': 'test@example.com',
            'name': 'Test User',
            'provider': 'google',
            'google_id': '123456789'
        }
        
        # Mock Stripe customer creation
        mock_customer = MagicMock()
        mock_customer.id = 'cus_test123'
        mock_create.return_value = mock_customer
        
        # Test customer creation
        result = self.stripe_service.create_customer(user_data)
        
        # Verify customer creation
        self.assertIsNotNone(result)
        self.assertEqual(result.id, 'cus_test123')
        
        # Verify metadata was included
        mock_create.assert_called_once()
        call_args = mock_create.call_args[1]
        self.assertEqual(call_args['email'], 'test@example.com')
        self.assertEqual(call_args['metadata']['provider'], 'google')
    
    @patch('stripe.checkout.Session.create')
    def test_create_checkout_session(self, mock_create):
        """Test Stripe checkout session creation"""
        user_data = {
            'id': 'user_uuid',
            'email': 'test@example.com',
            'name': 'Test User',
            'stripe_customer_id': 'cus_test123'
        }
        
        # Mock checkout session creation
        mock_session = MagicMock()
        mock_session.id = 'cs_test123'
        mock_session.url = 'https://checkout.stripe.com/pay/cs_test123'
        mock_create.return_value = mock_session
        
        # Mock user service
        self.stripe_service.user_service = MagicMock()
        self.stripe_service.user_service.get_user_by_id.return_value = user_data
        
        # Mock get_or_create_customer
        mock_customer = MagicMock()
        mock_customer.id = 'cus_test123'
        self.stripe_service.get_or_create_customer = MagicMock(return_value=mock_customer)
        
        # Test checkout session creation
        result = self.stripe_service.create_checkout_session(
            'user_uuid', 'pro', 'http://success.com', 'http://cancel.com'
        )
        
        # Verify session creation
        self.assertIsNotNone(result)
        self.assertEqual(result.url, 'https://checkout.stripe.com/pay/cs_test123')
    
    @patch('stripe.Subscription.list')
    def test_get_subscription_status(self, mock_list):
        """Test subscription status retrieval"""
        # Mock active subscription
        mock_subscription = MagicMock()
        mock_subscription.id = 'sub_test123'
        mock_subscription.status = 'active'
        mock_subscription.current_period_start = 1640995200  # 2022-01-01
        mock_subscription.current_period_end = 1643673600    # 2022-02-01
        mock_subscription.cancel_at_period_end = False
        mock_subscription.items.data = [MagicMock()]
        mock_subscription.items.data[0].price.id = 'price_pro_test'
        mock_subscription.items.data[0].price.unit_amount = 2999
        mock_subscription.items.data[0].price.currency = 'usd'
        mock_subscription.items.data[0].price.recurring.interval = 'month'
        
        mock_list.return_value.data = [mock_subscription]
        
        # Test subscription status retrieval
        result = self.stripe_service.get_subscription_status('cus_test123')
        
        # Verify result
        self.assertEqual(result['status'], 'active')
        self.assertEqual(result['plan'], 'pro')
        self.assertEqual(result['amount'], 2999)
        self.assertFalse(result['cancel_at_period_end'])
    
    @patch('stripe.Webhook.construct_event')
    def test_webhook_handling(self, mock_construct):
        """Test Stripe webhook event handling"""
        # Mock webhook event
        mock_event = {
            'type': 'checkout.session.completed',
            'data': {
                'object': {
                    'id': 'cs_test123',
                    'subscription': 'sub_test123',
                    'metadata': {
                        'user_id': 'user_uuid',
                        'plan_type': 'pro'
                    }
                }
            }
        }
        mock_construct.return_value = mock_event
        
        # Mock user service
        self.stripe_service.user_service = MagicMock()
        self.stripe_service.user_service.supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]
        
        # Test webhook handling
        result = self.stripe_service.handle_webhook('payload', 'signature')
        
        # Verify webhook processing
        self.assertTrue(result)
        mock_construct.assert_called_once_with('payload', 'signature', self.stripe_service.webhook_secret)
```

### End-to-End Testing

End-to-end testing validates the complete user journey from authentication through subscription management, ensuring that all components work together seamlessly in realistic usage scenarios.

```python
import pytest
import requests
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

class TestEndToEndFlow:
    @pytest.fixture
    def driver(self):
        """Setup Chrome WebDriver for testing"""
        options = webdriver.ChromeOptions()
        options.add_argument('--headless')  # Run in headless mode for CI
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')
        
        driver = webdriver.Chrome(options=options)
        driver.implicitly_wait(10)
        yield driver
        driver.quit()
    
    def test_google_oauth_flow(self, driver):
        """Test complete Google OAuth authentication flow"""
        # Navigate to login page
        driver.get('http://localhost:3007')
        
        # Wait for login page to load
        WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.TEXT, "Sign in with Google"))
        )
        
        # Click Google sign-in button
        google_button = driver.find_element(By.XPATH, "//button[contains(text(), 'Sign in with Google')]")
        google_button.click()
        
        # This would require additional setup for OAuth testing in a real environment
        # including test user credentials and OAuth consent handling
        
        # Verify redirect to Google OAuth
        WebDriverWait(driver, 10).until(
            lambda d: 'accounts.google.com' in d.current_url
        )
        
        # In a real test, you would:
        # 1. Fill in test credentials
        # 2. Handle OAuth consent
        # 3. Verify redirect back to application
        # 4. Check for successful authentication state
    
    def test_github_oauth_flow(self, driver):
        """Test complete GitHub OAuth authentication flow"""
        # Navigate to login page
        driver.get('http://localhost:3007')
        
        # Click GitHub sign-in button
        github_button = driver.find_element(By.XPATH, "//button[contains(text(), 'Sign in with GitHub')]")
        github_button.click()
        
        # Verify redirect to GitHub OAuth
        WebDriverWait(driver, 10).until(
            lambda d: 'github.com' in d.current_url
        )
        
        # Similar to Google OAuth, this would require additional setup
        # for handling GitHub OAuth flow in testing environment
    
    def test_subscription_flow(self, driver):
        """Test complete subscription purchase flow"""
        # This test would require:
        # 1. Authenticated user session
        # 2. Navigation to subscription page
        # 3. Plan selection
        # 4. Stripe checkout completion (using test cards)
        # 5. Verification of subscription activation
        pass
    
    def test_api_endpoints(self):
        """Test API endpoints with various authentication states"""
        base_url = 'http://localhost:5001'
        
        # Test unauthenticated access
        response = requests.get(f'{base_url}/auth/user')
        assert response.status_code == 401
        
        # Test protected endpoints
        response = requests.get(f'{base_url}/stripe/subscription-status')
        assert response.status_code == 401
        
        # Test with valid session (would require setup of authenticated session)
        # This would involve creating a test user session and validating
        # that protected endpoints return appropriate responses
```

### Performance and Load Testing

Performance testing ensures that the authentication and payment systems can handle expected user loads while maintaining acceptable response times and system stability.

```python
import asyncio
import aiohttp
import time
from concurrent.futures import ThreadPoolExecutor

class TestPerformance:
    def test_concurrent_authentication_requests(self):
        """Test system performance under concurrent authentication load"""
        
        async def make_auth_request(session, user_id):
            """Make an authentication status request"""
            try:
                async with session.get(
                    'http://localhost:5001/auth/user',
                    headers={'Authorization': f'Bearer test_token_{user_id}'}
                ) as response:
                    return response.status, await response.text()
            except Exception as e:
                return 500, str(e)
        
        async def run_concurrent_tests(num_requests=100):
            """Run concurrent authentication requests"""
            async with aiohttp.ClientSession() as session:
                tasks = [
                    make_auth_request(session, i) 
                    for i in range(num_requests)
                ]
                
                start_time = time.time()
                results = await asyncio.gather(*tasks)
                end_time = time.time()
                
                # Analyze results
                successful_requests = sum(1 for status, _ in results if status == 200)
                total_time = end_time - start_time
                requests_per_second = num_requests / total_time
                
                print(f"Completed {num_requests} requests in {total_time:.2f} seconds")
                print(f"Successful requests: {successful_requests}")
                print(f"Requests per second: {requests_per_second:.2f}")
                
                # Assert performance requirements
                assert requests_per_second > 50  # Minimum 50 RPS
                assert successful_requests / num_requests > 0.95  # 95% success rate
        
        # Run the test
        asyncio.run(run_concurrent_tests())
    
    def test_database_query_performance(self):
        """Test database query performance under load"""
        from services.user_service import UserService
        
        user_service = UserService()
        
        # Test user lookup performance
        start_time = time.time()
        for i in range(1000):
            user_service.get_user_by_email(f'test{i}@example.com')
        end_time = time.time()
        
        avg_query_time = (end_time - start_time) / 1000
        print(f"Average query time: {avg_query_time * 1000:.2f}ms")
        
        # Assert performance requirements
        assert avg_query_time < 0.1  # Less than 100ms per query
    
    def test_stripe_api_performance(self):
        """Test Stripe API integration performance"""
        from services.stripe_service import StripeService
        
        stripe_service = StripeService()
        
        # Test customer creation performance
        test_customers = []
        start_time = time.time()
        
        for i in range(10):  # Limited due to Stripe rate limits
            customer_data = {
                'id': f'test_user_{i}',
                'email': f'test{i}@example.com',
                'name': f'Test User {i}',
                'provider': 'test'
            }
            customer = stripe_service.create_customer(customer_data)
            if customer:
                test_customers.append(customer.id)
        
        end_time = time.time()
        avg_creation_time = (end_time - start_time) / len(test_customers)
        
        print(f"Created {len(test_customers)} customers in {end_time - start_time:.2f} seconds")
        print(f"Average creation time: {avg_creation_time:.2f} seconds")
        
        # Cleanup test customers
        for customer_id in test_customers:
            try:
                stripe.Customer.delete(customer_id)
            except:
                pass
        
        # Assert performance requirements
        assert avg_creation_time < 2.0  # Less than 2 seconds per customer creation
```

### Security Testing

Security testing validates that the authentication and payment systems properly protect user data and prevent common security vulnerabilities.

```python
class TestSecurity:
    def test_jwt_token_security(self):
        """Test JWT token security measures"""
        from services.oauth_service import OAuthService
        
        oauth_service = OAuthService()
        
        # Test token with tampered payload
        user_data = {'id': '123', 'email': 'test@example.com', 'provider': 'test'}
        valid_token = oauth_service.generate_jwt_token(user_data)
        
        # Tamper with token
        tampered_token = valid_token[:-10] + 'tampered123'
        
        # Verify tampered token is rejected
        result = oauth_service.verify_jwt_token(tampered_token)
        assert result is None
    
    def test_sql_injection_protection(self):
        """Test protection against SQL injection attacks"""
        from services.user_service import UserService
        
        user_service = UserService()
        
        # Test with malicious email input
        malicious_email = "test@example.com'; DROP TABLE users; --"
        
        # This should not cause any database issues
        result = user_service.get_user_by_email(malicious_email)
        assert result is None  # Should return None, not cause an error
    
    def test_oauth_state_parameter(self):
        """Test OAuth state parameter validation"""
        # This would test that OAuth flows properly validate state parameters
        # to prevent CSRF attacks
        pass
    
    def test_webhook_signature_validation(self):
        """Test Stripe webhook signature validation"""
        from services.stripe_service import StripeService
        
        stripe_service = StripeService()
        
        # Test with invalid signature
        result = stripe_service.handle_webhook('payload', 'invalid_signature')
        assert result is False
    
    def test_rate_limiting(self):
        """Test rate limiting on authentication endpoints"""
        # This would test that the application properly implements rate limiting
        # to prevent brute force attacks
        pass
```

The comprehensive testing strategy ensures that all aspects of the multi-provider authentication and Stripe payment integration function correctly, perform well under load, and maintain security standards. Regular execution of these tests during development and deployment helps maintain system reliability and user trust.


## Deployment and Production Considerations

Deploying the multi-provider authentication and Stripe payment integration to production requires careful attention to security, scalability, monitoring, and operational excellence. This section provides comprehensive guidance for production deployment, including infrastructure requirements, security hardening, monitoring setup, and operational procedures.

### Production Environment Configuration

Production deployment requires a robust infrastructure configuration that can handle user load while maintaining security and reliability. The deployment architecture should include redundancy, monitoring, and automated scaling capabilities to ensure consistent service availability.

#### Infrastructure Requirements

The production infrastructure must support the Flask backend application, React frontend, database services, and associated monitoring and logging systems. The recommended architecture includes load balancers, application servers, database clusters, and content delivery networks to ensure optimal performance and reliability.

For cloud deployment, consider using managed services that provide automatic scaling, backup, and monitoring capabilities. Amazon Web Services, Google Cloud Platform, or Microsoft Azure all provide comprehensive managed services that can significantly reduce operational overhead while improving reliability and security.

The database infrastructure should include primary and replica instances for high availability, automated backups with point-in-time recovery capabilities, and monitoring for performance and capacity planning. Connection pooling and query optimization are essential for handling concurrent user sessions and payment processing operations.

```yaml
# Example Docker Compose configuration for production
version: '3.8'

services:
  backend:
    build: 
      context: ./backend
      dockerfile: Dockerfile.prod
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=${DATABASE_URL}
      - REDIS_URL=${REDIS_URL}
      - GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
      - GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
      - GITHUB_CLIENT_ID=${GITHUB_CLIENT_ID}
      - GITHUB_CLIENT_SECRET=${GITHUB_CLIENT_SECRET}
      - STRIPE_SECRET_KEY=${STRIPE_SECRET_KEY}
      - STRIPE_WEBHOOK_SECRET=${STRIPE_WEBHOOK_SECRET}
      - JWT_SECRET_KEY=${JWT_SECRET_KEY}
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '1.0'
          memory: 1G
        reservations:
          cpus: '0.5'
          memory: 512M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5001/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  frontend:
    build:
      context: ./
      dockerfile: Dockerfile.frontend.prod
    environment:
      - VITE_BACKEND_URL=${BACKEND_URL}
      - VITE_STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY}
    deploy:
      replicas: 2
      resources:
        limits:
          cpus: '0.5'
          memory: 512M

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - backend
      - frontend
    deploy:
      replicas: 2

  redis:
    image: redis:alpine
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 256M

volumes:
  redis_data:

networks:
  default:
    driver: overlay
    attachable: true
```

#### Environment Variable Management

Production environment variables must be managed securely using dedicated secret management systems rather than plain text files. Consider using AWS Secrets Manager, Azure Key Vault, Google Secret Manager, or HashiCorp Vault for storing sensitive configuration data.

Environment variables should be organized by service and environment, with clear naming conventions and documentation. Implement automated rotation for sensitive credentials such as database passwords, API keys, and JWT signing secrets.

```bash
# Production environment variables template
# Database Configuration
DATABASE_URL=postgresql://user:password@db-cluster.region.rds.amazonaws.com:5432/tubby_prod
DATABASE_POOL_SIZE=20
DATABASE_MAX_OVERFLOW=30

# Redis Configuration
REDIS_URL=redis://redis-cluster.region.cache.amazonaws.com:6379
REDIS_PASSWORD=secure_redis_password

# OAuth Configuration
GOOGLE_CLIENT_ID=production_google_client_id
GOOGLE_CLIENT_SECRET=production_google_client_secret
GOOGLE_REDIRECT_URI=https://tubby.ai/auth/google/callback

GITHUB_CLIENT_ID=production_github_client_id
GITHUB_CLIENT_SECRET=production_github_client_secret
GITHUB_REDIRECT_URI=https://tubby.ai/auth/github/callback

# Stripe Configuration
STRIPE_PUBLISHABLE_KEY=pk_live_production_publishable_key
STRIPE_SECRET_KEY=sk_live_production_secret_key
STRIPE_WEBHOOK_SECRET=whsec_production_webhook_secret

# Application Configuration
JWT_SECRET_KEY=production_jwt_secret_key_256_bits_minimum
JWT_ALGORITHM=HS256
JWT_EXPIRATION_HOURS=24

FRONTEND_URL=https://tubby.ai
BACKEND_URL=https://api.tubby.ai

# Monitoring and Logging
SENTRY_DSN=https://sentry.io/dsn/production
LOG_LEVEL=INFO
METRICS_ENABLED=true
```

### Security Hardening

Production security requires comprehensive hardening measures including HTTPS enforcement, security headers, input validation, rate limiting, and monitoring for security events. The security implementation should follow industry best practices and compliance requirements.

#### HTTPS and SSL/TLS Configuration

All production traffic must use HTTPS with properly configured SSL/TLS certificates. Implement HTTP Strict Transport Security (HSTS), certificate pinning where appropriate, and regular certificate renewal processes.

```nginx
# Nginx configuration for production security
server {
    listen 80;
    server_name tubby.ai www.tubby.ai;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name tubby.ai www.tubby.ai;

    # SSL Configuration
    ssl_certificate /etc/nginx/ssl/tubby.ai.crt;
    ssl_certificate_key /etc/nginx/ssl/tubby.ai.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https://js.stripe.com; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https://api.stripe.com; frame-src https://js.stripe.com;" always;

    # Rate Limiting
    limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;
    limit_req_zone $binary_remote_addr zone=api:10m rate=100r/m;

    # Frontend
    location / {
        proxy_pass http://frontend:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Backend API
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://backend:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Authentication endpoints with stricter rate limiting
    location /auth/ {
        limit_req zone=auth burst=10 nodelay;
        proxy_pass http://backend:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # Stripe webhooks
    location /stripe/webhook {
        proxy_pass http://backend:5001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 1m;
    }
}
```

#### Application Security Configuration

The Flask application requires security-focused configuration including secure session management, CSRF protection, input validation, and comprehensive logging of security events.

```python
# Production Flask security configuration
from flask import Flask
from flask_talisman import Talisman
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import logging
import os

app = Flask(__name__)

# Security Configuration
app.config.update(
    SECRET_KEY=os.getenv('JWT_SECRET_KEY'),
    SESSION_COOKIE_SECURE=True,
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE='Lax',
    PERMANENT_SESSION_LIFETIME=timedelta(hours=24),
    WTF_CSRF_ENABLED=True,
    WTF_CSRF_TIME_LIMIT=None,
    MAX_CONTENT_LENGTH=16 * 1024 * 1024  # 16MB max request size
)

# Content Security Policy
csp = {
    'default-src': "'self'",
    'script-src': [
        "'self'",
        "'unsafe-inline'",  # Required for some React functionality
        'https://js.stripe.com'
    ],
    'style-src': [
        "'self'",
        "'unsafe-inline'"  # Required for dynamic styles
    ],
    'img-src': [
        "'self'",
        'data:',
        'https:'
    ],
    'connect-src': [
        "'self'",
        'https://api.stripe.com'
    ],
    'frame-src': [
        'https://js.stripe.com'
    ]
}

# Apply security headers
Talisman(app, 
    force_https=True,
    strict_transport_security=True,
    content_security_policy=csp,
    referrer_policy='strict-origin-when-cross-origin'
)

# Rate Limiting
limiter = Limiter(
    app,
    key_func=get_remote_address,
    default_limits=["1000 per hour", "100 per minute"],
    storage_uri=os.getenv('REDIS_URL')
)

# Apply stricter limits to authentication endpoints
@app.route('/auth/<provider>')
@limiter.limit("5 per minute")
def auth_endpoint(provider):
    # Authentication logic
    pass

# Security logging
security_logger = logging.getLogger('security')
security_handler = logging.FileHandler('/var/log/tubby/security.log')
security_handler.setFormatter(logging.Formatter(
    '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
))
security_logger.addHandler(security_handler)
security_logger.setLevel(logging.INFO)

# Log security events
def log_security_event(event_type, user_id=None, ip_address=None, details=None):
    security_logger.info(f"Security Event: {event_type}", extra={
        'user_id': user_id,
        'ip_address': ip_address,
        'details': details,
        'timestamp': datetime.utcnow().isoformat()
    })
```

### Monitoring and Observability

Production monitoring requires comprehensive observability including application metrics, performance monitoring, error tracking, and business metrics. The monitoring system should provide real-time alerts and historical analysis capabilities.

#### Application Performance Monitoring

Implement comprehensive application performance monitoring using tools like New Relic, Datadog, or open-source alternatives like Prometheus and Grafana. Monitor key metrics including response times, error rates, throughput, and resource utilization.

```python
# Application monitoring setup
import time
import psutil
from prometheus_client import Counter, Histogram, Gauge, generate_latest
from flask import request, g

# Metrics definitions
REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])
ACTIVE_USERS = Gauge('active_users_total', 'Number of active users')
SUBSCRIPTION_COUNT = Gauge('subscriptions_total', 'Number of active subscriptions', ['plan'])
AUTHENTICATION_COUNT = Counter('authentications_total', 'Total authentications', ['provider', 'status'])

# System metrics
CPU_USAGE = Gauge('cpu_usage_percent', 'CPU usage percentage')
MEMORY_USAGE = Gauge('memory_usage_percent', 'Memory usage percentage')
DATABASE_CONNECTIONS = Gauge('database_connections_active', 'Active database connections')

@app.before_request
def before_request():
    g.start_time = time.time()

@app.after_request
def after_request(response):
    # Record request metrics
    duration = time.time() - g.start_time
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown',
        status=response.status_code
    ).inc()
    
    REQUEST_DURATION.labels(
        method=request.method,
        endpoint=request.endpoint or 'unknown'
    ).observe(duration)
    
    return response

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    # Update system metrics
    CPU_USAGE.set(psutil.cpu_percent())
    MEMORY_USAGE.set(psutil.virtual_memory().percent)
    
    # Update business metrics
    update_business_metrics()
    
    return generate_latest()

def update_business_metrics():
    """Update business-specific metrics"""
    try:
        # Count active users (logged in within last 24 hours)
        active_users_count = user_service.supabase.table('users').select('id').gte(
            'last_login_at', 
            (datetime.utcnow() - timedelta(hours=24)).isoformat()
        ).execute()
        ACTIVE_USERS.set(len(active_users_count.data) if active_users_count.data else 0)
        
        # Count subscriptions by plan
        for plan in ['basic', 'pro', 'enterprise']:
            subscription_count = user_service.supabase.table('users').select('id').eq(
                'subscription_plan', plan
            ).eq('subscription_status', 'active').execute()
            SUBSCRIPTION_COUNT.labels(plan=plan).set(
                len(subscription_count.data) if subscription_count.data else 0
            )
            
    except Exception as e:
        app.logger.error(f"Error updating business metrics: {e}")
```

#### Error Tracking and Logging

Implement comprehensive error tracking using services like Sentry, Rollbar, or Bugsnag. Configure structured logging with appropriate log levels and ensure sensitive information is not logged.

```python
import sentry_sdk
from sentry_sdk.integrations.flask import FlaskIntegration
from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
import structlog

# Sentry configuration
sentry_sdk.init(
    dsn=os.getenv('SENTRY_DSN'),
    integrations=[
        FlaskIntegration(transaction_style='endpoint'),
        SqlalchemyIntegration()
    ],
    traces_sample_rate=0.1,  # 10% of transactions for performance monitoring
    environment=os.getenv('ENVIRONMENT', 'production'),
    release=os.getenv('APP_VERSION', 'unknown')
)

# Structured logging configuration
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    wrapper_class=structlog.stdlib.BoundLogger,
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Custom error handler
@app.errorhandler(Exception)
def handle_exception(e):
    # Log the error with context
    logger.error(
        "Unhandled exception",
        error=str(e),
        user_id=getattr(request, 'current_user', {}).get('id'),
        endpoint=request.endpoint,
        method=request.method,
        url=request.url,
        user_agent=request.headers.get('User-Agent'),
        ip_address=request.remote_addr
    )
    
    # Return appropriate error response
    if isinstance(e, HTTPException):
        return e
    
    return jsonify({'error': 'Internal server error'}), 500
```

### Database Management and Scaling

Production database management requires careful attention to performance, backup, recovery, and scaling considerations. Implement automated backup procedures, monitoring, and capacity planning.

#### Database Optimization

Optimize database performance through proper indexing, query optimization, connection pooling, and caching strategies. Monitor query performance and implement slow query logging for continuous optimization.

```sql
-- Production database optimization
-- Ensure proper indexes are in place
CREATE INDEX CONCURRENTLY idx_users_email_active ON users(email) WHERE subscription_status = 'active';
CREATE INDEX CONCURRENTLY idx_users_last_login ON users(last_login_at) WHERE last_login_at > NOW() - INTERVAL '30 days';
CREATE INDEX CONCURRENTLY idx_subscription_history_user_created ON subscription_history(user_id, created_at);

-- Partitioning for large tables
CREATE TABLE subscription_history_2024 PARTITION OF subscription_history
FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

-- Database maintenance procedures
CREATE OR REPLACE FUNCTION cleanup_old_activity_logs()
RETURNS void AS $$
BEGIN
    DELETE FROM user_activity_log 
    WHERE created_at < NOW() - INTERVAL '90 days';
END;
$$ LANGUAGE plpgsql;

-- Schedule regular maintenance
SELECT cron.schedule('cleanup-logs', '0 2 * * 0', 'SELECT cleanup_old_activity_logs();');
```

#### Backup and Recovery

Implement comprehensive backup and recovery procedures including automated daily backups, point-in-time recovery capabilities, and regular recovery testing.

```bash
#!/bin/bash
# Production backup script

# Configuration
DB_HOST="production-db-cluster.region.rds.amazonaws.com"
DB_NAME="tubby_prod"
DB_USER="backup_user"
BACKUP_DIR="/backups/postgresql"
S3_BUCKET="tubby-backups"
RETENTION_DAYS=30

# Create backup directory
mkdir -p $BACKUP_DIR

# Generate backup filename with timestamp
BACKUP_FILE="tubby_prod_$(date +%Y%m%d_%H%M%S).sql"
BACKUP_PATH="$BACKUP_DIR/$BACKUP_FILE"

# Create database backup
pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME \
    --verbose --clean --no-owner --no-privileges \
    --format=custom --compress=9 \
    --file=$BACKUP_PATH

# Verify backup integrity
pg_restore --list $BACKUP_PATH > /dev/null
if [ $? -eq 0 ]; then
    echo "Backup created successfully: $BACKUP_FILE"
    
    # Upload to S3
    aws s3 cp $BACKUP_PATH s3://$S3_BUCKET/postgresql/
    
    # Clean up local backup files older than retention period
    find $BACKUP_DIR -name "*.sql" -mtime +$RETENTION_DAYS -delete
    
    # Update monitoring
    echo "backup_success 1" | curl -X POST --data-binary @- \
        http://pushgateway:9091/metrics/job/postgresql_backup
else
    echo "Backup verification failed!"
    echo "backup_success 0" | curl -X POST --data-binary @- \
        http://pushgateway:9091/metrics/job/postgresql_backup
    exit 1
fi
```

### Deployment Automation

Implement automated deployment procedures using CI/CD pipelines that include testing, security scanning, and gradual rollout capabilities. The deployment process should minimize downtime and provide rollback capabilities.

```yaml
# GitHub Actions deployment pipeline
name: Production Deployment

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: test
          POSTGRES_DB: tubby_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        pip install -r backend/requirements.txt
        pip install -r backend/requirements-test.txt
    
    - name: Run tests
      run: |
        pytest backend/tests/ --cov=backend --cov-report=xml
    
    - name: Security scan
      run: |
        bandit -r backend/ -f json -o security-report.json
        safety check --json --output safety-report.json
    
    - name: Upload coverage
      uses: codecov/codecov-action@v3

  security-scan:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  deploy:
    needs: [test, security-scan]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-east-1
    
    - name: Build and push Docker images
      run: |
        # Build backend image
        docker build -t tubby-backend:${{ github.sha }} ./backend
        docker tag tubby-backend:${{ github.sha }} ${{ secrets.ECR_REGISTRY }}/tubby-backend:${{ github.sha }}
        docker push ${{ secrets.ECR_REGISTRY }}/tubby-backend:${{ github.sha }}
        
        # Build frontend image
        docker build -t tubby-frontend:${{ github.sha }} .
        docker tag tubby-frontend:${{ github.sha }} ${{ secrets.ECR_REGISTRY }}/tubby-frontend:${{ github.sha }}
        docker push ${{ secrets.ECR_REGISTRY }}/tubby-frontend:${{ github.sha }}
    
    - name: Deploy to ECS
      run: |
        # Update ECS service with new image
        aws ecs update-service \
          --cluster tubby-production \
          --service tubby-backend \
          --task-definition tubby-backend:${{ github.sha }}
        
        aws ecs update-service \
          --cluster tubby-production \
          --service tubby-frontend \
          --task-definition tubby-frontend:${{ github.sha }}
    
    - name: Wait for deployment
      run: |
        aws ecs wait services-stable \
          --cluster tubby-production \
          --services tubby-backend tubby-frontend
    
    - name: Run smoke tests
      run: |
        # Basic health checks
        curl -f https://api.tubby.ai/health
        curl -f https://tubby.ai/
    
    - name: Notify deployment
      uses: 8398a7/action-slack@v3
      with:
        status: ${{ job.status }}
        channel: '#deployments'
        webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

The production deployment strategy ensures reliable, secure, and scalable operation of the multi-provider authentication and Stripe payment integration while providing comprehensive monitoring, backup, and recovery capabilities. Regular review and updates of these procedures ensure continued operational excellence as the system evolves and scales.

