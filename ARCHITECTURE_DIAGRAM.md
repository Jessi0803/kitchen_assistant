# Edge-AI Kitchen Assistant - System Architecture

## Complete System Overview

```
╔══════════════════════════════════════════════════════════════════════════╗
║                     📱 iOS KITCHEN ASSISTANT APP                         ║
║                         (iPhone 12+, iOS 16+)                            ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  USER WORKFLOW:  📸 Photo  →  👁️ Detect  →  💭 Input  →  🍳 Recipe     ║
║                                                                          ║
║  ⚙️ SETTINGS:   ☐ Use Local Processing   ☐ Use MLX Generation          ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝
                                   │
                   ┌───────────────┼───────────────┐
                   │               │               │
                   ▼               ▼               ▼
       ╔═══════════════╗ ╔═══════════════╗ ╔═══════════════╗
       ║   MODE 1      ║ ║   MODE 2      ║ ║   MODE 3      ║
       ║ Server Mode   ║ ║ Local Mode    ║ ║ Developer     ║
       ║               ║ ║               ║ ║ Mode          ║
       ╚═══════════════╝ ╚═══════════════╝ ╚═══════════════╝


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      🔍 STAGE 1: INGREDIENT DETECTION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│  ☁️ CLOUD MODE   │   │ 📱 LOCAL MODE    │   │ 📱 LOCAL MODE    │
├──────────────────┤   ├──────────────────┤   ├──────────────────┤
│ AWS EC2 Server   │   │ CoreML           │   │ CoreML           │
│ FastAPI Backend  │   │ Neural Engine    │   │ Neural Engine    │
│                  │   │                  │   │                  │
│ Model:           │   │ Model:           │   │ Model:           │
│  YOLOv8n PyTorch │   │  yolov8n.mlmodel │   │  yolov8n.mlmodel │
│  Full precision  │   │  Optimized       │   │  Optimized       │
│                  │   │                  │   │                  │
│ 💾 Size: N/A     │   │ 💾 Size: ~6MB    │   │ 💾 Size: ~6MB    │
│ 🌐 Need: WiFi    │   │ ✅ Need: None    │   │ ✅ Need: None    │
│ ⏱️ Speed: 0.5-1s │   │ ⚡ Speed: ~100ms │   │ ⚡ Speed: ~100ms │
│ 🔒 Privacy: Med  │   │ 🔒 Privacy: High │   │ 🔒 Privacy: High │
└────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘
         │                      │                      │
         └──────────────────────┴──────────────────────┘
                                │
                    ✅ DETECTED INGREDIENTS
                    ["Tomato", "Cheese", "Chicken"]
                                │
                                ▼
                    💭 User Input: "pasta"
                                │

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                     🤖 STAGE 2: RECIPE GENERATION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│ 📱 iPhone MLX    │   │ 📱 iPhone MLX    │   │ 🖥️ Mac Ollama    │
├──────────────────┤   ├──────────────────┤   ├──────────────────┤
│ Model:           │   │ Model:           │   │ Model:           │
│  Qwen2.5-0.5B    │   │  Qwen2.5-0.5B    │   │  Qwen2.5:3b      │
│  4-bit quantized │   │  4-bit quantized │   │  Full model      │
│                  │   │                  │   │                  │
│ 💾 Size: ~300MB  │   │ 💾 Size: ~300MB  │   │ 💾 Size: ~2GB    │
│ 🧠 Params: 500M  │   │ 🧠 Params: 500M  │   │ 🧠 Params: 3B    │
│                  │   │                  │   │                  │
│ 🖥️ Hardware:     │   │ 🖥️ Hardware:     │   │ 🖥️ Hardware:     │
│   iPhone GPU     │   │   iPhone GPU     │   │   Mac GPU (M3)   │
│   (Metal)        │   │   (Metal)        │   │   (Metal)        │
│                  │   │                  │   │                  │
│ 🌐 Need: None    │   │ ✅ Need: None    │   │ 🌐 Need: WiFi    │
│ ⏱️ Speed: 10-30s │   │ ⏱️ Speed: 10-30s │   │ ⚡ Speed: 5-10s  │
│ 🎯 Quality: ⭐⭐  │   │ 🎯 Quality: ⭐⭐  │   │ 🎯 Quality: ⭐⭐⭐ │
│ 🔒 Privacy: High │   │ 🔒 Privacy: High │   │ 🔒 Privacy: High │
└────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘
         │                      │                      │
         └──────────────────────┴──────────────────────┘
                                │
                    📖 GENERATED RECIPE (JSON)
                    {
                      title: "Chicken Tomato Pasta",
                      ingredients: [...],
                      steps: [...],
                      nutrition: {...}
                    }
                                │

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                        📱 STAGE 3: DISPLAY TO USER
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

                     ┌─────────────────────────┐
                     │  📱 Recipe Detail View  │
                     ├─────────────────────────┤
                     │ 📖 Chicken Tomato Pasta │
                     │ ⏱️ 25 min | 👥 4 servings│
                     │ 💪 Easy                 │
                     ├─────────────────────────┤
                     │ 🥗 INGREDIENTS (8)      │
                     │  • Chicken: 300g        │
                     │  • Tomato: 3 pcs        │
                     │  • Cheese: 100g         │
                     │  • ...                  │
                     ├─────────────────────────┤
                     │ 👨‍🍳 STEPS (6)           │
                     │  1. Boil pasta...       │
                     │  2. Cook chicken...     │
                     │  3. Add tomatoes...     │
                     │  • ...                  │
                     ├─────────────────────────┤
                     │ 📊 NUTRITION            │
                     │  Calories: 450 kcal     │
                     │  Protein: 35g           │
                     │  Carbs: 45g             │
                     └─────────────────────────┘
```

