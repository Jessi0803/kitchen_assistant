# Edge-AI Kitchen Assistant

## Project Overview

1. Built a complete frontend-backend separation architecture for a Kitchen Assistant App: an iOS SwiftUI frontend with image upload, ingredient detection, and recipe display features.

2. Paired with a Python FastAPI backend including image processing and recipe generation endpoints.

3. A fully offline macOS companion that takes one photo of your fridge, combines it with whatever meal you're craving, and instantly delivers a step-by-step recipe.

4. Using Fine-tuned YOLOv8n for real ingredient detection and Qwen2.5:3b LLM (via Ollama) for real recipe generation.

---

## Current Architecture

### Triple Architecture Support

This project supports **three deployment modes** that can be toggled via app settings:

#### 1. Server Mode (Cloud Detection + Local Recipe)
```
iOS SwiftUI App
    ↓
    ├─ Detection: REST API → AWS EC2 FastAPI Backend
    │   └─ Fine-tuned YOLOv8n (Docker container)
    │
    └─ Recipe Generation: MLX on-device
        └─ Qwen2.5-0.5B-Instruct-4bit
```

**Configuration**: `useLocalProcessing = false`

**Use Cases**:
- Testing on iOS Simulator (CoreML not available)
- Offloading detection to cloud for older devices
- Hybrid approach: Cloud detection + Local recipe generation

**Settings Display**:
```
🌐 Server Mode
• Detection: Cloud Server, Generation: On-device
• Requires internet for detection
```

---

#### 2. Local Mode (100% Offline)
```
iOS SwiftUI App (Standalone)
    ↓
    ├─ CoreML YOLOv8n (Ingredient Detection)
    │   └─ yolov8n_merged_food_cpu_aug_finetuned.mlmodelc
    │   └─ ~100ms inference on Neural Engine
    │
    └─ MLX LLM (Recipe Generation)
        └─ Qwen2.5-0.5B-Instruct-4bit
        └─ 10-30s generation on GPU
```

**Configuration**: `useLocalProcessing = true` + `useMLXGeneration = true`

**Use Cases**:
- Production deployment (recommended)
- Complete privacy (no data leaves device)
- Offline capability
- No server costs

**Settings Display**:
```
📱 Offline Mode (推薦)
• Detection & Generation: On-device
• 100% offline, completely private
• Requires iOS 16+ (iPhone 12+)
```

---

#### 3. Developer Mode (Local Detection + Ollama Recipe)
```
iOS SwiftUI App
    ↓
    ├─ CoreML YOLOv8n (Ingredient Detection)
    │   └─ yolov8n_merged_food_cpu_aug_finetuned.mlmodelc
    │   └─ ~100ms inference on Neural Engine
    │
    └─ Ollama LLM (Recipe Generation)
        └─ Qwen2.5:3b (on Mac via network)
        └─ 5-10s generation (larger 3B model)
```

**Configuration**: `useLocalProcessing = true` + `useMLXGeneration = false`

**Use Cases**:
- Development and testing
- Better recipe quality (3B vs 0.5B model)
- Faster generation (Mac GPU > iPhone GPU)
- Debugging and experimentation

**Settings Display**:
```
🔧 Developer Mode
• Detection: On-device, Generation: Ollama
• Requires Ollama server on Mac
• For development & testing
```

---

### Extended System Architecture

```
┌───────────────────────────────────────────────────────────────────────────┐
│                       iOS SwiftUI Application                              │
│                      (iPhone 12+, iOS 16.0+)                              │
├───────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────────────────┐ │
│  │  Home   │  │ Camera  │  │ Recipe  │  │      Settings               │ │
│  │  View   │  │  View   │  │  Tab    │  │  ☐ Use Local Processing     │ │
│  └─────────┘  └─────────┘  └─────────┘  │  ☐ Use MLX Generation       │ │
│                                           └─────────────────────────────┘ │
│                                                    │                       │
│                     ┌──────────────────────────────┼───────────────┐      │
│                     │                              │               │      │
└─────────────────────┼──────────────────────────────┼───────────────┼──────┘
                      ▼                              ▼               ▼
              ┌───────────────┐           ┌──────────────┐  ┌──────────────┐
              │ Server Mode   │           │ Local Mode   │  │ Developer    │
              │   (OFF/OFF)   │           │   (ON/ON)    │  │   (ON/OFF)   │
              └───────┬───────┘           └──────┬───────┘  └──────┬───────┘
                      │                          │                  │
═══════════════════════╪══════════════════════════╪══════════════════╪═══════
    DETECTION         │                          │                  │
═══════════════════════╪══════════════════════════╪══════════════════╪═══════
                      │                          │                  │
                      ▼                          ▼                  ▼
            ┌──────────────────┐      ┌──────────────────┐  ┌──────────────┐
            │  AWS EC2 Server  │      │  CoreML YOLO     │  │  CoreML YOLO │
            │  ☁️ FastAPI      │      │  📱 Neural Engine│  │  📱 Neural   │
            │  YOLOv8n PyTorch │      │  yolov8n.mlmodel │  │     Engine   │
            │  ~500ms-1s       │      │  ~100ms          │  │  ~100ms      │
            └────────┬─────────┘      └────────┬─────────┘  └──────┬───────┘
                     │                         │                    │
                     └─────────────────────────┴────────────────────┘
                                               │
                              ✅ Detected Ingredients
                                 ["Tomato", "Cheese", "Chicken"]
                                               │
═══════════════════════════════════════════════╪═══════════════════════════════
    RECIPE GENERATION                          │
═══════════════════════════════════════════════╪═══════════════════════════════
                                               │
                     ┌─────────────────────────┼──────────────────┐
                     │                         │                  │
                     ▼                         ▼                  ▼
          ┌──────────────────┐      ┌──────────────────┐  ┌──────────────────┐
          │  MLX LLM         │      │  MLX LLM         │  │  Ollama LLM      │
          │  📱 On-Device    │      │  📱 On-Device    │  │  🖥️ Mac Server   │
          │  Qwen2.5-0.5B    │      │  Qwen2.5-0.5B    │  │  Qwen2.5:3b      │
          │  4-bit quant     │      │  4-bit quant     │  │  Full precision  │
          │  (~300MB)        │      │  (~300MB)        │  │  (~2GB)          │
          │  10-30s          │      │  10-30s          │  │  5-10s           │
          │  Good Quality    │      │  Good Quality    │  │  Excellent       │
          └────────┬─────────┘      └────────┬─────────┘  └────────┬─────────┘
                   │                         │                      │
                   └─────────────────────────┴──────────────────────┘
                                             │
                              📖 Generated Recipe (JSON)
                                 {title, ingredients, steps...}
                                             │
═══════════════════════════════════════════════════════════════════════════════
                                             ▼
                              ┌──────────────────────────┐
                              │   RecipeDetailView       │
                              │  📖 Title & Description  │
                              │  🥗 Ingredients List     │
                              │  👨‍🍳 Step-by-Step        │
                              │  🏷️  Tags                │
                              │  📊 Nutrition Info       │
                              └──────────────────────────┘
```

