#!/bin/bash

echo "Starting Kitchen Assistant Backend..."

# Use fresh_venv (Python 3.13) for FastAPI backend
if [ ! -d "fresh_venv" ]; then
    echo "❌ Virtual environment 'fresh_venv' not found!"
    echo "Please create it first:"
    echo "  python3.13 -m venv fresh_venv"
    echo "  source fresh_venv/bin/activate"
    echo "  pip install -r requirements.txt"
    exit 1
fi

# Activate virtual environment
echo "Activating fresh_venv (Python 3.13)..."
source fresh_venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt

# Start the server
echo "Starting FastAPI server on http://localhost:8000"
echo "API documentation available at http://localhost:8000/docs"
uvicorn main:app --reload --host 0.0.0.0 --port 8000