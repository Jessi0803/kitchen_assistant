#!/usr/bin/env python3
"""
Test script for Kitchen Assistant API
Run this to test the backend endpoints
"""

import requests
import json
import time
from io import BytesIO
from PIL import Image

# API base URL
BASE_URL = "http://localhost:8000"

def test_health_check():
    """Test the health check endpoint"""
    print("🔍 Testing health check...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print("✅ Health check passed:", response.json())
            return True
        else:
            print("❌ Health check failed:", response.status_code)
            return False
    except requests.exceptions.RequestException as e:
        print("❌ Health check failed:", str(e))
        return False

def create_test_image():
    """Create a simple test image"""
    img = Image.new('RGB', (300, 300), color='lightgreen')
    img_buffer = BytesIO()
    img.save(img_buffer, format='JPEG')
    img_buffer.seek(0)
    return img_buffer

def test_ingredient_detection():
    """Test ingredient detection endpoint"""
    print("\n🔍 Testing ingredient detection...")
    try:
        # Create test image
        test_image = create_test_image()
        
        files = {'image': ('test_fridge.jpg', test_image, 'image/jpeg')}
        response = requests.post(f"{BASE_URL}/api/detect", files=files)
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Ingredient detection successful:")
            print(f"   Detected ingredients: {data['ingredients']}")
            print(f"   Confidence scores: {data['confidence']}")
            print(f"   Processing time: {data['processing_time']:.2f}s")
            return data['ingredients']
        else:
            print("❌ Ingredient detection failed:", response.status_code, response.text)
            return None
    except requests.exceptions.RequestException as e:
        print("❌ Ingredient detection failed:", str(e))
        return None

def test_recipe_generation(ingredients):
    """Test recipe generation endpoint"""
    print("\n🔍 Testing recipe generation...")
    try:
        payload = {
            "ingredients": ingredients or ["tomato", "cheese", "basil"],
            "meal_craving": "pasta",
            "dietary_restrictions": [],
            "preferred_cuisine": "Italian"
        }
        
        response = requests.post(
            f"{BASE_URL}/api/recipes", 
            json=payload,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status_code == 200:
            recipe = response.json()
            print("✅ Recipe generation successful:")
            print(f"   Title: {recipe['title']}")
            print(f"   Description: {recipe['description']}")
            print(f"   Prep time: {recipe['prep_time']} min")
            print(f"   Cook time: {recipe['cook_time']} min")
            print(f"   Servings: {recipe['servings']}")
            print(f"   Difficulty: {recipe['difficulty']}")
            print(f"   Ingredients count: {len(recipe['ingredients'])}")
            print(f"   Instructions count: {len(recipe['instructions'])}")
            return True
        else:
            print("❌ Recipe generation failed:", response.status_code, response.text)
            return False
    except requests.exceptions.RequestException as e:
        print("❌ Recipe generation failed:", str(e))
        return False

def test_api_docs():
    """Test API documentation endpoint"""
    print("\n🔍 Testing API documentation...")
    try:
        response = requests.get(f"{BASE_URL}/docs")
        if response.status_code == 200:
            print("✅ API documentation accessible at http://localhost:8000/docs")
            return True
        else:
            print("❌ API documentation failed:", response.status_code)
            return False
    except requests.exceptions.RequestException as e:
        print("❌ API documentation failed:", str(e))
        return False

def main():
    """Run all API tests"""
    print("🚀 Kitchen Assistant API Test Suite")
    print("=" * 50)
    
    # Test health check first
    if not test_health_check():
        print("\n❌ Backend server is not running!")
        print("💡 Please start the backend with: cd backend && ./start.sh")
        return
    
    # Test ingredient detection
    ingredients = test_ingredient_detection()
    
    # Test recipe generation
    test_recipe_generation(ingredients)
    
    # Test API docs
    test_api_docs()
    
    print("\n" + "=" * 50)
    print("🎉 API testing completed!")
    print("💡 Visit http://localhost:8000/docs for interactive API documentation")

if __name__ == "__main__":
    main()