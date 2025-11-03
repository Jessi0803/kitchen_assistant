"""
Kitchen Assistant Backend - Docker Version (YOLO Detection Service Only)

This simplified version excludes Ollama/LLM dependencies for deployment on AWS EC2 Free Tier.
Recipe generation is handled by MLX on-device (iPhone).
"""

from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List
import time
import io
import os
from PIL import Image
from ultralytics import YOLO

app = FastAPI(
    title="Kitchen Assistant API - YOLO Detection Service",
    description="Ingredient detection service using fine-tuned YOLOv8n",
    version="1.0.0-docker"
)

# Initialize YOLO model
model_path = os.path.join(os.path.dirname(__file__), 'best.pt')
if not os.path.exists(model_path):
    model_path = 'best.pt'

try:
    yolo_model = YOLO(model_path)
    print("✅ YOLO model loaded successfully")
except Exception as e:
    print(f"❌ Failed to load YOLO model: {e}")
    yolo_model = None

# Mapping for fine-tuned food detection model
YOLO_TO_FOOD_MAPPING = {
    'beef': 'Beef',
    'pork': 'Pork',
    'chicken': 'Chicken',
    'butter': 'Butter',
    'cheese': 'Cheese',
    'milk': 'Milk',
    'broccoli': 'Broccoli',
    'carrot': 'Carrot',
    'cucumber': 'Cucumber',
    'lettuce': 'Lettuce',
    'tomato': 'Tomato'
}

# CORS middleware for iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class DetectionResponse(BaseModel):
    ingredients: List[str]
    confidence: List[float]
    processing_time: float

@app.get("/")
async def root():
    return {
        "message": "Kitchen Assistant API - YOLO Detection Service",
        "version": "1.0.0-docker",
        "status": "running",
        "services": {
            "detection": "available",
            "recipe_generation": "handled by iOS MLX on-device"
        }
    }

@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "yolo_model_loaded": yolo_model is not None
    }

@app.post("/api/detect", response_model=DetectionResponse)
async def detect_ingredients(image: UploadFile = File(...)):
    """
    Detect ingredients in uploaded fridge image using fine-tuned YOLOv8n model.
    """
    start_time = time.time()

    # Validate image file
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    if yolo_model is None:
        raise HTTPException(
            status_code=503,
            detail="YOLO model not loaded. Service unavailable."
        )

    try:
        # Read and validate image
        image_data = await image.read()
        pil_image = Image.open(io.BytesIO(image_data))

        # Run YOLO inference (CPU mode on AWS t2.micro)
        results = yolo_model(pil_image, conf=0.1)

        detected_ingredients = []
        confidence_scores = []

        # Process YOLO results
        for result in results:
            for box in result.boxes:
                if box.conf is not None and box.cls is not None:
                    confidence = float(box.conf.cpu().numpy())
                    class_id = int(box.cls.cpu().numpy())
                    class_name = yolo_model.names[class_id].lower()

                    # Check if detected class is food-related
                    if class_name in YOLO_TO_FOOD_MAPPING:
                        food_name = YOLO_TO_FOOD_MAPPING[class_name]
                        if food_name not in detected_ingredients:  # Avoid duplicates
                            detected_ingredients.append(food_name)
                            confidence_scores.append(round(confidence, 2))

        # If no food items detected
        if not detected_ingredients:
            raise HTTPException(
                status_code=404,
                detail="No food items detected in the image. Please try a clearer photo."
            )

        processing_time = time.time() - start_time

        print(f"🔍 Detected {len(detected_ingredients)} food items: {detected_ingredients}")
        print(f"⏱️  Processing time: {processing_time:.2f}s")

        return DetectionResponse(
            ingredients=detected_ingredients,
            confidence=confidence_scores,
            processing_time=processing_time
        )

    except HTTPException:
        raise
    except Exception as e:
        print(f"❌ YOLO detection failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Detection failed: {str(e)}"
        )

# Note: Recipe generation endpoint is removed
# iOS app will use MLX on-device for recipe generation
