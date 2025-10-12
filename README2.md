# Edge-AI Kitchen Assistant

A fully offline, AI-powered kitchen assistant that takes one photo of your fridge, combines it with your meal preference, and instantly delivers step-by-step recipes using local YOLOv8 detection and Qwen2.5:3b LLM generation.

## 🎯 Project Overview

### Complete Frontend-Backend-AI Architecture

**Three Core Technologies:**
1. **iOS SwiftUI Frontend** - Native camera capture, ingredient display, recipe browsing
2. **Python FastAPI Backend** - REST API services, image processing, AI orchestration
3. **Local AI Models** - Fine-tuned YOLOv8n for ingredient detection + Qwen2.5:3b for recipe generation

### System Architecture

```
iOS SwiftUI App ← REST API → FastAPI Backend (localhost:8000)
                               ↓
                            ┌──────────────────────────────┐
                            │  AI Processing Pipeline      │
                            ├──────────────────────────────┤
                            │  1. YOLOv8n (CPU)           │
                            │     → Ingredient Detection   │
                            │                              │
                            │  2. Qwen2.5:3b (Ollama)     │
                            │     → Recipe Generation      │
                            └──────────────────────────────┘
```

**Complete Data Flow:**
```
iOS Camera → Image Upload → YOLO Detection → Ollama LLM → Recipe JSON → SwiftUI Display
```

### Architecture Diagram
![App Architecture](image.png)

---

## 🚀 Quick Start Guide

### Prerequisites
- macOS with Apple Silicon (M1/M2/M3) recommended
- Python 3.10+
- Xcode 15+
- Homebrew

### 1. Install Ollama and Download Model

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

### 2. Setup Backend Server

```bash
cd backend
source fresh_venv/bin/activate  # Activate virtual environment
pip install ollama              # Install Ollama SDK
python main.py                  # Start FastAPI server
```

Server will start at `http://localhost:8000`

### 3. Run iOS App

```bash
open ios-app/KitchenAssistant.xcodeproj
```

Select iOS simulator in Xcode and press Play to run.

### 4. Test Complete Workflow

1. Open app in iOS simulator
2. Switch to "Scan Fridge" tab
3. Select or capture a photo of ingredients
4. Enter desired meal type (e.g., "pasta")
5. Click "Generate Recipe"
6. View generated complete recipe (15-30 seconds)
7. Click "View Full Recipe" for detailed instructions

---

## 🤖 AI Integration: Local LLM Recipe Generation

### Why Qwen2.5:3b?

**Completely Free & Offline:**
- ✅ No API costs (vs. OpenAI GPT: $0.002/1K tokens)
- ✅ Complete privacy - data never leaves your device
- ✅ Works offline - no internet required
- ✅ Fast inference - 40-60 tokens/s on M3 MacBook Air

### Ollama: Local LLM Inference Engine

**What is Ollama?**

Ollama is an open-source local LLM inference engine, similar to Docker but specialized for large language models.

**Core Features:**
1. **Local Execution**: No cloud services required, completely offline
2. **Model Management**: Download, update, switch between models (Qwen, Llama, Mistral)
3. **API Services**: REST API and Python SDK for easy integration
4. **Auto Optimization**: Automatic CPU/GPU acceleration (Apple Silicon, CUDA, ROCm)
5. **Memory Management**: Automatic model loading/unloading to save resources

**Zero Configuration:**

Ollama automatically detects your hardware and selects the optimal execution method:

```
Ollama Startup:
1. Hardware Detection
   - Check for GPU (graphics card)
   - Detect GPU type (Apple Metal, NVIDIA CUDA, AMD ROCm)
   - Check RAM size

2. Auto Select Execution Method
   ├─ Apple M-series chip → Use Metal (GPU acceleration)
   ├─ NVIDIA GPU → Use CUDA (GPU acceleration)
   ├─ AMD GPU → Use ROCm (GPU acceleration)
   └─ CPU only → Use CPU execution

3. Load Model
   - Load model into GPU memory (faster)
   - If GPU memory insufficient → Partial load to RAM
   - Auto allocate optimal memory usage
```