**Architecture Overview**:
- **3 Processing Modes**: Server, Local, Developer
- **Flexible Configuration**: User-togglable in Settings
- **Hybrid Approach**: Mix cloud and edge computing
- **Privacy-First**: Local and Developer modes keep all data on-device
- **Performance Optimized**: Neural Engine + GPU acceleration

**Key Features**:
- 🔄 **Mode Switching**: Real-time mode changes via Settings
- 🛡️ **Privacy Options**: Choose between cloud and on-device processing
- ⚡ **Fast Detection**: CoreML achieves ~100ms inference
- 🤖 **Quality Recipes**: Ollama 3B model for best results in Developer Mode
- 📱 **Offline Capable**: Local Mode works without internet

For detailed architecture diagrams, see: [`ARCHITECTURE_DIAGRAM.md`](ARCHITECTURE_DIAGRAM.md) and [`architecture-mermaid.md`](architecture-mermaid.md)

---

## Current Implementation Overview

### Complete Frontend-Backend Architecture
- **Native iOS SwiftUI App** with full user interface
- **Triple AI Processing Modes**:
  - **Server Mode**: AWS EC2 FastAPI Backend (detection) + MLX on-device (recipe)
  - **Local Mode**: CoreML (detection) + MLX (recipe) - 100% offline
  - **Developer Mode**: CoreML (detection) + Ollama on Mac (recipe) - for development
- **End-to-End Data Flow** from camera capture to recipe display
- **User-Configurable Mode Selection**: Toggle in Settings with detailed descriptions
- **Automatic Fallbacks**: Graceful handling when modes are unavailable

---

## Technology Stack & Hardware Configuration

### Development Environment

#### Hardware
- **Device**: MacBook Air (2024)
- **Chip**: Apple M3 (8-core CPU + 10-core GPU)
- **RAM**: 16 GB unified memory
- **OS**: macOS 14.6.1 (Sonoma)

#### Software Versions
- **Python**: 3.13.5
- **Xcode**: 16.2 (Build 16C5032a)
- **Ollama**: 0.12.3

---

### Backend Stack (Python/FastAPI)

#### Core Frameworks & Libraries

##### Web Framework & API
```python
fastapi==0.104.1                    # Modern async web framework
pydantic==2.5.0                     # Data validation
```

##### Computer Vision & Deep Learning (YOLOv8n Fine-tuning)
```python
# Core ML Libraries
torch==2.8.0                        # PyTorch deep learning framework
torchvision==0.23.0                 # Computer vision utilities
ultralytics==8.3.203                # YOLOv8 implementation
opencv-python==4.12.0.88            # Image processing

# Scientific Computing
numpy==2.2.6                        # Numerical computing
scipy==1.15.3                       # Scientific algorithms
matplotlib==3.10.6                  # Visualization

```


##### Model Deployment & Inference

##### LLM Integration (Recipe Generation)
```bash
# Ollama (installed via Homebrew)
ollama version 0.12.3

# Python SDK
ollama                              # Python client for Ollama API
```

**Model**: Qwen2.5:3b (1.9 GB)
- 3 billion parameters
- 32 transformer layers
- Hidden size: 2048
- Attention heads: 16
- Inference speed: 40-60 tokens/s (on M3 GPU via Metal)

##### Utilities
```python
requests==2.32.5                    # HTTP client
```

---

### Frontend Stack (iOS/SwiftUI)

#### Core Technologies
- **Language**: Swift 5.x
- **UI Framework**: SwiftUI (iOS 17.0+)
- **Architecture**: MVVM (Model-View-ViewModel)
- **Minimum iOS Version**: iOS 16.0+ (for MLX support)

#### On-Device AI Stack

##### 1. Ingredient Detection (CoreML)
```swift
// CoreML Framework
import CoreML
import Vision

// Model Format
yolov8n_merged_food_cpu_aug_finetuned.mlmodelc
```

**Features**:
- **Model**: Fine-tuned YOLOv8n converted to CoreML
- **Input Size**: 640×640 RGB image
- **Output**: 11 food categories with bounding boxes
- **Performance**:
  - iPhone 14+: ~100ms inference time
  - Utilizes Neural Engine for acceleration
