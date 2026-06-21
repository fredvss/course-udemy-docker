#!/usr/bin/env python3

from flask import Flask
from os import getenv
from requests import get

import json

app = Flask(__name__)

@app.route('/')
def hello():
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Health Check</title>
    </head>
    <body>
        <h1>Health Check</h1>
        <p>Service is running.</p>
    </body>
    </html>
    """

@app.route('/health')
def health():
    # Check if the service is healthy
    health_status = {
        "status": "healthy",
        "version": "1.0.0"
    }
    return json.dumps(health_status), 503, {'Content-Type': 'application/json'}

if __name__ == '__main__':
    port = int(getenv('PORT', 5000))
    app.run(host='0.0.0.0', port=port)