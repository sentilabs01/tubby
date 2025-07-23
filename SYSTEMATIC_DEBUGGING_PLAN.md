# 🔍 Systematic Debugging Plan - Elastic Beanstalk Deployment

## 📋 **Current Situation Analysis**

### **What We Know:**
1. ✅ **GitHub Push Successful**: Clean repository with secrets removed
2. ✅ **Requirements.txt Fixed**: Merge conflicts resolved
3. ❌ **Elastic Beanstalk Deployment Failing**: Environment stuck in "Red" health
4. ❌ **Procfile Issues**: Multiple parsing errors despite attempts to fix
5. ❌ **Application Not Starting**: 502 Bad Gateway errors

### **Root Cause Hypothesis:**
The deployment is failing due to a combination of:
- Procfile syntax/encoding issues
- Application startup failures
- Environment configuration problems
- Possible dependency conflicts

## 🎯 **Systematic Debugging Approach**

### **Phase 1: Environment Isolation & Clean Slate**

#### **Step 1.1: Terminate Current Environment**
```bash
# Current environment is corrupted - start fresh
eb terminate tubby-backend-prod
eb terminate tubby-backend-prod-new
```

#### **Step 1.2: Create Minimal Test Environment**
```bash
# Create new environment with minimal configuration
eb create tubby-backend-debug --instance-type t2.micro --single-instance
```

#### **Step 1.3: Deploy Minimal Test App**
Create a **completely minimal** Flask app to verify basic deployment:

**File: `backend/minimal_test.py`**
```python
from flask import Flask, jsonify
from datetime import datetime

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        "status": "success",
        "message": "Minimal Flask app working!",
        "timestamp": datetime.now().isoformat()
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004, debug=False)
```

**File: `backend/Procfile`**
```
web: gunicorn minimal_test:app
```

### **Phase 2: Progressive Complexity Testing**

#### **Step 2.1: Test Minimal App**
```bash
cd backend
eb deploy
eb status
curl http://your-eb-url/health
```

**Success Criteria:**
- Environment shows "Green" health
- `/health` endpoint returns 200 OK
- No startup errors in logs

#### **Step 2.2: Add Basic Dependencies**
If minimal app works, gradually add dependencies:

**File: `backend/requirements_minimal.txt`**
```
flask==2.3.3
gunicorn==21.2.0
```

**File: `backend/test_with_deps.py`**
```python
from flask import Flask, jsonify
from datetime import datetime
import os

app = Flask(__name__)

@app.route('/')
def index():
    return jsonify({
        "status": "success",
        "message": "Flask with dependencies working!",
        "env": os.getenv('FLASK_ENV', 'not_set'),
        "timestamp": datetime.now().isoformat()
    })

@app.route('/health')
def health():
    return jsonify({"status": "healthy"})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5004, debug=False)
```

#### **Step 2.3: Add Environment Variables**
```bash
# Test with basic environment variables
eb setenv FLASK_ENV=production SECRET_KEY=test-key
eb deploy
```

### **Phase 3: Application-Specific Debugging**

#### **Step 3.1: Test Production App Structure**
Once basic deployment works, test the actual production app:

**File: `backend/app_debug.py`**
```python
from flask import Flask, jsonify
from datetime import datetime
import os

app = Flask(__name__)

# Basic configuration
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

@app.route('/')
def index():
    return jsonify({
        "status": "success",
        "message": "Production app structure working!",
        "timestamp": datetime.now().isoformat()
    })

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    })

@app.route('/test')
def test():
    return jsonify({"message": "Test endpoint working!"})

if __name__ == '__main__':
    port = int(os.getenv('PORT', '5004'))
    host = os.getenv('HOST', '0.0.0.0')
    print(f"Starting server on {host}:{port}")
    app.run(host=host, port=port, debug=False)
```

#### **Step 3.2: Add Dependencies One by One**
```bash
# Test with minimal production requirements
pip install flask flask-cors python-dotenv
```

**File: `backend/requirements_debug.txt`**
```
flask==2.3.3
flask-cors==4.0.0
python-dotenv==1.0.0
gunicorn==21.2.0
```

### **Phase 4: Full Application Testing**

#### **Step 4.1: Test Complete App**
Once basic structure works, test the full application:

**File: `backend/app_production_debug.py`**
```python
from flask import Flask, jsonify
from flask_cors import CORS
from datetime import datetime
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

# Configure CORS
CORS(app, origins=['*'], supports_credentials=True, methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])

@app.route('/')
def index():
    return jsonify({
        "message": "Tubby AI Backend Debug Version",
        "status": "running",
        "timestamp": datetime.now().isoformat()
    })

@app.route('/health')
def health():
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "version": "1.0.0"
    })

@app.route('/test')
def test():
    return jsonify({"message": "Test endpoint working!"})

@app.route('/auth/user')
def get_current_user():
    return jsonify({"error": "No user session"}), 401

@app.route('/auth/guest', methods=['GET', 'POST'])
def guest_auth():
    return jsonify({
        "user": {
            "id": "guest_test",
            "name": "Guest User",
            "type": "guest",
            "subscription_status": "basic"
        }
    })

if __name__ == '__main__':
    port = int(os.getenv('PORT', '5004'))
    host = os.getenv('HOST', '0.0.0.0')
    print(f"Starting debug server on {host}:{port}")
    app.run(host=host, port=port, debug=False)
```

