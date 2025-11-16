"""
API Integration Tests for Kitchen Assistant Backend
"""
import pytest
from fastapi.testclient import TestClient
from PIL import Image
import io

def test_root_endpoint(client):
    """Test root endpoint returns correct info"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "message" in data
    assert data["message"] == "Kitchen Assistant API"

def test_health_endpoint(client):
    """Test health check endpoint"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "healthy"
    assert "yolo_loaded" in data
    assert "ollama_available" in data

def test_detect_endpoint_with_valid_image(client):
    """Test detection endpoint with valid image"""
    # Create a simple test image
    img = Image.new('RGB', (640, 640), color='white')
    img_bytes = io.BytesIO()
    img.save(img_bytes, format='JPEG')
    img_bytes.seek(0)
    
    response = client.post(
        "/api/detect",
        files={"image": ("test.jpg", img_bytes, "image/jpeg")}
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "ingredients" in data
    assert "confidence" in data
    assert "processing_time" in data
    assert isinstance(data["ingredients"], list)
    assert isinstance(data["confidence"], list)
    assert isinstance(data["processing_time"], float)

def test_detect_endpoint_without_image(client):
    """Test detection endpoint without image"""
    response = client.post("/api/detect")
    assert response.status_code == 422  # Unprocessable Entity

def test_detect_endpoint_with_invalid_file(client):
    """Test detection endpoint with non-image file"""
    # Create a text file
    text_bytes = io.BytesIO(b"This is not an image")
    
    response = client.post(
        "/api/detect",
        files={"image": ("test.txt", text_bytes, "text/plain")}
    )
    
    assert response.status_code == 400
    data = response.json()
    assert "detail" in data

def test_recipe_endpoint_with_valid_request(client):
    """Test recipe generation endpoint"""
    request_data = {
        "ingredients": ["chicken", "tomato", "cheese"],
        "mealCraving": "pasta",
        "dietaryRestrictions": [],
        "preferredCuisine": "Italian"
    }
    
    response = client.post("/api/recipes", json=request_data)
    
    # May succeed or fail depending on Ollama availability
    if response.status_code == 200:
        data = response.json()
        assert "title" in data
        assert "ingredients" in data
        assert "instructions" in data
    else:
        # Expected if Ollama is not running
        assert response.status_code in [500, 503]

def test_recipe_endpoint_without_ingredients(client):
    """Test recipe endpoint without required fields"""
    request_data = {
        "mealCraving": "pasta"
    }
    
    response = client.post("/api/recipes", json=request_data)
    assert response.status_code == 422  # Validation error