**On M3 MacBook Air:**
```
Hardware: Apple M3 (8-core CPU + 10-core GPU)
Ollama Auto Selects: Metal (Apple GPU acceleration)

Execution:
├─ Qwen2.5:3b model (~2GB) → Loaded into GPU unified memory
├─ Token generation → Runs on GPU (3-5x faster than CPU)
└─ Inference speed: 40-60 tokens/s (CPU only: ~15-20 tokens/s)
```

**vs. Other Solutions (Manual Configuration Required):**

```python
# PyTorch (Manual device configuration)
device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
model = model.to(device)  # Manually move to GPU

# Ollama (Fully automatic)
response = ollama.chat(model='qwen2.5:3b', messages=[...])
# No device configuration needed!
```

### Ollama vs. GPT API Comparison

| Feature | Ollama (Local) | OpenAI GPT API (Cloud) |
|---------|---------------|------------------------|
| **Cost** | Free | $0.002/1K tokens |
| **Privacy** | Completely local, no data transmission | Data sent to OpenAI servers |
| **Speed** | Depends on local hardware | Depends on network and server load |
| **Model Choice** | Free switching (Qwen, Llama, etc.) | OpenAI models only |
| **Offline Use** | ✅ Fully offline capable | ❌ Requires internet |
| **Hardware Requirements** | 8GB+ RAM | No hardware requirements |

---

## 📊 Complete Data Flow with Data Shapes

### 15-Step Pipeline: iOS Photo → Recipe Display

| Step | Data Type | Shape/Size | Example | Key Code |
|------|-----------|-----------|---------|----------|
| **1. User Photo** | UIImage | (1920, 1080, 3) | RGB image with 3 channels (red, green, blue) | `UIImagePickerController()` |
| **2. Image Upload** | JPEG Data | ~300 KB | Compressed JPEG bytes: `<Data: 0x1234... 307200 bytes>` | `image.jpegData(compressionQuality: 0.8)` |
| **3a. YOLO Input** | PIL Image | (640, 640, 3) | Resized PIL Image: `<PIL.Image.Image mode=RGB size=640x640>` | `Image.open(BytesIO(data))` |
| **3b. YOLO Output** | Tensor | (N, 6) | 5 objects: `[[100,150,200,250,0.92,2], [50,80,120,180,0.87,5], ...]` | `yolo_model(image, conf=0.1)` |
| **4. Detection JSON** | JSON | ~150 bytes | `{"ingredients": ["Tomato", "Cheese", "Chicken"], "confidence": [0.92, 0.87, 0.85]}` | `return JSONResponse(content={...})` |
| **5. iOS Ingredients** | [String] | (3,) | Swift array: `["Tomato", "Cheese", "Chicken"]` | `try await apiClient.detectIngredients(in: image)` |
| **6. Meal Craving** | String | 5 chars | User input: `"pasta"` | `@State private var mealCraving: String = ""` |
| **7. Request JSON** | JSON | ~180 bytes | `{"ingredients": ["Tomato", "Cheese", "Chicken"], "mealCraving": "pasta", ...}` | `JSONEncoder().encode(requestBody)` |
| **8. LLM Prompt** | String | ~800 chars, 200 tokens | `"You are a professional chef. Create a recipe...\nIngredients: Tomato, Cheese, Chicken\n..."` | `prompt = f"""You are..."""` |
| **9a. LLM Input Tokens** | List[int] | (230,) | Token IDs: `[1, 887, 403, 264, 6584, 29224, 13, ...]` | `ollama.chat(model='qwen2.5:3b', messages=[...])` |
| **9b. LLM Output Tokens** | List[int] | (1200,) | Generated Token IDs: `[123, 456, 789, ...]` - Generated one-by-one | Ollama auto-generation (Autoregressive) |
| **10. LLM Output Text** | String | ~2500 chars | `'{"title": "Chicken Tomato Pasta", "description": "A delicious...", "prep_time": 15, ...}'` | `response['message']['content']` |
| **11. Recipe Dict** | Dict | 10 keys, nested | `{'title': 'Chicken Tomato Pasta', 'prep_time': 15, 'ingredients': [{'name': 'Chicken', ...}]}` | `json.loads(json_str)` |
| **12. Recipe Object** | Pydantic Model | 10 fields | `Recipe(title='Chicken Tomato Pasta', prep_time=15, ingredients=[Ingredient(...)])` | `Recipe(**recipe_data)` |
| **13. Response JSON** | JSON | ~3800 bytes | snake_case format: `{"title": "Chicken Tomato Pasta", "prep_time": 15, "cook_time": 25, ...}` | FastAPI auto-serialization: `return recipe` |
| **14. iOS Recipe** | Swift struct | 10 properties | camelCase format: `Recipe(title: "Chicken Tomato Pasta", prepTime: 15, cookTime: 25, ...)` | `try decoder.decode(Recipe.self, from: data)` + `toRecipe()` |
| **15. UI Display** | SwiftUI Views | Multi-level nested | Display: Title Text, Description, HStack(time/servings/difficulty), VStack(8 ingredients), VStack(6 steps), LazyVGrid(nutrition), FlowLayout(4 tags) | `RecipeDetailView(recipe: recipe)` |

