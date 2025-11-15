"""
Pytest configuration and fixtures
"""
import pytest
from fastapi.testclient import TestClient
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from main import app

@pytest.fixture
def client():
    """FastAPI test client fixture"""
    return TestClient(app)

@pytest.fixture
def sample_image_path():
    """Path to sample test image"""
    return os.path.join(os.path.dirname(__file__), 'fixtures', 'sample_food.jpg')

