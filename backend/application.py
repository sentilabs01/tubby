# Import the Flask app from app.py
from app import app

# This file exists to satisfy Elastic Beanstalk's default configuration
# which looks for 'application' module by default
application = app 