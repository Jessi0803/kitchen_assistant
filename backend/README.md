# Kitchen Assistant Backend

FastAPI backend for the Edge-AI Kitchen Assistant app.

## Quick Start

### 1. Start the Backend Server

```bash
cd backend
./start.sh
```

The server will start at `http://localhost:8000`

### 2. Test the API

```bash
# In another terminal
python3 test_api.py
```

### 3. View API Documentation

Open your browser and go to: `http://localhost:8000/docs`

## API Endpoints

### Health Check
- `GET /health` - Check server status

### Ingredient Detection
- `POST /api/detect` - Upload fridge image and detect ingredients
- **Input**: Image file (JPEG/PNG)
- **Output**: List of detected ingredients with confidence scores

### Recipe Generation
- `POST /api/recipes` - Generate recipe from ingredients
- **Input**: JSON with ingredients, meal craving, dietary restrictions
- **Output**: Complete recipe with ingredients, instructions, nutrition info

## For Week 1 Demo

This backend provides:
- ✅ Complete REST API structure
- ✅ Mock ingredient detection (simulates AI)
- ✅ Mock recipe generation (simulates LLM)
- ✅ Proper error handling and validation
- ✅ Interactive API documentation
- ✅ CORS support for iOS app integration

## Architecture

```
Backend Structure:
├── main.py              # FastAPI application
├── requirements.txt     # Python dependencies
├── start.sh            # Startup script
├── test_api.py         # API testing script
└── README.md           # This file
```

## Next Steps

1. **Week 2+**: Replace mock data with real YOLO model
2. **Week 3+**: Integrate actual LLM for recipe generation
3. **Week 4+**: Add user preferences database
4. **Production**: Add authentication, rate limiting, deployment config