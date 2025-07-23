# 🔑 API Setup Guide - AI Agent Communication Platform

## 🎯 **Required API Keys**

### **Google API Key (Required for Gemini CLI)**

#### **Step 1: Get Google API Key**
1. **Visit**: https://makersuite.google.com/app/apikey
2. **Sign in** with your Google account
3. **Click** "Create API Key"
4. **Copy** the generated API key

#### **Step 2: Set Environment Variable**

**Option A: Create .env file**
```bash
# Create .env file in project root
GOOGLE_API_KEY=your_google_api_key_here
ANTHROPIC_API_KEY=your_anthropic_api_key_here  # Optional for Claude Code
```

**Option B: Set in PowerShell**
```powershell
$env:GOOGLE_API_KEY="your_google_api_key_here"
```

**Option C: Set in docker-compose.yml**
```yaml
environment:
  - GOOGLE_API_KEY=${GOOGLE_API_KEY}
```

### **Anthropic API Key (Optional for Claude Code)**

#### **Step 1: Get Anthropic API Key**
1. **Visit**: https://console.anthropic.com/
2. **Sign up/Login** to your account
3. **Go to** API Keys section
4. **Create** a new API key
5. **Copy** the generated key

#### **Step 2: Set Environment Variable**
```bash
ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

## 🚀 **Quick Setup**

### **1. Create .env file**
```bash
# In your project root directory
echo "GOOGLE_API_KEY=your_google_api_key_here" > .env
echo "ANTHROPIC_API_KEY=your_anthropic_api_key_here" >> .env
```

### **2. Restart containers**
```bash
docker-compose down
docker-compose up --build -d
```

### **3. Test the setup**
```bash
# Test Gemini CLI
gemini --prompt "Hello, how are you?"

# Test Claude Code
claude --help
```

## 🎯 **What Each API Key Does**

### **Google API Key** 🔑
- **Required for**: Gemini CLI functionality
- **What it enables**: AI chat responses, code generation
- **Without it**: Shows help text only

### **Anthropic API Key** 🔑
- **Required for**: Claude Code authentication
- **What it enables**: Interactive coding sessions
- **Without it**: Limited functionality

## 🔧 **Troubleshooting**

### **"Unknown arguments" Error**
- **Cause**: Missing API key
- **Solution**: Set GOOGLE_API_KEY environment variable

### **"Authentication required" Error**
- **Cause**: Missing or invalid API key
- **Solution**: Check API key format and permissions

### **"Rate limit exceeded" Error**
- **Cause**: API usage limits
- **Solution**: Wait or upgrade API plan

## 📋 **Environment Variables Summary**

```bash
# Required for Gemini CLI
GOOGLE_API_KEY=your_google_api_key_here

# Optional for Claude Code
ANTHROPIC_API_KEY=your_anthropic_api_key_here

# Optional for additional features
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_key
OPENAI_API_KEY=your_openai_key
```

## 🎉 **After Setup**

Once you have the API keys set up:

### **Gemini CLI Terminal:**
```bash
gemini --prompt "What kind of app is this?"
# Should return: AI response about your platform

gemini --prompt "Explain quantum computing"
# Should return: Detailed explanation
```

### **Claude Code Terminal:**
```bash
claude --help
# Should show: Claude Code help with authentication

claude code "print('Hello World')"
# Should return: Python code execution
```

## 🔒 **Security Notes**

- **Never commit** API keys to version control
- **Use .env files** for local development
- **Use secrets management** for production
- **Rotate keys** regularly for security

Your platform will be fully functional once you add the Google API key! 🚀 