- **Classes**: beef, pork, chicken, butter, cheese, milk, broccoli, carrot, cucumber, lettuce, tomato

**Implementation**:
- `LocalInferenceService.swift`: CoreML model loading and inference
- **Preprocessing**:
  - ✅ Resize: Automatic via Vision framework (`.scaleFit`)
  - ✅ Normalize: Automatic via CoreML
- **Post-processing** (Manual Implementation):
  - ❌ NMS (Non-Maximum Suppression): ~30 lines custom code
  - ❌ Output parsing: ~130 lines parsing [1, 16, 8400] output
  - ❌ Confidence filtering, coordinate conversion, class mapping

**Comparison with Server**:
| Task | Server (Python/Ultralytics) | Local (Swift/CoreML) |
|------|---------------------------|---------------------|
| Resize | ✅ Auto (1 line) | ✅ Auto (Vision framework) |
| Normalize | ✅ Auto (1 line) | ✅ Auto (CoreML) |
| Inference | ✅ PyTorch | ✅ CoreML + Neural Engine |
| NMS | ✅ Auto (1 line) | ❌ Manual (~30 lines) |
| Post-processing | ✅ Auto (1 line) | ❌ Manual (~130 lines) |
| **Total Code** | **1 line** | **~200 lines** |

**Why Manual Implementation?**
- CoreML only provides raw model output (MLMultiArray)
- Ultralytics handles all post-processing in Python
- Swift developers must implement NMS and parsing manually

---

##### 2. Recipe Generation (MLX)
```swift
// MLX Framework (Apple Silicon optimized)
import MLX
import MLXLLM
import MLXLMCommon
import Hub
```

**Model**: Qwen2.5-0.5B-Instruct-4bit
- **Size**: ~300MB (4-bit quantized)
- **Parameters**: 500 million
- **Context Length**: 32K tokens
- **Performance**:
  - iPhone 15 Pro: 20-30 tokens/s
  - iPhone 14: 10-20 tokens/s
  - Generation time: 10-30 seconds
- **Memory Usage**: ~450-500MB during inference

**Features**:
- ✅ **Fully On-Device**: No cloud API required
- ✅ **Metal Acceleration**: Utilizes iPhone GPU
- ✅ **Auto-download**: Models downloaded from HuggingFace on first use
- ✅ **Memory Optimized**: Simplified prompts to reduce memory footprint
- ⚠️ **Real Device Only**: MLX requires physical iPhone (no Simulator support)

**Implementation**:
- `MLXRecipeGenerator.swift`: MLX model management and inference
- Auto screen-lock prevention during inference
- Timeout handling (120s max)
- Fallback to simplified recipes on error

**Optimization Strategies**:
1. **Prompt Simplification**: Reduced from 700 to 400 characters
2. **Screen Lock Prevention**: Prevents background GPU termination
3. **Memory Management**: Close other apps before inference
4. **Error Handling**: Graceful fallback to pre-defined recipes

---

##### 3. Hybrid Strategy Pattern
```swift
// RecipeGenerationStrategy.swift
protocol RecipeGenerationStrategy {
    func generateRecipe(...) async throws -> Recipe
}

// Three implementations:
1. MLXRecipeGenerator          // On-device MLX
2. NetworkOllamaGenerator      // Network Ollama (Mac server)
3. LocalLLMRecipeGenerator     // Fallback/compatibility
```

**Strategy Selection**:
- **Simulator**: Automatically uses Network Ollama
- **Real Device**: User can toggle between MLX and Network
- **Fallback**: Gracefully handles unavailable strategies

---

#### Data Layer
- **Networking**:
  - `URLSession` for HTTP requests
  - `async/await` for asynchronous operations
  - Automatic endpoint selection (localhost for Simulator, Mac IP for real device)

- **State Management**:
  - `@State` for local view state
  - `@Binding` for two-way data binding
  - `@ObservableObject` for shared state
  - `@AppStorage` for persistent settings (useLocalProcessing, useMLXGeneration)


---

### Fine-tuning Stack (YOLOv8n Training)

#### Training Environment
```python
Device: CPU (Apple M3 - 8 cores)
PyTorch: 2.8.0
Ultralytics: 8.3.203
Workers: 2 (for data loading)
```

#### Training Configuration
```python
Optimizer: AdamW
├─ Learning rate: 0.0005
├─ Weight decay: 0.0005
├─ Warmup epochs: 2
└─ Batch size: 8

Augmentations (moderate):
├─ HSV (hue, saturation, value): (0.01, 0.3, 0.2)
├─ Horizontal flip: 0.5
├─ Mosaic: 0.3
├─ Scale: 0.2
└─ Translate: 0.05

Training Duration:
├─ Epochs: 30
├─ Image size: 640x640
└─ Total time: ~2-3 hours on M3 CPU
```

#### Why CPU Training?
- **Stability**: No MPS-related dimension errors
- **Reproducibility**: Consistent results across runs
- **Compatibility**: Works perfectly with Python 3.13
- **Performance**: Still achieves mAP50 ≈ 0.881 (excellent)

**Note**: Attempted MPS (Apple Silicon GPU) training on Python 3.13 with PyTorch ≥2.6, but encountered:
- Negative-dimension errors during training
- Version constraint conflicts
- `torch.load` security changes requiring special handling

---

### Dataset

#### Food Classes (11 total)
```
Proteins: beef, pork, chicken
Dairy: butter, cheese, milk
Vegetables: broccoli, carrot, cucumber, lettuce, tomato
```

#### Dataset Structure
```
datasets/merged_food_dataset/
├── images/
│   ├── train/           # Training images
│   └── val/             # Validation images
├── labels/
│   ├── train/           # YOLO format annotations
│   └── val/
└── data.yaml            # Dataset configuration
```

