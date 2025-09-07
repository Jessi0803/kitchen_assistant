# Edge-AI Kitchen Assistant

A fully offline macOS companion that takes one photo of your fridge, combines it with whatever meal you're craving, and instantly delivers a step-by-step recipe, while protecting your privacy by keeping all vision, language, and preference models entirely on your M-series Mac.

## Architecture Overview

```
┌─────────────────────────┐    ┌─────────────────────────┐
│    iOS Client App       │    │      Backend Services   │
│      (SwiftUI)          │    │                         │
├─────────────────────────┤    ├─────────────────────────┤
│                         │    │                         │
│  ① Camera/Photos        │    │  ④ API Gateway          │
│  ② Image Preprocessing  │───▶│     (REST/JSON)         │
│  ③ Local YOLO (Optional)│    │     /detect, /recipes   │
│                         │    │                         │
│  ⑧ UI/Interaction       │◀───│  ⑤ Detection Service    │
│    - Detection boxes    │    │     (YOLO/GPU)          │
│    - Ingredients list   │    │                         │
│    - Recipe display     │    │  ⑥ Recipe & Chat Service │
│                         │    │     (LLM + Retrieval)   │
│  API Client +           │    │                         │
│  InferenceProvider      │    │  ⑦ Preferences DB       │
│                         │    │     (PostgreSQL)        │
└─────────────────────────┘    └─────────────────────────┘
```

## Data Flow

1. **Photo Input**: User takes/selects fridge photo
2. **Preprocessing**: App compresses and cleans image
3. **Local Inference (Optional)**: YOLO tiny on-device for validation
4. **Remote Detection**: Upload to `/detect` endpoint
5. **Ingredient Detection**: Server returns ingredient list
6. **Recipe Generation**: Send ingredients + preferences to `/recipes`
7. **Recipe Response**: Backend returns complete recipe JSON
8. **UI Rendering**: App displays results to user

## Tech Stack

### Frontend (iOS)
- SwiftUI for UI
- Core ML for on-device inference (optional)
- URLSession for API calls

### Backend
- Python FastAPI for REST API
- YOLO (Ultralytics) for object detection
- Ollama/Llama for recipe generation
- PostgreSQL for user preferences
- Docker for deployment

## Getting Started

### Prerequisites
- macOS with M-series chip
- Xcode 15+
- Python 3.11+
- Docker (optional)

### Installation

1. Clone the repository
2. Set up iOS app in Xcode
3. Install Python dependencies
4. Run backend services
5. Test end-to-end workflow

## Development Philosophy

Following professor's guidance:
- **Software Engineering First**: Complete system architecture before AI optimization
- **Modular Design**: Easy to swap models and adjust deployment locations
- **Start Local, Move Remote**: Validate with on-device models, then migrate to backend
- **Flexible Model Placement**: Architecture supports local or remote inference

## Project Structure

```
edge-ai-kitchen-assistant/
├── ios-app/              # SwiftUI iOS application
├── backend/              # Python backend services
│   ├── api/             # FastAPI REST endpoints
│   ├── detection/       # YOLO food detection
│   ├── recipes/         # LLM recipe generation
│   ├── models/          # ML model files
│   └── db/              # Database schemas
├── docs/                # Documentation
└── assets/              # Images, samples, etc.
```