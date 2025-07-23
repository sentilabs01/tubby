from flask import Flask, jsonify
from flask_cors import CORS
from flask_socketio import SocketIO
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv('.env')

app = Flask(__name__)
app.config['SECRET_KEY'] = os.getenv('SECRET_KEY', 'dev-secret-key')

# Configure CORS
CORS(app, origins=['http://localhost:3001'], supports_credentials=True)

# Initialize SocketIO BEFORE routes
socketio = SocketIO(app, cors_allowed_origins="*", async_mode="threading")

# Initialize services
print("🔧 Initializing services...")
try:
    from services.oauth_service import OAuthService
    from services.user_service import UserService
    from services.stripe_service import StripeService
    
    oauth_service = OAuthService()
    user_service = UserService()
    stripe_service = StripeService()
    print("✅ All services initialized")
except Exception as e:
    print(f"❌ Service initialization failed: {e}")

# Define routes AFTER everything else
@app.route('/')
def home():
    return "Hello World!"

@app.route('/ping')
def ping():
    return "pong"

@app.route('/test')
def test():
    return jsonify({"message": "Test endpoint working!"})

if __name__ == '__main__':
    print("Starting step 3 Flask test app...")
    print("Routes:")
    for rule in app.url_map.iter_rules():
        print(f"  {rule.rule} -> {rule.endpoint}")
    app.run(host='127.0.0.1', port=5004, debug=True) 