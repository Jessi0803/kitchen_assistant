"""
YOLO Model Inference Tests
"""
import pytest
from PIL import Image
import numpy as np
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

try:
    from ultralytics import YOLO
    YOLO_AVAILABLE = True
except ImportError:
    YOLO_AVAILABLE = False

@pytest.mark.skipif(not YOLO_AVAILABLE, reason="YOLOv8 not installed")
def test_yolo_model_loads():
    """Test that YOLO model can be loaded"""
    model_paths = ['best.pt', 'yolov8n_merged_food_cpu_aug_finetuned.pt', 'yolov8n.pt']
    
    model_loaded = False
    for model_path in model_paths:
        if os.path.exists(model_path):
            try:
                model = YOLO(model_path)
                model_loaded = True
                break
            except Exception as e:
                continue
    
    assert model_loaded, "Could not load any YOLO model"

@pytest.mark.skipif(not YOLO_AVAILABLE, reason="YOLOv8 not installed")
def test_yolo_inference_on_simple_image():
    """Test YOLO inference on a simple test image"""
    model_paths = ['best.pt', 'yolov8n_merged_food_cpu_aug_finetuned.pt', 'yolov8n.pt']
    
    model = None
    for model_path in model_paths:
        if os.path.exists(model_path):
            try:
                model = YOLO(model_path)
                break
            except Exception:
                continue
    
    if model is None:
        pytest.skip("No YOLO model available")
    
    # Create a simple test image
    test_image = Image.new('RGB', (640, 640), color='white')
    
    # Run inference
    results = model(test_image, conf=0.1)
    
    # Basic assertions
    assert results is not None
    assert len(results) > 0
    assert hasattr(results[0], 'boxes')

@pytest.mark.skipif(not YOLO_AVAILABLE, reason="YOLOv8 not installed")
def test_yolo_class_names():
    """Test that YOLO model has expected class names"""
    model_paths = ['best.pt', 'yolov8n_merged_food_cpu_aug_finetuned.pt']
    
    expected_classes = ['beef', 'pork', 'chicken', 'butter', 'cheese', 'milk',
                       'broccoli', 'carrot', 'cucumber', 'lettuce', 'tomato']
    
    model = None
    for model_path in model_paths:
        if os.path.exists(model_path):
            try:
                model = YOLO(model_path)
                break
            except Exception:
                continue
    
    if model is None:
        pytest.skip("No fine-tuned YOLO model available")
    
    # Check that model has class names
    assert hasattr(model, 'names')
    assert isinstance(model.names, dict)
    
    # Check for expected food classes (may have more or less)
    model_class_names = [name.lower() for name in model.names.values()]
    
    # At least some expected classes should be present
    found_classes = [cls for cls in expected_classes if cls in model_class_names]
    assert len(found_classes) > 0, f"Expected classes not found. Model has: {model_class_names}"

def test_yolo_food_mapping():
    """Test that food mapping dictionary is correctly defined"""
    from main import YOLO_TO_FOOD_MAPPING
    
    assert isinstance(YOLO_TO_FOOD_MAPPING, dict)
    assert len(YOLO_TO_FOOD_MAPPING) > 0
    
    # Check expected food items
    expected_foods = ['beef', 'pork', 'chicken', 'butter', 'cheese', 'milk',
                     'broccoli', 'carrot', 'cucumber', 'lettuce', 'tomato']
    
    for food in expected_foods:
        assert food in YOLO_TO_FOOD_MAPPING, f"{food} not in food mapping"