### Performance Metrics (M3 MacBook Air, 16GB RAM)

| Step | Time | Notes |
|------|------|-------|
| Image Upload | 0.1-0.3 sec | Depends on image size |
| YOLO Detection | 0.5-1 sec | CPU inference |
| Prompt Construction | <0.01 sec | String processing |
| **LLM Inference** | **15-30 sec** | **40-60 tokens/s** (Main bottleneck) |
| JSON Parsing | <0.1 sec | Python json.loads |
| HTTP Transfer | 0.05-0.1 sec | Local localhost |
| iOS JSON Parsing | <0.05 sec | JSONDecoder |
| UI Rendering | <0.1 sec | SwiftUI |
| **Total (User Experience)** | **16-32 sec** | From click to recipe display |

### Key Transformations Explained

#### 1. snake_case → camelCase (Step 13-14)

**Backend JSON (Python):**
```json
{
  "prep_time": 15,
  "cook_time": 25,
  "nutrition_info": {...}
}
```

**iOS Model (Swift):**
```swift
Recipe(
  prepTime: 15,        // prep_time → prepTime
  cookTime: 25,        // cook_time → cookTime
  nutritionInfo: ...   // nutrition_info → nutritionInfo
)
```

**Automatic conversion:**
```swift
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase  // ← Magic!
let recipe = try decoder.decode(Recipe.self, from: data)
```

#### 2. String → Enum (Step 14)

**Security improvement:**
```swift
// ❌ Using String - prone to typos
let difficulty: String = "Eazy"  // Typo!

// ✅ Using Enum - type-safe
let difficulty: Difficulty = .easy  // Cannot make typo
```

#### 3. Adding UUIDs (Step 14)

**Why needed:**

SwiftUI's `ForEach` requires unique IDs to track each item:

```swift
// ❌ Without ID - SwiftUI can't distinguish
["Chicken", "Tomato", "Chicken"]  // Two Chickens, can't tell apart

// ✅ With UUID - Each is unique
Ingredient(id: UUID(), name: "Chicken")  // id: 123-abc
Ingredient(id: UUID(), name: "Tomato")   // id: 456-def
Ingredient(id: UUID(), name: "Chicken")  // id: 789-ghi
```

---

## 🎯 YOLO Model: Ingredient Detection

### Fine-tuning YOLOv8n on CPU

I fine-tuned `yolov8n.pt` on a custom food dataset using CPU.

**Training Configuration:**
- **Device**: CPU (stable on this machine)
- **Epochs**: 30, **Batch**: 8, **Image Size**: 640, **Workers**: 2
- **Optimizer**: AdamW (lr0=0.0005, weight_decay=0.0005, warmup_epochs=2)
- **Augmentations**: Moderate (hsv_h=0.01, hsv_s=0.3, hsv_v=0.2, fliplr=0.5, mosaic=0.3, mixup=0.0)
- **Validation/Plots**: Enabled; metrics and plots saved every run
- **Output**: `kitchen_assistant_training_cpu_aug/merged_food_yolov8n_cpu_aug_30epochs/`

### How to Run Training

```bash
cd backend
source fresh_venv/bin/activate
python3 fine_tune_yolo_cpu_aug.py
```

### Training Results

**Overall Metrics:**
![YOLO Training Results](backend/kitchen_assistant_training_cpu_aug/merged_food_yolov8n_cpu_aug_30epochs/results.png)

