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
                            Fine-tuned Yolonv8 for ingredient detection
                            Mock AI Services for recipe generation
```

### Complete Frontend-Backend Architecture Diagram
![App Architecture](image.png)

## Current Implementation Overview

### Complete Frontend-Backend Architecture
- **Native iOS SwiftUI App** with full user interface
- **Python FastAPI Backend** with RESTful API services  
- **End-to-End Data Flow** from camera capture to recipe display


## Finetuning YOLOv8n (CPU)
I fine-tune `yolov8n.pt` on my food dataset using a CPU.

### How to run
```bash
cd backend
source fresh_venv/bin/activate
python3 fine_tune_yolo_cpu_aug.py
```

### Training process
- device: CPU (stable on this machine)
- epochs: 30, batch: 8, imgsz: 640, workers: 2
- optimizer: AdamW (lr0=0.0005, weight_decay=0.0005, warmup_epochs=2)
- augmentations: moderate (hsv_h=0.01, hsv_s=0.3, hsv_v=0.2, fliplr=0.5, mosaic=0.3, mixup=0.0)
- val/plots: enabled; metrics and plots are saved every run
- outputs: `kitchen_assistant_training_cpu_aug/merged_food_yolov8n_cpu_aug_30epochs/`

#### Data augmentation (on-the-fly)
- Augmentations are applied per batch/epoch in memory; original files are not changed.
- Each batch re-samples transforms (flip, color jitter, scale, translate, mosaic/mixup, etc.). Images are not "flipped back"—the change is one-time for that batch.
- Labels (bounding boxes) are transformed consistently with the image.
- Validation and inference avoid strong augmentations (typically only resize/letterbox).

### Training Results
- Overall metrics and losses over epochs:
![YOLO Training Results](backend/kitchen_assistant_training_cpu_aug/merged_food_yolov8n_cpu_aug_30epochs/results.png)

- Class-wise performance (normalized confusion matrix):
![Confusion Matrix (Normalized)](backend/kitchen_assistant_training_cpu_aug/merged_food_yolov8n_cpu_aug_30epochs/confusion_matrix_normalized.png)

Short summary:
- Final (epoch 30) precision ≈ 0.865, recall ≈ 0.857
- Final mAP50 ≈ 0.881, mAP50-95 ≈ 0.685
- Train/val losses steadily decreased and plateaued near the end, indicating stable convergence


### Losses (what they mean)
- box_loss: bounding box regression loss. Measures how well predicted boxes overlap with ground truth (IoU-based). Lower is better localization.
- cls_loss: classification loss. Measures how well the model predicts the correct class probabilities (BCE/Logits). Lower is better classification.
- dfl_loss: Distribution Focal Loss. Models box coordinates as discrete distributions for finer localization. Lower is sharper, more precise box edges.

Tips: Typically all three decrease together. As box_loss and dfl_loss drop, mAP50-95 improves; as cls_loss improves, precision/recall increase.


## Dataset
I use `datasets/merged_food_dataset` with 11 classes: 
`beef, pork, chicken, butter, cheese, milk, broccoli, carrot, cucumber, lettuce, tomato`.


## Why not MPS (Apple Silicon GPU)
I attempted MPS training on Python 3.13 with PyTorch ≥2.6 and Ultralytics 8.x, but ran into recurring issues:
- Negative-dimension/validation errors on MPS during training/metrics
- Version constraints on Python 3.13 limit known good torch+ultralytics combos
- `torch.load` security change (`weights_only=True`) required special handling

CPU training is stable and produced strong results (e.g., good mAP50). If I must use MPS, a more compatible stack is Python 3.11 + torch 2.1.0 + ultralytics 8.0.120 with conservative settings (amp=False, small batch/imgsz, minimal augments) and validating on CPU — but this requires a separate environment.



### Data Types Flow
**User Upload**: UIImage → Data (JPEG/PNG)  
*Example: User selects photo from camera roll → 2.3MB JPEG data*

**Backend**: UploadFile → bytes → PIL.Image  
*Example: FastAPI receives multipart file → 2,300,000 bytes → PIL Image object (640×480 RGB)*

**YOLO Input**: PIL.Image  
*Example: PIL Image (640×480×3) ready for model inference*

**YOLO Output**: List[Results] with boxes, confidence, classes  
*Example: 2 detections with boxes=[(90,40,210,160), (300,200,420,320)], conf=[0.91, 0.84], cls=["tomato", "cheese"]*

**Processing**: Map model class names → human-friendly names, keep confidences  
*Example: {ingredients: ["Tomato", "Cheese"], confidence: [0.91, 0.84]}*

**Response**: DetectionResponse (ingredients, confidence, time)  
*Example: {"ingredients": ["Tomato", "Cheese"], "confidence": [0.91, 0.84], "processing_time": 1.2}*

**iOS**: [String] food names, [Double] confidence scores  
*Example: ["Tomato", "Cheese"] and [0.91, 0.84] displayed in UI*

## Quick Start Guide

### 1. Start the Backend Server
```bash
cd backend
source venv/bin/activate  # Activate virtual environment
python main.py            # Start FastAPI server
```
Server will start at `http://localhost:8000`



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




