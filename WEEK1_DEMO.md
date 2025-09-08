# Week 1 Demo - Edge-AI Kitchen Assistant

## 🎯 Demo Overview
This is the **Week 1 Demo** version showing complete software engineering architecture with frontend-backend separation. The AI models are simulated with mock data to demonstrate the full workflow.

## 📂 Project Structure

```
edge-ai-kitchen-assistant/
├── backend/                      # Python FastAPI Backend
│   ├── main.py                  # FastAPI app with endpoints
│   ├── requirements.txt         # Python dependencies
│   ├── start.sh                # Server startup script
│   ├── test_api.py             # API testing script
│   ├── README.md               # Backend documentation
│   └── venv/                   # Python virtual environment
├── ios-app/                     # iOS SwiftUI Application
│   └── KitchenAssistant/
│       ├── KitchenAssistantApp.swift    # App entry point
│       ├── Models/
│       │   └── Recipe.swift             # Data models (Recipe, Ingredient, etc.)
│       ├── Services/
│       │   └── APIClient.swift          # HTTP client for backend API
│       ├── Views/
│       │   ├── ContentView.swift        # Main tab view & home screen
│       │   ├── CameraView.swift         # Photo capture & ingredient detection
│       │   └── RecipeView.swift         # Recipe display with instructions
│       ├── Utils/
│       │   └── ImagePicker.swift        # Camera/photo library interface
│       └── Assets.xcassets/             # App icons and images
├── docs/                        # Project documentation
├── assets/                      # Sample images and resources
├── README.md                    # Main project documentation
└── WEEK1_DEMO.md               # This demo guide

```

## 🏗️ Architecture Highlights

### ✅ What's Implemented:
- **Complete iOS SwiftUI App** with 4-tab navigation
- **FastAPI Python Backend** with RESTful endpoints
- **Full data flow** from camera → API → recipe display
- **Mock AI services** (YOLO detection + LLM recipe generation)


### 📱 iOS App Features:
1. **Home Tab** - Welcome screen with feature overview
2. **Camera Tab** - Photo capture/selection, ingredient detection, recipe generation
3. **Recipe Tab** - Detailed recipe view with instructions and nutrition
4. **Settings Tab** - User preferences and app configuration

### 🖥️ Backend API Endpoints:
- `GET /` - API status and version info
- `GET /health` - Health check with timestamp
- `POST /api/detect` - Image upload & ingredient detection (mock YOLO)
- `POST /api/recipes` - Recipe generation from ingredients (mock LLM)
- `GET /docs` - Interactive Swagger API documentation

### 🧩 Core Components

#### Backend (main.py)
- **FastAPI Application** with CORS support for iOS integration
- **Detection Service** - Mock YOLO ingredient detection from uploaded images
- **Recipe Generation** - Mock LLM service creating detailed recipes
- **Data Models** - Pydantic models for API request/response validation
- **Error Handling** - Comprehensive error responses with status codes

#### iOS App Core Files
- **APIClient.swift** - HTTP client handling multipart image uploads and JSON API calls
- **Recipe.swift** - Data models with proper Swift/JSON serialization
- **CameraView.swift** - Camera interface with photo capture and API integration
- **ContentView.swift** - Main UI with tab navigation and app flow
- **RecipeView.swift** - Rich recipe display with ingredients, instructions, and nutrition

### 🔗 Data Flow Architecture
```
Image Capture → APIClient → Backend Detection → Ingredient List
     ↓
Recipe Request → APIClient → Backend Generation → Complete Recipe
     ↓
UI Display → Recipe View → Step-by-step Instructions
```

## 🚀 Quick Start Guide

### 1. Start the Backend Server
```bash
cd backend
source venv/bin/activate  # Activate virtual environment
python main.py            # Start FastAPI server
```
Server will start at `http://localhost:8000`

**Alternative using script:**
```bash
./start.sh
```

### 2. Verify Backend is Running
Test the API endpoints:
```bash
# Check server status
curl http://localhost:8000

# Test with provided script
python test_api.py
```

### 3. Open iOS Project in Xcode
```bash
open ios-app/KitchenAssistant.xcodeproj
```

### 4. Run iOS App
- Select iOS simulator (iPhone 15 recommended) or physical device
- Press ▶️ to build and run
- App will automatically connect to `localhost:8000` backend

### 5. Troubleshooting
**If port 8000 is in use:**
```bash
# Check what's using port 8000
lsof -ti :8000

# Kill the process
kill <process_id>
```

**If backend dependencies are missing:**
```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
```

## 📊 Demo Flow

### User Experience Walkthrough:

1. **Launch App** - Opens to Home tab with welcome screen
2. **Navigate to Camera** - Switch to "Scan Fridge" tab
3. **Take/Select Photo** - User captures fridge image or selects from library
4. **Image Processing** - Photo uploaded to backend `/api/detect` endpoint
5. **Mock Detection Results** - Backend returns 4-8 simulated ingredients with confidence scores
6. **Enter Meal Craving** - User inputs desired dish type (e.g., "pasta", "stir-fry")
7. **Recipe Generation** - Backend `/api/recipes` endpoint creates complete recipe
8. **Display Results** - Recipe tab shows detailed view with:
   - Ingredient list with measurements
   - Step-by-step instructions with timing
   - Nutrition information
   - Difficulty level and cooking tips