**Class-wise Performance:**
![Confusion Matrix (Normalized)](backend/kitchen_assistant_training_cpu_aug/merged_food_yolov8n_cpu_aug_30epochs/confusion_matrix_normalized.png)

**Summary:**
- Final (epoch 30): Precision ≈ 0.865, Recall ≈ 0.857
- Final mAP50 ≈ 0.881, mAP50-95 ≈ 0.685
- Train/val losses steadily decreased and plateaued, indicating stable convergence

### Loss Functions Explained

- **box_loss**: Bounding box regression loss. Measures box overlap with ground truth (IoU-based). Lower = better localization.
- **cls_loss**: Classification loss. Measures correct class probability predictions (BCE/Logits). Lower = better classification.
- **dfl_loss**: Distribution Focal Loss. Models box coordinates as discrete distributions for finer localization. Lower = sharper box edges.

**Tip**: All three typically decrease together. As box_loss and dfl_loss drop, mAP50-95 improves; as cls_loss improves, precision/recall increase.

### Dataset

Using `datasets/merged_food_dataset` with **11 classes**:
```
beef, pork, chicken, butter, cheese, milk, broccoli, carrot, cucumber, lettuce, tomato
```

### Why Not MPS (Apple Silicon GPU)?

I attempted MPS training on Python 3.13 with PyTorch ≥2.6 and Ultralytics 8.x, but encountered recurring issues:
- Negative-dimension/validation errors on MPS during training/metrics
- Version constraints on Python 3.13 limit known good torch+ultralytics combinations
- `torch.load` security change (`weights_only=True`) required special handling

**CPU training is stable** and produced strong results (good mAP50). If MPS is required, a more compatible stack would be Python 3.11 + torch 2.1.0 + ultralytics 8.0.120 with conservative settings (amp=False, small batch/imgsz, minimal augments) and CPU validation — but this requires a separate environment.

---

## 🔄 Server vs. Local Inference Architecture

### Overview

This project supports both **server-side** and **local inference** for ingredient detection, each with distinct advantages.

### Server-Side Inference (Python + PyTorch) ✅ Currently Used

#### Implementation

```python
# Server-side: Simple 3-line implementation
from ultralytics import YOLO

model = YOLO('yolov8n_merged_food_cpu_aug_finetuned.pt')
results = model(image)  # Automatic preprocessing, inference, postprocessing
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
2. **Preprocessing**: YOLO automatically resizes, normalizes, converts to tensors
3. **Inference**: PyTorch model runs on server hardware
4. **Postprocessing**: YOLO automatically parses outputs, applies NMS, filters results

### Local Inference (iOS + ONNX) 🚧 Future Implementation

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

#### Why Manual Implementation is Required

**iOS Platform Limitations:**
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

#### Advantages & Disadvantages

**Local Inference:**
- ✅ **Privacy Protection**: Images never leave the device
- ✅ **Offline Usage**: No internet connection required
- ✅ **Low Operating Cost**: No server maintenance
- ✅ **Fast Response**: No network latency
- ❌ **Complex Development**: 100+ lines of manual implementation
- ❌ **Limited Performance**: Single-core ARM processor
- ❌ **Harder Maintenance**: Requires app updates for model changes

### Model Conversion Process

**PyTorch to ONNX for iOS:**

```python
# Convert PyTorch model to ONNX
from ultralytics import YOLO