## Server vs Local Inference Architecture

### Overview
This project supports both server-side and local inference for ingredient detection, each with distinct advantages and implementation approaches.

### Server-Side Inference (Python + PyTorch)

#### Environment
- **Platform**: Linux/macOS server
- **Framework**: Python + PyTorch + ultralytics
- **Model Format**: `.pt` (PyTorch)
- **Deployment**: Cloud server or localhost

#### Implementation
```python
# Server-side: Simple 3-line implementation
from ultralytics import YOLO

model = YOLO('yolov8n_merged_food_cpu_aug_finetuned.pt')
results = model(image)  # Automatic preprocessing, inference, and postprocessing
ingredients = [model.names[int(box.cls)] for box in results[0].boxes]
```

#### Advantages
- ✅ **Simple Development**: Only 3 lines of code
- ✅ **Complete Framework**: ultralytics handles all processing automatically
- ✅ **High Performance**: Multi-core CPU, unlimited memory
- ✅ **Easy Maintenance**: Replace model files, redeploy service
- ✅ **Full Features**: Automatic NMS, preprocessing, postprocessing

#### Processing Flow
1. **Image Loading**: PIL automatically loads and validates images
2. **Preprocessing**: YOLO automatically resizes, normalizes, and converts to tensors
3. **Inference**: PyTorch model runs on server hardware
4. **Postprocessing**: YOLO automatically parses outputs, applies NMS, filters results

### Local Inference (iOS + ONNX)

#### Environment
- **Platform**: iOS (iPhone/iPad)
- **Framework**: Swift + ONNX Runtime
- **Model Format**: `.onnx` (converted from PyTorch)
- **Deployment**: iOS App Bundle

#### Implementation
```swift
// Local-side: 100+ lines of manual implementation
class LocalInferenceService {
    // Manual preprocessing (30+ lines)
    private func preprocessImageToONNX(_ image: UIImage) -> ORTValue
    
    // Manual inference (5 lines)
    let outputs = try session.run(withInputs: inputs, outputNames: ["output0"])
    
    // Manual postprocessing (50+ lines)
    private func postProcessYOLOResults(_ outputTensor: ORTValue) -> ([String], [Double])
}
```

#### Manual Processing Steps

**1. Preprocessing (Manual Implementation)**
```swift
// Manual image preprocessing
private func preprocessImageToONNX(_ image: UIImage) throws -> ORTValue {
    // 1. Manual resize to 640x640
    guard let resizedImage = image.resized(to: CGSize(width: 640, height: 640)) else {
        throw LocalInferenceError.imageProcessingFailed
    }
    
    // 2. Manual RGB conversion
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: &pixelData, width: width, height: height, ...)
    
    // 3. Manual normalization (0-255 → 0-1)
    for channel in 0..<3 {
        for y in 0..<height {
            for x in 0..<width {
                let pixelValue = Float(pixelData[pixelIndex]) / 255.0
                floatPixels.append(pixelValue)
            }
        }
    }
    
    // 4. Manual tensor creation
    return try ORTValue(tensorData: data, elementType: .float, shape: shape)
}
```

**2. Inference (Manual ONNX Runtime)**
```swift
// Manual ONNX Runtime inference
let inputs: [String: ORTValue] = ["images": inputTensor]
let outputs = try session.run(withInputs: inputs, outputNames: ["output0"])
```

**3. Postprocessing (Manual Implementation)**
```swift
// Manual output parsing and processing
private func postProcessYOLOResults(_ outputTensor: ORTValue) throws -> ([String], [Double]) {
    // 1. Manual output format parsing [1, 16, 8400]
    let floatArray = data.withUnsafeBytes { bytes in
        bytes.bindMemory(to: Float.self)
    }
    
    // 2. Manual detection parsing
    for i in 0..<numDetections {
        let objectness = floatArray[4 * numDetections + i]
        
        // 3. Manual class score calculation
        var maxClassScore: Float = 0
        for classIndex in 0..<numClasses {
            let classScore = floatArray[(5 + classIndex) * numDetections + i]
            if classScore > maxClassScore {
                maxClassScore = classScore
                maxClassIndex = classIndex
            }
        }
        
        // 4. Manual confidence calculation
        let finalConfidence = Double(objectness * maxClassScore)
        
        // 5. Manual filtering and NMS
        if finalConfidence >= config.confidenceThreshold {
            // Process detection results...
        }
    }
}
```

