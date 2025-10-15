# Edge-AI Kitchen Assistant - Progress Report

## Progress update
generate personalized recipes using a local LLM, completely offline and free.

---

## Technical Architecture

### Recipe Generation: Qwen2.5:3b LLM
- **LLM Engine**: Ollama (local inference, no cloud required)
- **Model**: Qwen2.5:3b (3 billion parameters, ~2GB)
- **Hardware Acceleration**: Metal GPU on Apple Silicon
- **Performance**: 40-60 tokens/second on M3 MacBook Air

### Tech Stack
**Backend (Python)**:
- FastAPI for async web framework
- PyTorch + Ultralytics for YOLO inference

**Frontend (iOS)**:
- SwiftUI with native async/await networking


---

## Complete Data Flow



### Recipe Generation

```
1. User enters meal craving → "pasta"
   ↓
2. iOS sends request → Backend
   {"ingredients": [...], "mealCraving": "pasta"}
   ↓
3. Backend constructs LLM prompt → 200-250 tokens
   "You are a professional chef. Available ingredients: Tomato, Cheese, Chicken.
    Desired meal: pasta. Generate a recipe in JSON format..."
   ↓
4. Ollama processes with Qwen2.5:3b
   Tokenization: Text → Token IDs (200-250 tokens)
   Generation: Autoregressive generation (~1200 tokens)
   Time: 15-30 seconds
   ↓
5. LLM returns JSON recipe → ~2KB JSON
   {
     "title": "Chicken Tomato Pasta",
     "ingredients": [8 items],
     "instructions": [6 steps],
     "nutrition_info": {...}
   }
   ↓
6. Backend validates and returns → iOS
   ↓
7. iOS parses and displays → Full recipe UI
   (snake_case → camelCase conversion, UUID generation for list items)
```


## Next Steps

Add local LLM with toggle option for users to switch between local and server-side recipe generation.
---