---

## Mode Comparison Table

| Mode | Detection | Recipe | Privacy | Internet | Speed | Quality | Best For |
|------|-----------|--------|---------|----------|-------|---------|----------|
| **Server** | ☁️ AWS EC2 | 📱 MLX 0.5B | ⚠️ Partial | ⚠️ Required | Medium | Good | Simulator |
| **Local** | 📱 CoreML | 📱 MLX 0.5B | ✅ 100% | ✅ Offline | Fast | Good | Production |
| **Developer** | 📱 CoreML | 🖥️ Ollama 3B | ✅ 100% | ⚠️ Local Net | Fastest | Excellent | Development |

---

## Detailed Data Flow

### 1. Server Mode Flow
```
User Photo → Upload to AWS EC2 → YOLOv8n Detection (PyTorch) → Ingredients
                                                                      ↓
                                  JSON Response to iOS App
                                                                      ↓
                                  MLX on iPhone → Recipe Generation → Display
```

### 2. Local Mode Flow (Recommended)
```
User Photo → CoreML YOLO (Neural Engine) → Ingredients
                                              ↓
                         MLX on iPhone → Recipe Generation → Display
                         (100% Offline, No Server)
```

### 3. Developer Mode Flow
```
User Photo → CoreML YOLO (Neural Engine) → Ingredients
                                              ↓
                    HTTP to Mac → Ollama (Qwen2.5:3b) → Recipe → Display
                    (Better quality, faster generation)
```

---

## Technology Stack by Component

### iOS Application Layer
```
├── SwiftUI Views (UI)
├── ViewModels (MVVM)
├── Services Layer
│   ├── APIClient (Server communication)
│   ├── LocalInferenceService (CoreML detection)
│   ├── MLXRecipeGenerator (MLX recipe generation)
│   └── LocalLLMRecipeGenerator (Ollama communication)
└── Models (Data structures)
```

### Detection Layer
```
Server Mode:
├── FastAPI Backend (Python 3.13)
├── YOLOv8n (PyTorch 2.8.0)
├── Ultralytics 8.3.203
└── AWS EC2 (Docker container)

Local/Developer Mode:
├── CoreML Framework
├── Vision Framework
├── Neural Engine
└── YOLOv8n (converted to .mlmodelc)
```

