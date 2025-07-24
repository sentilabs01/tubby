from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello World from TubbyAI!'

@app.route('/health')
def health():
    return 'OK'

@app.route('/test')
def test():
    return 'Test endpoint working!'

if __name__ == '__main__':
    # Get port from environment variable (Elastic Beanstalk sets this)
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port) 