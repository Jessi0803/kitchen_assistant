# Edge-AI Kitchen Assistant

1. built a complete frontend-backend separation architecture for a Kitchen Assistant App: an iOS SwiftUI frontend with image upload, ingredient detection, and recipe display features.

2. paired with a Python FastAPI backend including image processing and recipe generation endpoints. 

3. A fully offline macOS companion that takes one photo of your fridge, combines it with whatever meal you're craving, and instantly delivers a step-by-step recipe.

4. using Mock AI services to simulate YOLO ingredient detection and LLM recipe generation


## Current Architecture

### System Overview
```
iOS SwiftUI App ← REST API → FastAPI Backend (localhost:8000)
                               ↓
                            Yolonv8 for ingredient detection
                            Mock AI Services for recipe generation
```

### Complete Frontend-Backend Architecture Diagram
![App Architecture](image.png)

## Current Implementation Overview

### Complete Frontend-Backend Architecture
- **Native iOS SwiftUI App** with full user interface
- **Python FastAPI Backend** with RESTful API services  
- **End-to-End Data Flow** from camera capture to recipe display

## Next Development Steps

### Local AI Integration
- **iOS Core ML Integration**: fintune Yolov8n on food101 dataset
- **Local LLM Service**: Integrate lightweight language model for basic recipe generation


## YOLO Model Training Process

### Fine-tuning Pipeline
The YOLO model undergoes a comprehensive training process to learn food detection:

1. **Image Input → YOLO Model**
   - Raw images are preprocessed and fed into the YOLOv8n architecture
   - Feature extraction through convolutional layers at multiple scales

2. **Model Output → Multiple Candidate Bounding Boxes + Class Probabilities**
   - Model generates thousands of candidate detections
   - Each detection includes bounding box coordinates and class probabilities
   - Raw predictions need filtering and refinement

3. **Non-Maximum Suppression → Filter Best Bounding Boxes**
   - Removes overlapping detections for the same object
   - Keeps only the highest confidence detection per object
   - Uses IoU (Intersection over Union) threshold for filtering

4. **Calculate Loss → Box + Classification + Distribution Focal Loss**
   - **Box Loss**: Measures accuracy of bounding box coordinates
   - **Classification Loss**: Measures accuracy of class predictions  
   - **Distribution Focal Loss**: Advanced loss for precise coordinate regression
   - Total loss combines all three with weights: box=7.5, cls=0.5, dfl=1.5

5. **Backpropagation → Update Model Parameters**
   - Gradients are calculated for all model parameters
   - AdamW optimizer updates weights with learning rate scheduling
   - L2 regularization prevents overfitting

6. **Repeat Training → Until Convergence**
   - Process continues for multiple epochs (2-3 for quick training)
   - Model performance improves with each iteration
   - Early stopping prevents overfitting

### Data Types Flow
**User Upload**: UIImage → Data (JPEG/PNG)  
*Example: User selects photo from camera roll → 2.3MB JPEG data*

**Backend**: UploadFile → bytes → PIL.Image  
*Example: FastAPI receives multipart file → 2,300,000 bytes → PIL Image object (640×480 RGB)*

**YOLO Input**: PIL.Image  
*Example: PIL Image (640×480×3) ready for model inference*

**YOLO Output**: List[Results] with boxes, confidence, classes  
*Example: 3 detections with boxes=[(100,50,200,150), (300,200,400,300)], conf=[0.85, 0.92], cls=[0, 15]*

**Processing**: Filter food classes, extract coordinates  
*Example: Filter to food classes only → ["Apple", "Banana"] with confidence [0.85, 0.92]*

**Response**: DetectionResponse (ingredients, confidence, time)  
*Example: {"ingredients": ["Apple", "Banana"], "confidence": [0.85, 0.92], "processing_time": 1.2}*

**iOS**: [String] food names, [Double] confidence scores  
*Example: ["Apple", "Banana"] and [0.85, 0.92] displayed in UI*

## Quick Start Guide

### 1. Start the Backend Server
```bash
cd backend
source venv/bin/activate  # Activate virtual environment
python main.py            # Start FastAPI server
```
Server will start at `http://localhost:8000`

### 1.1 FastAPI quick refs

- **Base URL**: `http://localhost:8000`
- **Interactive docs (Swagger UI)**: `http://localhost:8000/docs`
- **OpenAPI schema**: `http://localhost:8000/openapi.json`

Call the detect endpoint with curl (multipart image upload):
```bash
curl -X POST \
  -F "image=@test.png" \
  http://localhost:8000/api/detect
```

Tip: to use your fine‑tuned model, update `backend/main.py` model path to `food101_training/food101_yolov8n/weights/best.pt` (or `yolov8n_food101_finetuned.pt`).


### 2. Run iOS App
```bash
open ios-app/KitchenAssistant.xcodeproj
```
Select iOS simulator in Xcode and press Play to run

### 3. Test Complete Workflow
1. Open app in iOS simulator
2. Switch to "Scan Fridge" tab
3. Select or capture a photo
4. Enter desired meal type
5. View generated complete recipe