---

### API Communication

#### Data Flow Architecture
```
iOS (Swift/SwiftUI)
    ↕ HTTP/REST API (JSON)
Backend (Python/FastAPI)
    ↕ Python objects (Pydantic)
YOLO Model (PyTorch)
    ↕ Tensors
Ollama (Qwen2.5:3b)
    ↕ Text/JSON
```

#### Content Types
- **Image Upload**: `multipart/form-data` (JPEG, quality 0.8)
- **API Requests/Responses**: `application/json`
- **Data Formats**:
  - iOS: `camelCase` (Swift naming convention)
  - Backend: `snake_case` (Python naming convention)
  - Automatic conversion via `JSONDecoder.keyDecodingStrategy`

---

### Development Tools

#### Version Control
```bash
Git 2.x
GitHub repository: github.com/Jessi0803/kitchen_assistant
```

#### Python Environment
```bash
# Virtual environment management
python3 -m venv fresh_venv
source fresh_venv/bin/activate

# Package management
pip install -r requirements.txt
```

#### iOS Development
```bash
# Xcode command line tools
xcode-select --install

# iOS Simulator testing
iPhone 15 Pro simulator (iOS 17.0+)
```


## Finetuning YOLOv8n (CPU)

I fine-tune `yolov8n.pt` on my food dataset using a CPU.

### Virtual Environments

This project uses two virtual environments:

| Environment | Python | Purpose |
|------------|--------|---------|
| `fresh_venv` | 3.13.5 | FastAPI backend, training (optional) |
| `yolo_venv_310` | 3.10.12 | **CoreML export** (required), training (optional) |

**Note**: CoreML export requires `yolo_venv_310` due to better `coremltools` compatibility.

### How to run

#### Option 1: Training (use either environment)
```bash
cd backend
source fresh_venv/bin/activate
# or: source yolo_venv_310/bin/activate
python3 fine_tune_yolo_cpu_aug.py
deactivate
```

#### Option 2: Export to CoreML (must use yolo_venv_310)
```bash
cd backend
source yolo_venv_310/bin/activate
python3 export_coreml.py
deactivate
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

---

## Dataset
I use `datasets/merged_food_dataset` with 11 classes:
`beef, pork, chicken, butter, cheese, milk, broccoli, carrot, cucumber, lettuce, tomato`.

---

## Why not MPS (Apple Silicon GPU)
I attempted MPS training on Python 3.13 with PyTorch ≥2.6 and Ultralytics 8.x, but ran into recurring issues:
- Negative-dimension/validation errors on MPS during training/metrics
- Version constraints on Python 3.13 limit known good torch+ultralytics combos
- `torch.load` security change (`weights_only=True`) required special handling

CPU training is stable and produced strong results (e.g., good mAP50). If I must use MPS, a more compatible stack is Python 3.11 + torch 2.1.0 + ultralytics 8.0.120 with conservative settings (amp=False, small batch/imgsz, minimal augments) and validating on CPU — but this requires a separate environment.

---

## Data Types Flow

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


# Recipe Generation with Qwen2.5:3b LLM

## Overview

This project now uses **Qwen2.5:3b** local LLM to generate real recipes, completely free and runs offline.

---

## What is Ollama?

**Ollama** is an open-source local LLM inference engine, similar to Docker but specifically designed for large language models.

### Core Features:
1. **Run LLMs Locally**: No need to connect to cloud services, completely offline
2. **Model Management**: Download, update, and switch between different models (Qwen, Llama, Mistral, etc.)
4. **Performance Optimization**: Automatically uses CPU/GPU acceleration (supports Apple Silicon, CUDA, ROCm)


```
When Ollama starts:


**Your M3 MacBook Air Setup**:

```
Hardware: Apple M3 (8-core CPU + 10-core GPU)
Ollama automatically selects: Metal (Apple GPU acceleration)

Execution:
├─ Qwen2.5:3b model (~2GB) → Loaded into GPU unified memory
├─ Token generation computation → Executed on GPU (3-5x faster than CPU)
└─ Inference speed: 40-60 tokens/s (CPU only: ~15-20 tokens/s)
```


---

## Complete Data Flow and Data Shapes

### Step 1: iOS User Takes Photo/Selects Image

```
User Action: Take photo or select image
↓
Data Type: UIImage
Data Shape: (height, width, 3) - RGB image
Example: (1920, 1080, 3) - 1920x1080 RGB image
```

### Step 2: iOS → Backend (Image Upload)

```swift
// iOS: APIClient.detectIngredients()
HTTP POST /api/detect
Body: image file (JPEG, compression quality 0.8)
```

```
Data Format: JPEG image file

```

### Step 3: Backend YOLO Detection

```python
# Backend: main.py detect_ingredients()
pil_image = Image.open(BytesIO(image_data))  # PIL Image
results = yolo_model(pil_image, conf=0.1)    # YOLO inference
```

```
Input: PIL Image (RGB)
    Shape: (height, width, 3)
    Example: (1920, 1080, 3)

YOLO Processing:
    Internal resize: (640, 640, 3) - YOLOv8 input size
    Output: List[Result]
        - boxes: Tensor (N, 6) - [x1, y1, x2, y2, conf, cls]
        - N = number of detected objects
        - Example: (5, 6) - 5 objects detected

Parsing Results:
    detected_ingredients: List[str]
    confidence_scores: List[float]
    Example: ["Tomato", "Cheese", "Chicken"], [0.92, 0.87, 0.85]
```

### Step 4: Backend → iOS (Detection Results) FastAPI converts dictionary to JSON string

