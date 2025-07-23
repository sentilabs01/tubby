# 📱 Mobile Testing Configuration

## 🚀 Quick Setup for Mobile Testing

### Option 1: Local Network Testing (Recommended for Development)

**Your Computer's IP Address**: `192.168.4.22`

**Frontend (React)**: 
- URL: `http://192.168.4.22:3001`
- Status: ✅ Running with `--host` flag

**Backend (Flask)**:
- URL: `http://192.168.4.22:5004`
- Status: ✅ Running on port 5004

### 📱 How to Test on Mobile:

1. **Make sure your mobile device is on the same WiFi network** as your computer
2. **Open your mobile browser** and go to: `http://192.168.4.22:3001`
3. **The frontend will automatically connect** to the backend at `http://192.168.4.22:5004`

### ⚙️ Environment Variables for Local Testing:

If you need to test with local backend, update your `.env` file:

```env
VITE_API_URL=http://192.168.4.22:5004
```

### 🔧 Alternative: Production Deployment

For production testing, you should deploy the backend to Amplify:

1. **Frontend**: Already deployed at `https://tubbyai.com`
2. **Backend**: Needs to be deployed to Amplify backend environment
3. **Environment Variables**: Already configured for production

### 🚨 Important Notes:

- **Local testing**: Only works when mobile and computer are on same network
- **Production testing**: Works from anywhere, but requires backend deployment
- **OAuth callbacks**: May need to be configured for your local IP in development

### 🔍 Troubleshooting:

If mobile can't connect:
1. Check Windows Firewall settings
2. Ensure both devices are on same WiFi
3. Try using your computer's IP address instead of localhost 