model = YOLO('yolov8n_merged_food_cpu_aug_finetuned.pt')
model.export(
    format='onnx',
    imgsz=640,
    simplify=True,
    opset=12  # Compatible with iOS ONNX Runtime
)
```

**Output format:**
- **PyTorch Output**: `[1, 16, 8400]` (4 bbox + 1 objectness + 11 classes)
- **ONNX Output**: `[1, 16, 8400]` (same format, different runtime)

### Accuracy Comparison

#### Theoretical Accuracy
- **Same Model**: Both use identical YOLOv8 (converted from same `.pt` file)
- **Same Preprocessing**: Both resize to 640x640 and normalize to 0-1
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

---

## 🛠 API Reference

### Ingredient Detection

**Endpoint**: `POST /api/detect`

**Request**:
```
Content-Type: multipart/form-data
Body: image file (JPEG/PNG)
```

**Response**:
```json
{
  "ingredients": ["Tomato", "Cheese", "Chicken"],
  "confidence": [0.91, 0.84, 0.87],
  "processing_time": 0.8
}
```

### Recipe Generation

**Endpoint**: `POST /api/recipes`

**Request**:
```json
{
  "ingredients": ["Tomato", "Cheese", "Chicken", "Broccoli"],
  "mealCraving": "pasta",
  "dietaryRestrictions": [],
  "preferredCuisine": "Italian"
}
```

**Response**:
```json
{
  "title": "Chicken Broccoli Pasta",
  "description": "A delicious Italian pasta with chicken and vegetables",
  "prep_time": 15,
  "cook_time": 25,
  "servings": 4,
  "difficulty": "Easy",
  "ingredients": [
    {
      "name": "Chicken",
      "amount": "300",
      "unit": "g",
      "notes": "diced"
    }
  ],
  "instructions": [
    {
      "step": 1,
      "text": "Boil pasta according to package instructions",
      "time": 10,
      "tips": "Add salt to water for better flavor"
    }
  ],
  "tags": ["Italian", "Pasta", "Chicken"],
  "nutrition_info": {
    "calories": 450,
    "protein": "35g",
    "carbs": "48g",
    "fat": "12g"
  }
}
```

---

## ⚙️ Advanced Configuration

### Adjusting LLM Parameters

In `backend/main.py`, `generate_recipe_with_llm()` function:

```python
response = ollama.chat(
    model='qwen2.5:3b',
    messages=[...],
    options={
        'temperature': 0.7,     # Creativity (0.0-1.0)
        'num_predict': 2048,    # Max generation length
        'top_p': 0.9,           # Sampling threshold
        'top_k': 40,            # Candidate count
    }
)
```

**Parameter Descriptions:**

- **temperature** (0.7): Higher = more creative but potentially unreasonable
  - 0.3-0.5: Conservative, practical
  - 0.7-0.9: Balanced
  - 0.9-1.0: Creative, adventurous

- **num_predict** (2048): Maximum number of tokens to generate
  - 1024: Short recipes
  - 2048: Detailed recipes (recommended)
  - 4096: Very detailed (slower)

### Upgrading to Larger Models

#### Option 1: Qwen2.5:7b (Higher Quality)

```bash
# Download 7b model (~4.7 GB)
ollama pull qwen2.5:7b

# Modify main.py
model='qwen2.5:7b'  # Originally 'qwen2.5:3b'
```

**Trade-offs:**
- ✅ Better recipe quality
- ✅ More accurate nutrition info
- ❌ Slower generation (15-25 tokens/s)
- ❌ More RAM needed (5-7 GB)

#### Option 2: Llama 3.2:3b (English-focused)

```bash
ollama pull llama3.2:3b

# Modify main.py
model='llama3.2:3b'
```

---

## 📚 Detailed Technical Documentation

For in-depth technical details, see:
- **[RECIPE_GENERATION_GUIDE.md](RECIPE_GENERATION_GUIDE.md)** - Complete LLM integration documentation with detailed data flow
- **[FIX_XCODE_ERROR.md](FIX_XCODE_ERROR.md)** - Xcode configuration troubleshooting guide

---

## 🔮 Future Development

### Next Steps

1. **Local AI Integration**
   - Convert `best.pt` to ONNX and embed in iOS app
   - Add local/server toggle in Settings
   - Optimize local inference accuracy

2. **Local LLM Service**
   - Integrate lightweight language model for basic recipe generation
   - Implement hybrid approach: local quick suggestions + server detailed recipes

3. **Enhanced Features**
   - Voice input for meal preferences
   - Recipe favorites and history
   - Nutritional tracking
   - Shopping list generation

---

## 📄 License

This project is available under the MIT License.

---

## 🙏 Acknowledgments

- **YOLOv8** by Ultralytics for object detection
- **Qwen2.5** by Alibaba for language model
- **Ollama** for local LLM inference engine
- **FastAPI** for backend framework
- **SwiftUI** for iOS interface

---

**Last Updated**: 2025-10-11
**Status**: ✅ Fully functional with local AI recipe generation
