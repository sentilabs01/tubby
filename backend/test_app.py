from flask import Flask, jsonify

app = Flask(__name__)

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
    print("Starting minimal Flask test app...")
    print("Routes:")
    for rule in app.url_map.iter_rules():
        print(f"  {rule.rule} -> {rule.endpoint}")
    app.run(host='127.0.0.1', port=5004, debug=True) 