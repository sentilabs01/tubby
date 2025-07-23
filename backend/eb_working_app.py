from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello from EB working app!'

@app.route('/health')
def health():
    return 'OK'

@app.route('/test')
def test():
    return 'Test endpoint working!'

@app.route('/debug')
def debug():
    return f'Debug info: PORT={os.environ.get("PORT", "Not set")}'

if __name__ == '__main__':
    # Elastic Beanstalk sets PORT environment variable
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False) 