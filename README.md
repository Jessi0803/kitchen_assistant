# Edge-AI Kitchen Assistant

1. built a complete frontend-backend separation architecture for a Kitchen Assistant App: an iOS SwiftUI frontend with image upload, ingredient detection, and recipe display features.

2. paired with a Python FastAPI backend providing RESTful API services including image processing and recipe generation endpoints. 

3. A fully offline macOS companion that takes one photo of your fridge, combines it with whatever meal you're craving, and instantly delivers a step-by-step recipe.

4. using Mock AI services to simulate YOLO ingredient detection and LLM recipe generation


## Current Architecture

### System Overview
```
iOS SwiftUI App ← REST API → FastAPI Backend (localhost:8000)
                               ↓
                            Mock AI Services
```

### Complete Frontend-Backend Architecture Diagram
![App Architecture](image.png)

## Current Implementation Overview

### Complete Frontend-Backend Architecture
- **Native iOS SwiftUI App** with full user interface
- **Python FastAPI Backend** with RESTful API services  
- **End-to-End Data Flow** from camera capture to recipe display

## iOS App Features & Implementation

### 1. Home Tab - Welcome & Overview
**Functionality:**
- Welcome screen showcasing app feature overview
- Four main features introduction: fridge scanning, AI ingredient recognition, personalized recipes
- Clear navigation guidance for users

**Technical Implementation:**
- **ContentView.swift**: Main tab navigation with SwiftUI TabView
- State management using `@State` for selected tab tracking
- Custom welcome UI with SF Symbols icons and structured layout

### 2. Camera Tab - Photo Capture & Processing
**Functionality:**
- **Photo Capture**: Support for photo library selection
- **Image Upload**: Automatic compression and upload to backend API
- **Ingredient Detection**: Send images to `/api/detect` endpoint for processing
- **Interactive Input**: User input for desired meal type
- **Real-time Feedback**: Processing status and loading animations

**Technical Implementation:**
- **CameraView.swift**: Camera interface and API integration
- **ImagePicker.swift**: UIKit bridge for camera and photo library access
- **APIClient.swift**: HTTP communication layer with multipart form data upload
```swift
// Key technical features
- Multipart form data image upload
- Async/await network requests
- Comprehensive error handling
- Image compression (JPEG 0.8 quality)
- Loading state management
```

### 3. Recipe Tab - Complete Recipe Display
**Functionality:**
- **Complete Recipe Information**: Title, description, prep time, cook time
- **Detailed Ingredient List**: Including quantities, units, and notes
- **Step-by-Step Cooking Instructions**: Each step with timing, temperature, and tips
- **Nutrition Information**: Calories, protein, carbs, etc.
- **Difficulty Indicators**: Easy/Medium/Hard with color coding

**Technical Implementation:**
- **RecipeView.swift**: Rich recipe display with structured layout
- **Models/Recipe.swift**: Complete data models with proper serialization
```swift
// Data structures
struct Recipe {
    - Complete recipe information
    - Codable for JSON serialization
    - UUID for unique identification
}
struct Ingredient {
    - Name, amount, unit, notes
    - displayText computed property
}
struct Instruction {
    - Step number, text, time, temperature, tips
}
```

### 4. Settings Tab - User Preferences
**Functionality:**
- Local AI processing options
- Dietary preferences and restrictions
- Preferred cuisine type selection
- App version and AI model information

**Technical Implementation:**
- SwiftUI Form with Toggle and Picker controls
- @State property wrappers for settings persistence
- Structured sections for different preference categories

## Backend API Features & Implementation

### FastAPI Architecture & Endpoints
```python
# Core endpoints
GET /                    # API status and version info
GET /health             # Health check with timestamp
POST /api/detect        # Image upload & ingredient detection
POST /api/recipes       # Recipe generation from ingredients
GET /docs               # Interactive Swagger documentation
```

### Ingredient Detection Service (`/api/detect`)
**Functionality:**
- **Image Validation**: Check file format (JPEG/PNG)
- **Image Processing**: Basic processing using Pillow
- **Mock YOLO Recognition**: Simulate AI vision model
- **Response**: 4-8 random ingredients with confidence scores (0.7-0.95)
- **Processing Time**: Simulate real AI processing delay (1.5 seconds)

**Technical Implementation:**
```python
# Key backend features
- FastAPI with automatic OpenAPI docs
- CORS middleware for iOS cross-origin requests  
- Pydantic models for request/response validation
- Multipart file upload handling
- Comprehensive error responses
- Mock AI processing with realistic delays

async def detect_ingredients(image: UploadFile):
    # Image validation and processing
    # Mock YOLO simulation
    # Structured JSON response
```

### Recipe Generation Service (`/api/recipes`)
**Functionality:**
- **Input Parameters**: Ingredient list, meal type, dietary restrictions, preferred cuisine
- **Mock LLM Generation**: Create structured recipes based on input
- **Complete Recipe**: Ingredients, steps, nutrition, tags
- **Customized Content**: Adjust content based on user preferences
- **Processing Time**: Simulate LLM processing time (2 seconds)

**Technical Implementation:**
```python
# Recipe generation logic
class RecipeRequest(BaseModel):
    ingredients: List[str]
    mealCraving: str
    dietaryRestrictions: List[str] = []
    preferredCuisine: str = "Any"

def generate_mock_recipe(request: RecipeRequest) -> Recipe:
    # Dynamic recipe creation based on detected ingredients
    # Structured instruction generation with timing and tips
    # Nutrition information calculation
    # Tag generation based on cuisine and meal type
```

### Data Flow Architecture
```
iOS App Request → FastAPI Validation → Mock AI Processing → Structured Response
Image Upload → Pillow Processing → YOLO Simulation → Ingredient JSON
Recipe Request → Parameter Validation → LLM Simulation → Complete Recipe JSON
```

## Mock AI Services Implementation

### YOLO Ingredient Detection Simulation
**Technical Details:**
- Predefined pool of 15 common ingredients
- Random selection of 4-8 ingredients per request
- Confidence score generation (0.7-0.95 range)
- Realistic processing time simulation (asyncio.sleep)

```python
MOCK_INGREDIENTS = [
    "Tomatoes", "Bell Peppers", "Onions", "Carrots", "Broccoli",
    "Cheese", "Milk", "Eggs", "Chicken Breast", "Garlic",
    # ... more ingredients
]

# Simulation logic
detected_count = random.randint(4, 8)
detected_ingredients = random.sample(MOCK_INGREDIENTS, detected_count)
confidence_scores = [round(random.uniform(0.7, 0.95), 2) for _ in detected_ingredients]
```

### LLM Recipe Generation Simulation  
**Technical Details:**
- Recipe creation based on detected ingredients
- Dynamic content adjustment based on meal type
- Complete cooking instruction generation
- Nutrition information and practical cooking tips

```python
def generate_mock_recipe(request: RecipeRequest) -> Recipe:
    # Use detected ingredients as base
    # Create structured ingredients with measurements
    # Generate step-by-step instructions with timing
    # Add nutrition facts and cooking tips
    # Tag categorization based on cuisine and preferences
```

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

### 4. API Documentation
Visit `http://localhost:8000/docs` for interactive Swagger documentation

