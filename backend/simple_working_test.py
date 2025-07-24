from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello from simple working test!'

@app.route('/health')
def health():
    return 'OK'

@app.route('/test')
def test():
    return 'Test endpoint working!'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000) 