#### Advantages
- ✅ **Privacy Protection**: Images never leave the device
- ✅ **Offline Usage**: No internet connection required
- ✅ **Low Operating Cost**: No server maintenance
- ✅ **Fast Response**: No network latency
- ❌ **Complex Development**: 100+ lines of manual implementation
- ❌ **Limited Performance**: Single-core ARM processor
- ❌ **Harder Maintenance**: Requires app updates for model changes

### Accuracy Comparison

#### Theoretical Accuracy
- **Same Model**: Both use identical YOLOv8 model (converted from same `.pt` file)
- **Same Preprocessing**: Both resize to 640x640 and normalize to 0-1 range
- **Same Inference**: Both use the same model weights

#### Practical Differences
| Aspect | Server-Side | Local-Side | Impact on Accuracy |
|--------|-------------|------------|-------------------|
| **Image Resizing** | PIL LANCZOS (high quality) | UIImage resize | Minor (1-2%) |
| **Normalization** | PIL automatic | Manual calculation | Minor (1-2%) |
| **Color Space** | PIL automatic RGB | Manual RGB conversion | Minor (1-2%) |
| **NMS Algorithm** | Complete NMS | Simplified NMS | Moderate (3-5%) |
| **Output Parsing** | YOLO automatic | Manual parsing | Minor (1-2%) |

**Expected Accuracy Difference**: 5-10% lower for local inference due to implementation differences.

### Why Manual Implementation is Required

#### iOS Platform Limitations
```swift
// iOS cannot run Python/PyTorch directly
// ❌ Not possible on iOS
import ultralytics
import torch

// ✅ Only available on iOS
import OnnxRuntimeBindings
import CoreML
```

#### Framework Dependencies
| Framework | Server-Side | iOS Local-Side |
|-----------|-------------|----------------|
| **Python** | ✅ Full support | ❌ Not supported |
| **PyTorch** | ✅ Native support | ❌ Not supported |
| **ultralytics** | ✅ Full support | ❌ Not supported |
| **PIL** | ✅ Encapsulated in YOLO | ❌ Manual implementation required |
| **ONNX Runtime** | ⚠️ Optional | ✅ Required |
| **CoreML** | ❌ Not applicable | ✅ Optional |

### Model Conversion Process

#### PyTorch to ONNX Conversion
```python
# Convert PyTorch model to ONNX for iOS
from ultralytics import YOLO

model = YOLO('yolov8n_merged_food_cpu_aug_finetuned.pt')
model.export(
    format='onnx',
    imgsz=640,
    simplify=True,
    opset=12  # Compatible with iOS ONNX Runtime
)
```

#### Output Format
- **PyTorch Output**: `[1, 16, 8400]` (4 bbox + 1 objectness + 11 classes + 1 DFL)
- **ONNX Output**: `[1, 16, 8400]` (same format, different runtime)

### Development Complexity Comparison

| Task | Server-Side | Local-Side |
|------|-------------|------------|
| **Model Loading** | 1 line | 20+ lines |
| **Preprocessing** | Automatic | Manual (30+ lines) |
| **Inference** | Automatic | Manual (5 lines) |
| **Postprocessing** | Automatic | Manual (50+ lines) |
| **Error Handling** | Simple | Complex |
| **Debugging** | Easy | Difficult |

### Usage Scenarios

#### Choose Server-Side When:
- High accuracy is critical
- Processing large batches of images
- Real-time model updates needed
- Privacy is not a major concern
- Stable internet connection available

#### Choose Local-Side When:
- Privacy protection is essential
- Offline usage is required
- No internet connection available
- Low operating costs preferred
- Acceptable to have slightly lower accuracy

## Next Development Steps

### Local AI Integration
- **On-device food detection (ONNX)**: Convert `best.pt` to ONNX, embed in iOS app, and add local inference path
- **Local/Server toggle**: In Settings, allow switching between ONNX (local) and FastAPI (server) for detection
- **Accuracy optimization**: Improve local inference accuracy to match server-side performance
- **Local LLM Service**: Integrate lightweight language model for basic recipe generation