#!/usr/bin/env python3
"""
WSGI entry point for the Novak Trading Engine
"""
import os
import sys

# Add the src directory to the Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'src'))

from src.app import app

if __name__ == "__main__":
    app.run() 