#### **Step 4.2: Add Required Dependencies**
```bash
# Add all required dependencies
pip install flask flask-cors python-dotenv gunicorn requests
```

**File: `backend/requirements_production_debug.txt`**
```
flask==2.3.3
flask-cors==4.0.0
python-dotenv==1.0.0
gunicorn==21.2.0
requests==2.31.0
```

### **Phase 5: Environment Configuration**

#### **Step 5.1: Test Environment Variables**
```bash
# Set basic environment variables
eb setenv FLASK_ENV=production SECRET_KEY=your-secret-key
eb deploy
```

#### **Step 5.2: Add Supabase Configuration**
```bash
# Add Supabase environment variables
eb setenv SUPABASE_URL=your-supabase-url SUPABASE_ANON_KEY=your-supabase-key
eb deploy
```

#### **Step 5.3: Test Database Connection**
Add database connection test to the debug app.

### **Phase 6: Full Application Deployment**

#### **Step 6.1: Deploy Complete App**
Once all components work individually, deploy the full application:

**File: `backend/Procfile`**
```
web: gunicorn app_production:app
```

#### **Step 6.2: Add All Environment Variables**
```bash
# Add all required environment variables
eb setenv FLASK_ENV=production SECRET_KEY=your-secret-key SUPABASE_URL=your-url SUPABASE_ANON_KEY=your-key GOOGLE_CLIENT_ID=your-id GOOGLE_CLIENT_SECRET=your-secret STRIPE_SECRET_KEY=your-stripe-key
eb deploy
```

## 🔧 **Debugging Tools & Commands**

### **Essential Commands**
```bash
# Check environment status
eb status

# View logs
eb logs --all

# Check environment variables
eb printenv

# Test endpoint
curl http://your-eb-url/health

# SSH into instance (if needed)
eb ssh
```

### **Log Analysis**
```bash
# Check specific log files
eb logs --all
# Look for:
# - Application startup errors
# - Module import errors
# - Environment variable issues
# - Port binding problems
```

### **Health Check Verification**
```bash
# Test health endpoint
curl -v http://your-eb-url/health

# Expected response:
# {"status": "healthy", "timestamp": "...", "version": "1.0.0"}
```

## 🎯 **Success Criteria**

### **Phase 1 Success:**
- ✅ Environment shows "Green" health
- ✅ Minimal app responds to requests
- ✅ No startup errors in logs

### **Phase 2 Success:**
- ✅ Dependencies install correctly
- ✅ Environment variables load
- ✅ Basic Flask app works

### **Phase 3 Success:**
- ✅ Production app structure works
- ✅ CORS configuration functional
- ✅ All basic endpoints respond

### **Phase 4 Success:**
- ✅ Full application deploys
- ✅ All environment variables configured
- ✅ Database connections work
- ✅ Authentication endpoints respond

## 🚨 **Common Issues & Solutions**

### **Issue 1: Procfile Parsing Error**
**Symptoms:** `Procfile could not be parsed`
**Solutions:**
- Use simple Procfile: `web: gunicorn app:app`
- Check for hidden characters
- Ensure UTF-8 encoding
- Remove any special characters

### **Issue 2: Module Import Errors**
**Symptoms:** `ModuleNotFoundError`
**Solutions:**
- Check requirements.txt syntax
- Verify all dependencies listed
- Test imports locally first
- Use minimal requirements to start

### **Issue 3: Environment Variable Issues**
**Symptoms:** `KeyError` or missing configuration
**Solutions:**
- Set environment variables via `eb setenv`
- Use `.ebextensions/environment.config`
- Test with hardcoded values first
- Verify variable names match code

### **Issue 4: Port Binding Issues**
**Symptoms:** `Address already in use` or connection refused
**Solutions:**
- Use `0.0.0.0` as host
- Let Elastic Beanstalk handle port mapping
- Check for conflicting processes
- Use environment variable for port

## 📊 **Progress Tracking**

### **Current Status:**
- [ ] Phase 1: Environment Isolation
- [ ] Phase 2: Progressive Complexity
- [ ] Phase 3: Application-Specific Debugging
- [ ] Phase 4: Full Application Testing
- [ ] Phase 5: Environment Configuration
- [ ] Phase 6: Full Application Deployment

### **Next Steps:**
1. **Immediate**: Terminate current environments and start fresh
2. **Short-term**: Deploy minimal test app to verify basic functionality
3. **Medium-term**: Gradually add complexity and dependencies
4. **Long-term**: Deploy full application with all features

## 🎉 **Expected Outcome**

By following this systematic approach, we should:
1. **Identify the exact failure point** in the deployment process
2. **Resolve each issue incrementally** without introducing new problems
3. **Achieve a stable, working deployment** of the Tubby AI backend
4. **Have a clear understanding** of what was causing the original failures
5. **Establish a reliable deployment process** for future updates

---

**🚀 Ready to begin systematic debugging! 🚀** 