```json
// HTTP Response
{
  "ingredients": ["Tomato", "Cheese", "Chicken"],
  "confidence": [0.92, 0.87, 0.85],
  "processing_time": 0.8
}
```

```
Data Type: JSON
Data Shape:
    ingredients: List[str] - shape (3,)
    confidence: List[float] - shape (3,)
    processing_time: float - scalar
```

### Step 5: iOS Receives and Displays Ingredients

```swift
// iOS: CameraView.swift
let ingredients = try await apiClient.detectIngredients(in: image)
self.detectedIngredients = ingredients  // ["Tomato", "Cheese", "Chicken"]
```

```
Data Type: [String]
Data Shape: (3,) - 3 ingredients
UI Display: 3 green tag cards
```

### Step 6: User Inputs Meal Craving

```
User Action: Enter "pasta"
Data Type: String
Data Length: 5 characters
```

### Step 7: iOS → Backend (Recipe Generation Request) Swift's Codable automatically generates JSON

```swift
// iOS: APIClient.generateRecipe()
HTTP POST /api/recipes
Content-Type: application/json
```

```json
{
  "ingredients": ["Tomato", "Cheese", "Chicken"],
  "mealCraving": "pasta",
  "dietaryRestrictions": [],
  "preferredCuisine": "Any"
}
```

```
Data Format: JSON
Data Shape:
    ingredients: List[str] - shape (3,)
    mealCraving: str - scalar
    dietaryRestrictions: List[str] - shape (0,) empty array
    preferredCuisine: str - scalar
```

### Step 8: Backend Prompt Construction

```python
# Backend: generate_recipe_with_llm()
ingredients_str = ", ".join(request.ingredients)
# "Tomato, Cheese, Chicken"

prompt = f"""You are a professional chef...
Available Ingredients: {ingredients_str}
Desired Meal: {request.mealCraving}
Generate a recipe in JSON format..."""
```

```
Data Type: str (Prompt text)

```

### Step 9: Ollama LLM Inference

```python
# Backend: ollama.chat()
response = ollama.chat(
    model='qwen2.5:3b',
    messages=[{'role': 'user', 'content': prompt}],
    options={'temperature': 0.7, 'num_predict': 2048}
)
```

```
Input → Ollama:
    model: str - "qwen2.5:3b"
    messages: List[Dict]
        - shape: (1,) - 1 message
        - content: str (200-250 tokens)
    options: Dict
        - temperature: float (0.7)
        - num_predict: int (2048)

Ollama Internal Processing:
    1. Tokenization: str → List[int]
        Shape: (200-250,) tokens

    2. Model Inference: Qwen2.5:3b (3B parameters)
        - Embedding Layer: (vocab_size, 2048)
        - Transformer Layers: 32 layers
        - Hidden Size: 2048
        - Attention Heads: 16

    3. Token Generation (Autoregressive):
        Generates tokens one by one
        Speed: 40-60 tokens/s
        Total tokens: ~1000-1500 tokens
        Time: 15-30 seconds

Output ← Ollama:
    response: Dict
        - message: Dict
            - content: str (JSON text, ~2000 characters)
```

**Detailed Example**:

**1. Tokenization Example**:

```
Input String:
"You are a professional chef. Create a recipe with Tomato, Cheese, Chicken for pasta."

↓ Tokenization (split text into tokens)

Token IDs: [1, 887, 403, 264, 6584, 29224, 13, 4155, 264, 11324, 449, ...]
Shape: (23,) - 23 tokens total

Explanation:
- "You" → token ID 1
- "are" → token ID 887
- "a" → token ID 403
- "professional" → token ID 6584
- "chef" → token ID 29224
- ...

Total: ~200-250 tokens (complete prompt)
```

**3. Token Generation Example**:

```
Autoregressive Generation (generates tokens one by one):

Generation Process:
Step 1: Input prompt (23 tokens) → Predict token 24: "{" (JSON start)
Step 2: Input prompt + "{" (24 tokens) → Predict token 25: "\"title\""
Step 3: Input prompt + "{ \"title\"" (25 tokens) → Predict token 26: ":"
Step 4: ...continues generating...
Step N: Complete JSON generated (~1200 tokens)



Final Output:
{
  "title": "Chicken Tomato Pasta",
  "description": "A delicious Italian pasta...",
  ...
}
```

**Ollama response structure**: Prompt explicitly requires: "Generate a recipe in JSON format"

```python
response = {
    'model': 'qwen2.5:3b',
    'created_at': '2025-10-10T12:30:00Z',
    'message': {
        'role': 'assistant',
        'content': '{"title": "Chicken Tomato Pasta", "description": "A delicious Italian pasta with chicken and fresh vegetables", "prep_time": 15, ...}'  # Complete JSON string
    },
    'done': True,
    'total_duration': 24000000000,  # 24 seconds (nanoseconds)
    'load_duration': 500000000,     # 0.5 seconds to load model
    'prompt_eval_count': 230,       # Input token count
    'eval_count': 1200,             # Generated token count
    'eval_duration': 23500000000    # 23.5 seconds generation time
}
```

### Step 10: Backend JSON Parsing

```python
# Backend: Parse LLM output
llm_output = response['message']['content']
# Extract JSON
start_idx = llm_output.find('{')
end_idx = llm_output.rfind('}') + 1
json_str = llm_output[start_idx:end_idx]
recipe_data = json.loads(json_str)
```

```
Input:
    llm_output: str (~2000 chars)
    Example: "{\"title\": \"Chicken Tomato Pasta\", ...}"

Parsing:
    json_str: str (removes extra text before/after)
    recipe_data: Dict
        Shape (key-value pairs):
            - title: str
            - description: str
            - prep_time: int
            - cook_time: int
            - servings: int
            - difficulty: str
            - ingredients: List[Dict] - shape (8,)
                Each Dict has 4 keys: name, amount, unit, notes
            - instructions: List[Dict] - shape (6,)
                Each Dict has 5 keys: step, text, time, temperature, tips
            - tags: List[str] - shape (4,)
            - nutrition_info: Dict - 7 keys
```