### Current App Capabilities:

✅ **Working Features:**
- Camera integration (capture + photo library)
- Image upload to backend with proper multipart encoding
- Mock ingredient detection (returns random ingredients from predefined list)
- Recipe generation based on ingredients and meal preferences
- Rich recipe display with complete cooking instructions
- Error handling for network issues and server errors
- Interactive API documentation at `http://localhost:8000/docs`

🔄 **Mock AI Services:**
- **YOLO Detection Simulation**: Returns 4-8 random ingredients with confidence scores (0.7-0.95)
- **LLM Recipe Generation**: Creates structured recipes with ingredients, instructions, timing, and nutrition
- **Processing Delays**: Simulates real AI processing time (1.5s detection, 2s recipe generation)

## 🔧 Technical Architecture

```
┌─────────────────────┐    ┌─────────────────────┐
│   iOS SwiftUI App   │    │  Python FastAPI     │
│                     │    │                     │
│  ┌─────────────────┐│    │┌─────────────────────┐│
│  │  Camera View    ││───▶││  /api/detect        ││
│  │  (Photo Capture)││    ││  (Mock YOLO)        ││
│  └─────────────────┘│    │└─────────────────────┘│
│                     │    │                     │
│  ┌─────────────────┐│    │┌─────────────────────┐│
│  │  Recipe View    ││◀───││  /api/recipes       ││
│  │  (UI Display)   ││    ││  (Mock LLM)         ││
│  └─────────────────┘│    │└─────────────────────┘│
│                     │    │                     │
│  ┌─────────────────┐│    │┌─────────────────────┐│
│  │  API Client     ││────││  CORS + Validation  ││
│  │  (HTTP Requests)││    ││  Error Handling     ││
│  └─────────────────┘│    │└─────────────────────┘│
└─────────────────────┘    └─────────────────────┘
```

## 🎓 Professor Review Points

### ✅ Software Engineering Excellence:
- **Clean Architecture** - Separation of concerns
- **API-First Design** - RESTful backend with documentation
- **Error Handling** - Proper validation and user feedback
- **Mock Implementation** - AI placeholders for development
- **Scalable Structure** - Easy to add real AI models later

### ✅ Future-Ready Design:
- **Model Flexibility** - Easy to swap mock → real AI
- **Deployment Ready** - Docker-compatible backend
- **Mobile Native** - Native iOS with SwiftUI
- **Privacy-First** - Architecture supports on-device models

## 🔧 Technical Implementation Details

### Backend Technology Stack:
- **FastAPI** - Modern Python web framework with automatic API docs
- **Pydantic** - Data validation and serialization
- **Pillow (PIL)** - Image processing and validation
- **CORS** - Cross-origin requests for iOS app integration
- **Uvicorn** - ASGI server for FastAPI

### iOS Technology Stack:
- **SwiftUI** - Modern declarative UI framework
- **Foundation/URLSession** - HTTP networking
- **UIKit Integration** - Camera and image picker
- **Observable Objects** - State management for API calls

### API Design Patterns:
- RESTful endpoints with proper HTTP status codes
- JSON request/response format
- Multipart form data for image uploads
- Comprehensive error handling with structured responses
- OpenAPI/Swagger documentation generation

### Development Best Practices:
- **Separation of Concerns** - Clear model/view/service architecture
- **Error Boundaries** - Graceful handling of network and processing errors  
- **Type Safety** - Strong typing in both Swift and Python
- **Async Programming** - Non-blocking API calls and UI updates
- **Mock-Driven Development** - AI placeholders for rapid prototyping

## 📈 Roadmap & Next Steps

### Week 2-3: AI Integration
- [ ] **Real YOLO Integration** - Replace mock detection with trained model
- [ ] **LLM Integration** - Connect to Ollama or local language model
- [ ] **Model Performance** - Optimize inference speed and accuracy

### Week 4-5: Enhanced Features  
- [ ] **User Preferences Database** - PostgreSQL backend for dietary restrictions
- [ ] **Recipe History** - Save and favorite generated recipes
- [ ] **Advanced Filtering** - Cuisine preferences, cooking time, difficulty

### Week 6-7: Production Ready
- [ ] **Core ML Integration** - On-device AI processing option
- [ ] **Authentication** - User accounts and personalization
- [ ] **Cloud Deployment** - Containerized backend with Docker

### Week 8+: Advanced Features
- [ ] **Nutritional Analysis** - Detailed macro/micro nutrient breakdown
- [ ] **Shopping Lists** - Generate grocery lists from recipes
- [ ] **Meal Planning** - Weekly meal suggestions and preparation
- [ ] **Social Features** - Share recipes and cooking tips

## 🎉 Demo Ready!

This version demonstrates:
- ✅ Complete software engineering pipeline
- ✅ Frontend-backend separation
- ✅ API documentation and testing
- ✅ Professional mobile UI/UX
- ✅ Scalable architecture for AI integration

**Perfect for Week 1 professor demonstration!** 📱🚀