### Recipe Generation Layer
```
Server/Local Mode:
├── MLX Framework (Apple Silicon)
├── MLXLLM
├── Qwen2.5-0.5B-Instruct-4bit
├── HuggingFace Hub (model download)
└── iPhone GPU (Metal acceleration)

Developer Mode:
├── Ollama (installed via Homebrew)
├── Qwen2.5:3b (2GB model)
├── Mac GPU (Metal acceleration)
└── HTTP API (localhost:11434)
```

---

## Network Communication

### Server Mode
```
iOS App ──HTTP POST──> AWS EC2 Backend
        (Image JPEG)
        
AWS EC2 ──HTTP Response──> iOS App
        (JSON: ingredients, confidence)

iOS MLX ──Local Inference──> Recipe
        (No network)
```

### Local Mode
```
All processing on-device:
├── CoreML (Neural Engine)
├── MLX (GPU)
└── No network communication
```

### Developer Mode
```
iOS App ──HTTP POST──> Mac (Ollama)
        (JSON: ingredients, meal type)
        
Mac Ollama ──HTTP Response──> iOS App
        (JSON: complete recipe)
        
Local network only (192.168.x.x)
```

---

## Hardware Requirements by Mode

### Server Mode
- **iOS**: Any device with iOS 16+ (Simulator supported)
- **Server**: AWS EC2 t2.micro (1 vCPU, 1GB RAM)
- **Internet**: Required for detection

### Local Mode
- **iOS**: iPhone 12+ (A14 Bionic or newer)
- **RAM**: 2GB+ available
- **Storage**: ~500MB for MLX model
- **Internet**: Only for initial model download

### Developer Mode
- **iOS**: iPhone 12+ (A14 Bionic or newer)
- **Mac**: M1/M2/M3 with 8GB+ RAM
- **Network**: Local WiFi connection
- **Storage**: ~2GB for Ollama model on Mac

---

## Performance Metrics

### Detection Speed
| Mode | Time | Hardware |
|------|------|----------|
| Server | 500ms-1s + network | AWS EC2 CPU |
| Local | ~100ms | Neural Engine |
| Developer | ~100ms | Neural Engine |

### Recipe Generation Speed
| Mode | Time | Hardware | Model |
|------|------|----------|-------|
| Server | 10-30s | iPhone GPU | 0.5B |
| Local | 10-30s | iPhone GPU | 0.5B |
| Developer | 5-10s | Mac GPU | 3B |

### Recipe Quality
| Mode | Quality | Reason |
|------|---------|--------|
| Server | Good | 0.5B model, limited parameters |
| Local | Good | 0.5B model, limited parameters |
| Developer | Excellent | 3B model, 6x more parameters |

---

## CI/CD Integration

### Backend (Server Mode)
```
GitHub Push → GitHub Actions
    ↓
pytest (Unit + API tests)
    ↓
Docker Build (PyTorch CPU)
    ↓
Push to Docker Hub
    ↓
Deploy to AWS EC2
    ↓
Health Check
```

### iOS Application
```
GitHub Push → GitHub Actions
    ↓
xcodebuild (Build)
    ↓
XCTest (Unit tests)
    ↓
XCUITest (UI tests)
    ↓
Optional: TestFlight Upload
```

---

## Security & Privacy

### Server Mode
- ⚠️ Images uploaded to AWS EC2
- ⚠️ Temporary storage on server
- ✅ HTTPS encryption in transit
- ✅ Recipe generation on-device

### Local Mode
- ✅ All data stays on device
- ✅ No network communication
- ✅ No cloud storage
- ✅ Complete privacy

### Developer Mode
- ✅ All data on local network
- ✅ No cloud services
- ✅ Data between iPhone and Mac only
- ✅ Local network only

---

## Cost Analysis

| Mode | Monthly Cost | Notes |
|------|-------------|-------|
| **Server** | ~$8-10 | AWS EC2 t2.micro (if running 24/7) |
| **Local** | $0 | All on-device |
| **Developer** | $0 | Local Mac + iPhone only |

**Recommendation for Production**: Use **Local Mode** to eliminate server costs.

