from flask import Flask, jsonify
from flask_cors import CORS
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv('.env')

app = Flask(__name__)
CORS(app, origins=['http://localhost:3001'], supports_credentials=True)

@app.route('/')
def home():
    return "Hello World!"

@app.route('/ping')
def ping():
    return "pong"

@app.route('/test')
def test():
    return jsonify({"message": "Test endpoint working!"})

# Test service initialization
print("🔧 Testing service initialization...")

try:
    from supabase_client import supabase_manager
    print("✅ Supabase client imported")
except Exception as e:
    print(f"❌ Supabase client failed: {e}")

try:
    from services.oauth_service import OAuthService
    print("🔧 Initializing OAuth service...")
    oauth_service = OAuthService()
    print("✅ OAuth service initialized")
except Exception as e:
    print(f"❌ OAuth service failed: {e}")

try:
    from services.user_service import UserService
    print("🔧 Initializing User service...")
    user_service = UserService()
    print("✅ User service initialized")
except Exception as e:
    print(f"❌ User service failed: {e}")

try:
    from services.stripe_service import StripeService
    print("🔧 Initializing Stripe service...")
    stripe_service = StripeService()
    print("✅ Stripe service initialized")
except Exception as e:
    print(f"❌ Stripe service failed: {e}")

# Test Flask-SocketIO
try:
    from flask_socketio import SocketIO
    print("🔧 Testing Flask-SocketIO...")
    socketio = SocketIO(app, cors_allowed_origins="*", async_mode="threading")
    print("✅ Flask-SocketIO initialized")
except Exception as e:
    print(f"❌ Flask-SocketIO failed: {e}")

if __name__ == '__main__':
    print("Starting step 2 Flask test app...")
    print("Routes:")
    for rule in app.url_map.iter_rules():
        print(f"  {rule.rule} -> {rule.endpoint}")
    app.run(host='127.0.0.1', port=5004, debug=True) 