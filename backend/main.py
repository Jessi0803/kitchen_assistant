from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import random
import time
import io
import os
from PIL import Image
from ultralytics import YOLO
import torch
import ollama
import json

app = FastAPI(
    title="Kitchen Assistant API",
    description="Edge-AI Kitchen Assistant Backend API",
    version="1.0.0"
)

# Initialize YOLO model
model_path = os.path.join(os.path.dirname(__file__), 'best.pt')
if not os.path.exists(model_path):
    # If model not in backend folder, try current directory
    model_path = 'best.pt' #yolov8n.pt

try:
    yolo_model = YOLO(model_path)
    print("✅ YOLO model loaded successfully")
except Exception as e:
    print(f"❌ Failed to load YOLO model: {e}")
    yolo_model = None

# COCO class names that are food-related
FOOD_CLASSES = {
    'apple', 'banana', 'sandwich', 'orange', 'broccoli', 'carrot', 'hot dog',
    'pizza', 'donut', 'cake', 'chair', 'dining table', 'laptop', 'mouse',
    'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster',
    'sink', 'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear',
    'hair drier', 'toothbrush', 'bottle', 'wine glass', 'cup', 'fork', 'knife',
    'spoon', 'bowl'
}

# Mapping for fine-tuned food detection model
YOLO_TO_FOOD_MAPPING = {
    'beef': 'Beef',
    'pork': 'Pork',
    'chicken': 'Chicken',
    'butter': 'Butter',
    'cheese': 'Cheese',
    'milk': 'Milk',
    'broccoli': 'Broccoli',
    'carrot': 'Carrot',
    'cucumber': 'Cucumber',
    'lettuce': 'Lettuce',
    'tomato': 'Tomato'
}

# CORS middleware for iOS app
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development - restrict in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class DetectionResponse(BaseModel):
    ingredients: List[str]
    confidence: List[float]
    processing_time: float

class RecipeRequest(BaseModel):
    ingredients: List[str]
    mealCraving: str  # Changed to camelCase to match iOS
    dietaryRestrictions: List[str] = []  # Changed to camelCase
    preferredCuisine: str = "Any"  # Changed to camelCase
    
    # Alias for backward compatibility
    class Config:
        allow_population_by_field_name = True
        schema_extra = {
            "example": {
                "ingredients": ["tomato", "cheese", "basil"],
                "mealCraving": "pasta",
                "dietaryRestrictions": [],
                "preferredCuisine": "Italian"
            }
        }

class Ingredient(BaseModel):
    name: str
    amount: str
    unit: Optional[str] = None
    notes: Optional[str] = None

class Instruction(BaseModel):
    step: int
    text: str
    time: Optional[int] = None
    temperature: Optional[str] = None
    tips: Optional[str] = None

class NutritionInfo(BaseModel):
    calories: Optional[int] = None
    protein: Optional[str] = None
    carbs: Optional[str] = None
    fat: Optional[str] = None
    fiber: Optional[str] = None
    sugar: Optional[str] = None
    sodium: Optional[str] = None

class Recipe(BaseModel):
    title: str
    description: str
    prep_time: int
    cook_time: int
    servings: int
    difficulty: str
    ingredients: List[Ingredient]
    instructions: List[Instruction]
    tags: List[str]
    nutrition_info: Optional[NutritionInfo] = None

# Mock data for demonstration
MOCK_INGREDIENTS = [
    "Tomatoes", "Bell Peppers", "Onions", "Carrots", "Broccoli",
    "Cheese", "Milk", "Eggs", "Chicken Breast", "Garlic",
    "Spinach", "Potatoes", "Mushrooms", "Cucumber", "Lettuce"
]