### Step 11: Backend Pydantic Model Conversion

```python
# Backend: Convert to Pydantic Recipe model
recipe = Recipe(
    title=recipe_data['title'],
    description=recipe_data['description'],
    ...
    ingredients=[Ingredient(**ing) for ing in recipe_data['ingredients']],
    instructions=[Instruction(**inst) for inst in recipe_data['instructions']],
    ...
)
```

### Step 12: Backend → iOS (Recipe JSON)

```json
// HTTP Response (snake_case)
{
  "title": "Chicken Tomato Pasta",
  "description": "A delicious Italian pasta...",
  "prep_time": 15,
  "cook_time": 25,
  "servings": 4,
  "difficulty": "Easy",
  "ingredients": [
    {"name": "Chicken breast", "amount": "300", "unit": "g", "notes": "diced"},
    {"name": "Tomato", "amount": "3", "unit": "pieces", "notes": "chopped"},
    ...
  ],
  "instructions": [
    {"step": 1, "text": "Boil pasta...", "time": 10, "tips": "Add salt"},
    ...
  ],
  "tags": ["Italian", "Pasta", "Chicken", "Quick"],
  "nutrition_info": {
    "calories": 450,
    "protein": "35g",
    ...
  }
}
```

```
Data Format: JSON (snake_case)
Data Size: ~3-5 KB
Data Structure:
    - 1 root object layer
    - ingredients: Array of Objects (8 items)
    - instructions: Array of Objects (6 items)
    - tags: Array of Strings (4 items)
    - nutrition_info: Nested Object (7 keys)
```

### Step 13: iOS JSON Parsing

```swift
// iOS: APIClient.swift
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
let backendRecipe = try decoder.decode(BackendRecipe.self, from: data)
let recipe = backendRecipe.toRecipe()
```

```
Input:
    data: Data (~3-5 KB)
    Format: JSON (snake_case)

JSONDecoder Processing:
    1. Parse JSON: Data → Dictionary
    2. Convert keys: snake_case → camelCase
        prep_time → prepTime
        cook_time → cookTime
        nutrition_info → nutritionInfo
    3. Type checking: Ensure all field types match

Output:
    BackendRecipe (Codable struct)
    ↓ toRecipe()
    Recipe (App internal model)
        - ingredients: [Ingredient] (8 items)
            Each Ingredient.id = UUID()
        - instructions: [Instruction] (6 items)
            Each Instruction.id = UUID() - Each ingredient and step automatically gets unique ID for UI display
        - difficulty: Difficulty enum (.easy)
```



### Step 14: iOS UI Update

Data Binding (@Binding)

  @Binding var generatedRecipe: Recipe?

  // When this variable changes, SwiftUI automatically re-renders the UI using it

```swift
// CameraView.swift
await MainActor.run {
    self.generatedRecipe = recipe
    self.isLoading = false
}
```

```
Data Type: Recipe (Swift struct)
UI Component: RecipeCard
Display Content:
    - Title: String (1 line)
    - Description: String (2-3 lines)
    - Metadata: 3 tags (time, servings, difficulty)
    - Ingredients Preview: First 3 ingredients
    - Button: "View Full Recipe"
```






---

## Data Shape Summary Table

| Step | Data Type | Shape/Size | Detailed Example | Key Code |
|------|---------|-----------|---------|-----------|
| **1. User Takes Photo** | UIImage | (1920, 1080, 3) | RGB image, each pixel has 3 channels (red, green, blue), Example: Photo of fridge ingredients | `UIImagePickerController()` |
| **2. Image Upload** | JPEG Data | ~300 KB | Compressed JPEG bytes: `<Data: 0x1234... 307200 bytes>` | `image.jpegData(compressionQuality: 0.8)` |
| **3a. YOLO Input** | PIL Image | (640, 640, 3) | Resized PIL Image, `<PIL.Image.Image image mode=RGB size=640x640>` | `Image.open(BytesIO(data))` |
| **3b. YOLO Output** | Tensor | (N, 6) | 5 objects: `[[100,150,200,250,0.92,2], [50,80,120,180,0.87,5], ...]` | `yolo_model(image, conf=0.1)` |
| **4. Detection Result JSON** | JSON | ~150 bytes | `{"ingredients": ["Tomato", "Cheese", "Chicken"], "confidence": [0.92, 0.87, 0.85]}` | `return JSONResponse(content={...})` |
| **5. iOS Ingredient List** | [String] | (3,) | Swift array: `["Tomato", "Cheese", "Chicken"]` | `try await apiClient.detectIngredients(in: image)` |
| **6. Meal Craving** | String | 5 chars | User input: `"pasta"` | `@State private var mealCraving: String = ""` |
| **7. Request JSON** | JSON | ~180 bytes | `{"ingredients": ["Tomato", "Cheese", "Chicken"], "mealCraving": "pasta", "dietaryRestrictions": [], "preferredCuisine": "Any"}` | `JSONEncoder().encode(requestBody)` |
| **8. LLM Prompt** | String | ~800 chars, 200 tokens | `"You are a professional chef. Create a recipe...\nAvailable Ingredients: Tomato, Cheese, Chicken\nDesired Meal: pasta\n..."` | `prompt = f"""You are..."""` |
| **9a. LLM Input Tokens** | List[int] | (230,) | Token IDs: `[1, 887, 403, 264, 6584, 29224, 13, ...]` - 230 tokens | `ollama.chat(model='qwen2.5:3b', messages=[...])` |
| **9b. LLM Output Tokens** | List[int] | (1200,) | Generated Token IDs: `[123, 456, 789, ...]` - 1200 tokens, generated one by one | Ollama automatic generation (Autoregressive) |
| **10. LLM Output Text** | String | ~2500 chars | `'{"title": "Chicken Tomato Pasta", "description": "A delicious Italian pasta...", "prep_time": 15, "cook_time": 25, ...}'` | `response['message']['content']` |
| **11. Recipe Dict** | Dict | 10 keys, nested | `{'title': 'Chicken Tomato Pasta', 'prep_time': 15, 'ingredients': [{'name': 'Chicken', 'amount': '300', 'unit': 'g'}, ...]}` | `json.loads(json_str)` |
| **12. Recipe Object** | Pydantic Model | 10 fields | `Recipe(title='Chicken Tomato Pasta', prep_time=15, ingredients=[Ingredient(name='Chicken', ...)])` | `Recipe(**recipe_data)` |
| **13. Response JSON** | JSON | ~3800 bytes | snake_case format: `{"title": "Chicken Tomato Pasta", "prep_time": 15, "cook_time": 25, ...}` | FastAPI automatic serialization: `return recipe` |
| **14. iOS Recipe** | Swift struct | 10 properties | camelCase format: `Recipe(title: "Chicken Tomato Pasta", prepTime: 15, cookTime: 25, ingredients: [...])` | `try decoder.decode(Recipe.self, from: data)` + `backendRecipe.toRecipe()` |
| **15. UI Display** | SwiftUI Views | Multi-layer nested | Display content: Title Text, Description Text, HStack(time/servings/difficulty), VStack(8 ingredients), VStack(6 steps), LazyVGrid(nutrition), FlowLayout(4 tags) | `RecipeDetailView(recipe: recipe)` |

---

## Performance Data (M3 MacBook Air, 16GB RAM)

| Step | Time | Notes |
|------|------|------|
| Image Upload | 0.1-0.3 sec | Depends on image size |
| YOLO Detection | 0.5-1 sec | CPU inference |
| Prompt Construction | <0.01 sec | String processing |
| LLM Inference | 15-30 sec | 40-60 tokens/s |
| JSON Parsing | <0.1 sec | Python json.loads |
| HTTP Transfer | 0.05-0.1 sec | Local localhost |
| iOS JSON Parsing | <0.05 sec | JSONDecoder |
| UI Rendering | <0.1 sec | SwiftUI |
| **Total (User Experience)** | **16-32 sec** | From click to recipe display |


## Quick Start Guide

### Choose Your Mode

#### Option A: Local Mode (Recommended for Production)
**Requirements**: iPhone 12+ with iOS 16+

1. **Deploy app to real device**:
   ```bash
   open ios-app/KitchenAssistant.xcodeproj
   # Select your iPhone in Xcode, then Run
   ```

2. **Enable Local Processing in app**:
   - Open Settings tab
   - Toggle **"Use Local Processing"** ON
   - Toggle **"Use MLX Generation"** ON

3. **First use**: MLX model (~300MB) will auto-download from HuggingFace

4. **Use the app**:
   - Take photo of ingredients
   - Enter meal craving
   - Generate recipe (10-30s on-device)

---

#### Option B: Developer Mode (Best for Development)
**Requirements**: iPhone 12+ + Mac with Ollama

1. **Install Ollama on Mac**:
   ```bash
   # Install Ollama
   brew install ollama
   
   # Start Ollama service
   brew services start ollama
   
   # Download Qwen2.5:3b model (~2GB)
   ollama pull qwen2.5:3b
   
   # Test the model
   ollama run qwen2.5:3b "Hello"
   ```

2. **Deploy app to iPhone**:
   ```bash
   open ios-app/KitchenAssistant.xcodeproj
   ```

3. **Configure app settings**:
   - Toggle **"Use Local Processing"** ON (for CoreML detection)
   - Toggle **"Use MLX Generation"** OFF (to use Ollama)

4. **Use the app**:
   - Take photo → CoreML detects (~100ms)
   - Enter meal → Ollama generates (5-10s with better quality)

---

#### Option C: Server Mode (For Simulator Testing)
**Requirements**: AWS EC2 backend (or local FastAPI for development)

1. **Start Backend** (if running locally):
   ```bash
   cd backend
   source fresh_venv/bin/activate
   python main.py  # Starts at http://localhost:8000
   ```

2. **Run iOS Simulator**:
   ```bash
   open ios-app/KitchenAssistant.xcodeproj
   # Select iPhone Simulator, then Run
   ```

3. **App will automatically use Server Mode** (CoreML not available on Simulator)

4. **Use the app**:
   - Select photo from library
   - Server detects ingredients
   - MLX generates recipe on Simulator (if iOS 16+ Mac)

---

### Mode Comparison at a Glance

| Mode | Setup Time | Recipe Quality | Use Case |
|------|-----------|---------------|----------|
| **Local** | 5 min | Good | Production, Privacy |
| **Developer** | 10 min | Excellent | Development |
| **Server** | 15 min | Good | Simulator Testing |

---

## Using On-Device AI (Local Processing)

### Prerequisites

**Hardware Requirements**:
- iPhone 12 or later (A14 Bionic chip or newer)
- ~500MB free storage for MLX model
- 2GB+ available RAM

**Software Requirements**:
- iOS 16.0 or later
- Xcode 16.2+ for development

---

### Setup Guide for Local AI

#### Step 1: Enable Developer Mode on iPhone