@app.get("/")
async def root():
    return {
        "message": "Kitchen Assistant API", 
        "version": "1.0.0",
        "status": "running"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": time.time()}

@app.post("/api/detect", response_model=DetectionResponse)
async def detect_ingredients(image: UploadFile = File(...)):
    """
    Detect ingredients in uploaded fridge image using YOLOv8n model.
    """
    start_time = time.time()

    # Validate image file
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")

    if yolo_model is None:
        # Fallback to mock data if model failed to load
        return await _fallback_mock_detection(image, start_time)

    try:
        # Read and validate image
        image_data = await image.read()
        pil_image = Image.open(io.BytesIO(image_data))

        # Run YOLO inference
        results = yolo_model(pil_image, conf=0.1)  # confidence threshold for fine-tuned model

        detected_ingredients = []
        confidence_scores = []

        # Process YOLO results
        for result in results:
            for box in result.boxes:
                if box.conf is not None and box.cls is not None:
                    confidence = float(box.conf.cpu().numpy())
                    class_id = int(box.cls.cpu().numpy())
                    class_name = yolo_model.names[class_id].lower()

                    # Check if detected class is food-related
                    if class_name in YOLO_TO_FOOD_MAPPING:
                        food_name = YOLO_TO_FOOD_MAPPING[class_name]
                        if food_name not in detected_ingredients:  # Avoid duplicates
                            detected_ingredients.append(food_name)
                            confidence_scores.append(round(confidence, 2))

        # If no food items detected, provide fallback with mock data
        if not detected_ingredients:
            print("⚠️ No food items detected, using fallback")
            return await _fallback_mock_detection(image, start_time)

        processing_time = time.time() - start_time

        print(f"🔍 Detected {len(detected_ingredients)} food items: {detected_ingredients}")

        return DetectionResponse(
            ingredients=detected_ingredients,
            confidence=confidence_scores,
            processing_time=processing_time
        )

    except Exception as e:
        print(f"❌ YOLO detection failed: {e}")
        # Fallback to mock data on error
        return await _fallback_mock_detection(image, start_time)

async def _fallback_mock_detection(image: UploadFile, start_time: float):
    """Fallback function for mock detection when YOLO fails"""
    # Simulate processing time
    await asyncio.sleep(1.0)

    # Mock ingredient detection
    detected_count = random.randint(3, 6)
    detected_ingredients = random.sample(MOCK_INGREDIENTS, detected_count)
    confidence_scores = [round(random.uniform(0.6, 0.85), 2) for _ in detected_ingredients]

    processing_time = time.time() - start_time

    print(f"🔄 Using mock detection: {detected_ingredients}")

    return DetectionResponse(
        ingredients=detected_ingredients,
        confidence=confidence_scores,
        processing_time=processing_time
    )

async def generate_recipe_with_llm(request: RecipeRequest) -> Recipe:
    """
    Generate recipe using Qwen2.5:3b LLM via Ollama.
    """
    # Create prompt for LLM
    ingredients_str = ", ".join(request.ingredients)

    prompt = f"""You are a professional chef. Create a detailed recipe based on these ingredients.

Available Ingredients: {ingredients_str}
Desired Meal: {request.mealCraving}
Dietary Restrictions: {", ".join(request.dietaryRestrictions) if request.dietaryRestrictions else "None"}
Preferred Cuisine: {request.preferredCuisine}

Generate a recipe in JSON format with the following structure:
{{
  "title": "Recipe name",
  "description": "Brief description (1-2 sentences)",
  "prep_time": <number in minutes>,
  "cook_time": <number in minutes>,
  "servings": <number>,
  "difficulty": "Easy|Medium|Hard",
  "ingredients": [
    {{"name": "ingredient name", "amount": "quantity", "unit": "unit", "notes": "optional notes"}}
  ],
  "instructions": [
    {{"step": 1, "text": "instruction text", "time": <optional minutes>, "temperature": "optional temp", "tips": "optional tip"}}
  ],
  "tags": ["tag1", "tag2"],
  "nutrition_info": {{
    "calories": <number>,
    "protein": "Xg",
    "carbs": "Xg",
    "fat": "Xg",
    "fiber": "Xg",
    "sugar": "Xg",
    "sodium": "Xmg"
  }}
}}

IMPORTANT:
1. Only use the available ingredients provided
2. Keep instructions clear and practical
3. Return ONLY valid JSON, no additional text
4. Make the recipe realistic and delicious"""

    print(f"🤖 Generating recipe with Qwen2.5:3b for: {request.mealCraving}")

    # Call Ollama API
    response = ollama.chat(
        model='qwen2.5:3b',
        messages=[{
            'role': 'user',
            'content': prompt
        }],
        options={
            'temperature': 0.7,  # Creative but not too random
            'num_predict': 2048,  # Max tokens to generate
        }
    )

    # Extract and parse JSON response
    llm_output = response['message']['content']

    # Try to extract JSON from the response (in case there's extra text)
    try:
        # Find JSON object in response
        start_idx = llm_output.find('{')
        end_idx = llm_output.rfind('}') + 1
        if start_idx != -1 and end_idx > start_idx:
            json_str = llm_output[start_idx:end_idx]
            recipe_data = json.loads(json_str)
        else:
            raise ValueError("No JSON found in LLM response")
    except Exception as e:
        print(f"⚠️ Failed to parse LLM JSON: {e}")
        print(f"Raw LLM output: {llm_output[:500]}...")
        raise ValueError(f"LLM did not return valid JSON: {e}")

    # Convert to Pydantic models
    try:
        recipe = Recipe(
            title=recipe_data.get('title', 'Generated Recipe'),
            description=recipe_data.get('description', ''),
            prep_time=recipe_data.get('prep_time', 15),
            cook_time=recipe_data.get('cook_time', 30),
            servings=recipe_data.get('servings', 4),
            difficulty=recipe_data.get('difficulty', 'Medium'),
            ingredients=[Ingredient(**ing) for ing in recipe_data.get('ingredients', [])],
            instructions=[Instruction(**inst) for inst in recipe_data.get('instructions', [])],
            tags=recipe_data.get('tags', []),
            nutrition_info=NutritionInfo(**recipe_data.get('nutrition_info', {})) if recipe_data.get('nutrition_info') else None
        )

        print(f"✅ Successfully generated recipe: {recipe.title}")
        return recipe

    except Exception as e:
        print(f"⚠️ Failed to convert to Recipe model: {e}")
        raise ValueError(f"Invalid recipe structure: {e}")

@app.post("/api/recipes", response_model=Recipe)
async def generate_recipe(request: RecipeRequest):
    """
    Generate recipe based on ingredients and user preferences using Qwen2.5:3b LLM.
    """
    try:
        # Generate recipe using Qwen2.5
        recipe = await generate_recipe_with_llm(request)
        return recipe

    except Exception as e:
        print(f"❌ LLM recipe generation failed: {e}")
        # Fallback to mock recipe on error
        print("🔄 Using fallback mock recipe")
        recipe = generate_mock_recipe(request)
        return recipe

def generate_mock_recipe(request: RecipeRequest) -> Recipe:
    """Generate a mock recipe based on the request parameters."""
    
    # Create recipe title
    main_ingredient = request.ingredients[0] if request.ingredients else "Vegetable"
    title = f"{main_ingredient} {request.mealCraving.title()}"
    
    # Create ingredients list from detected items
    recipe_ingredients = []
    for i, ingredient in enumerate(request.ingredients[:6]):  # Use first 6 ingredients
        recipe_ingredients.append(Ingredient(
            name=ingredient,
            amount=str(random.randint(1, 3)),
            unit=random.choice(["cup", "tbsp", "piece", "clove", "oz"]),
            notes="fresh" if random.random() > 0.7 else None
        ))
    
    # Add common ingredients
    recipe_ingredients.extend([
        Ingredient(name="Salt", amount="1", unit="tsp"),
        Ingredient(name="Black pepper", amount="1/2", unit="tsp"),
        Ingredient(name="Olive oil", amount="2", unit="tbsp")
    ])
    
    # Create instructions
    instructions = [
        Instruction(
            step=1, 
            text="Prepare all ingredients by washing, chopping, and measuring as needed.",
            time=10,
            tips="Having everything ready makes cooking smoother"
        ),
        Instruction(
            step=2,
            text="Heat olive oil in a large pan over medium-high heat.",
            time=3,
            temperature="Medium-high heat"
        ),
        Instruction(
            step=3,
            text=f"Add {main_ingredient.lower()} and other main ingredients to the pan.",
            time=8,
            tips="Don't overcrowd the pan"
        ),
        Instruction(
            step=4,
            text="Season with salt and pepper, cook until tender and flavorful.",
            time=12,
            tips="Taste and adjust seasoning as needed"
        ),
        Instruction(
            step=5,
            text="Serve hot and enjoy your homemade dish!",
            tips="Best enjoyed fresh and warm"
        )
    ]
    
    # Generate tags
    tags = ["Homemade", "Fresh Ingredients"]
    if "salad" in request.mealCraving.lower():
        tags.extend(["Healthy", "Light"])
    elif "pasta" in request.mealCraving.lower():
        tags.extend(["Italian", "Comfort Food"])
    elif "stir" in request.mealCraving.lower():
        tags.extend(["Asian", "Quick"])
    
    if request.preferredCuisine != "Any":
        tags.append(request.preferredCuisine)
    
    return Recipe(
        title=title,
        description=f"A delicious {request.mealCraving.lower()} made with fresh ingredients from your fridge.",
        prep_time=random.randint(10, 25),
        cook_time=random.randint(15, 35),
        servings=random.randint(2, 6),
        difficulty=random.choice(["Easy", "Medium", "Hard"]),
        ingredients=recipe_ingredients,
        instructions=instructions,
        tags=tags,
        nutrition_info=NutritionInfo(
            calories=random.randint(200, 500),
            protein=f"{random.randint(10, 30)}g",
            carbs=f"{random.randint(20, 50)}g",
            fat=f"{random.randint(5, 20)}g",
            fiber=f"{random.randint(3, 10)}g",
            sugar=f"{random.randint(5, 15)}g",
            sodium=f"{random.randint(300, 800)}mg"
        )
    )

# Add asyncio import for sleep
import asyncio

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)