1. Connect iPhone to Mac via USB cable
2. On iPhone: **Settings** → **Privacy & Security** → **Developer Mode**
3. Toggle **ON** and restart iPhone
4. After restart, confirm enabling Developer Mode

#### Step 2: Trust Developer Certificate

1. Connect iPhone to Mac and run the app from Xcode
2. On iPhone: **Settings** → **General** → **VPN & Device Management**
3. Under "Developer App", tap your Apple ID
4. Tap **Trust** and confirm

#### Step 3: Configure App Settings

In the app on your iPhone:

**Settings Tab Configuration**:

```
┌─────────────────────────────────────────────┐
│ AI Processing Mode                          │
├─────────────────────────────────────────────┤
│                                             │
│ ☐ Use Local Processing                     │
│ ☐ Use On-Device MLX LLM                    │
│                                             │
└─────────────────────────────────────────────┘
```

**Three Configuration Options**:

| Toggle 1 | Toggle 2 | Result |
|----------|----------|--------|
| ☐ OFF | ☐ OFF | **Server Mode**: Cloud detection + Local MLX recipe |
| ☑️ ON | ☐ OFF | **Developer Mode**: CoreML detection + Ollama recipe |
| ☑️ ON | ☑️ ON | **Local Mode**: CoreML detection + MLX recipe (100% offline) |

**Recommended Settings**:
- **For Production**: Both ON (Local Mode)
- **For Development**: First ON, Second OFF (Developer Mode)
- **For Simulator**: Both OFF (Server Mode)

---

### How to Use Local AI

#### Ingredient Detection (CoreML YOLO)

1. Open the app on your iPhone
2. Tap **"Camera"** or **"Photo Library"**
3. Take/select a photo of ingredients
4. **CoreML automatically detects** ingredients (no server needed!)

**Performance**:
- Detection time: ~100ms on iPhone 14+
- Completely offline
- No data leaves your device

---

#### Recipe Generation (MLX)

1. After ingredients are detected
2. Enter your meal craving (e.g., "pasta", "stir fry")
3. Tap **"Generate Recipe"**
4. **MLX generates recipe on-device** (10-30 seconds)

**Important Notes**:
- ⚠️ **Keep app in foreground** during generation (30-60 seconds)
- ⚠️ **Don't lock screen** - automatic lock is disabled during inference
- ⚠️ **Close other apps** to free up memory
- ⚠️ **First use downloads model** (~300MB from HuggingFace)

**Performance**:
- iPhone 15 Pro: 20-30 tokens/s (15-25 seconds)
- iPhone 14: 10-20 tokens/s (25-40 seconds)
- iPhone 12/13: 8-15 tokens/s (30-60 seconds)


### Comparison: Three Processing Modes

| Feature | Server Mode | Local Mode | Developer Mode |
|---------|-------------|------------|----------------|
| **Detection** | ☁️ AWS EC2 (YOLOv8n) | 📱 CoreML (Neural Engine) | 📱 CoreML (Neural Engine) |
| **Recipe Generation** | 📱 MLX 0.5B (on-device) | 📱 MLX 0.5B (on-device) | 🖥️ Ollama 3B (Mac) |
| **Privacy** | ⚠️ Detection data to cloud | ✅ 100% on-device | ✅ 100% on-device |
| **Internet Required** | ⚠️ For detection only | ✅ Fully offline | ⚠️ For Ollama connection |
| **Speed (Detection)** | ~500ms-1s + network | ✅ ~100ms | ✅ ~100ms |
| **Speed (Recipe)** | ⚠️ 10-30s (0.5B) | ⚠️ 10-30s (0.5B) | ✅ 5-10s (3B, Mac GPU) |
| **Recipe Quality** | ⚠️ Good (0.5B) | ⚠️ Good (0.5B) | ✅ Excellent (3B) |
| **Setup Required** | ⚠️ AWS EC2 backend | ✅ None | ⚠️ Ollama on Mac |
| **Device Support** | ✅ All iOS devices | ⚠️ iPhone 12+ (iOS 16+) | ⚠️ iPhone 12+ + Mac |
| **Simulator Support** | ✅ Yes | ❌ No (MLX unavailable) | ✅ Yes |
| **Server Costs** | ⚠️ AWS EC2 costs | ✅ Free | ✅ Free |
| **Best For** | Testing/Simulator | Production/Privacy | Development |

**Recommendation**:
- **For Development**: Use **Developer Mode** (best recipe quality, fast iteration)
- **For Testing on Simulator**: Use **Server Mode** (only mode that works on Simulator)
- **For Production Deployment**: Use **Local Mode** (privacy, offline, no costs)
- **User Choice**: Let users toggle between Server and Local modes in Settings

---

### Model Information

#### CoreML YOLO Model
```
File: yolov8n_merged_food_cpu_aug_finetuned.mlmodelc
Size: ~6MB
Input: 640×640 RGB image
Output: 11 food categories + bounding boxes
Inference: Neural Engine accelerated
```

**Detected Classes**:
- Proteins: beef, pork, chicken
- Dairy: butter, cheese, milk
- Vegetables: broccoli, carrot, cucumber, lettuce, tomato

---

#### MLX LLM Model
```
Model: mlx-community/Qwen2.5-0.5B-Instruct-4bit
Size: ~300MB (4-bit quantized)
Parameters: 500 million
Context: 32K tokens
Download: Automatic from HuggingFace on first use
Location: ~/Documents/huggingface/models/
```

**Recipe Generation**:
- Input: List of ingredients + meal type
- Output: Structured JSON recipe with:
  - Title, description
  - Ingredient list with amounts
  - Step-by-step instructions with timing
  - Nutritional information (optional)
  - Tags and difficulty level



