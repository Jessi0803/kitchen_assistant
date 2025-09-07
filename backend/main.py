from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
import random
import time
import io
from PIL import Image

app = FastAPI(
    title="Kitchen Assistant API",
    description="Edge-AI Kitchen Assistant Backend API",
    version="1.0.0"
)

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
    Detect ingredients in uploaded fridge image.
    For week 1 demo: returns mock data to demonstrate API structure.
    """
    start_time = time.time()
    
    # Validate image file
    if not image.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    try:
        # Read and validate image
        image_data = await image.read()
        pil_image = Image.open(io.BytesIO(image_data))
        
        # Simulate processing time
        await asyncio.sleep(1.5)  # Simulate AI processing
        
        # Mock ingredient detection
        detected_count = random.randint(4, 8)
        detected_ingredients = random.sample(MOCK_INGREDIENTS, detected_count)
        confidence_scores = [round(random.uniform(0.7, 0.95), 2) for _ in detected_ingredients]
        
        processing_time = time.time() - start_time
        
        return DetectionResponse(
            ingredients=detected_ingredients,
            confidence=confidence_scores,
            processing_time=processing_time
        )
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Image processing failed: {str(e)}")

@app.post("/api/recipes", response_model=Recipe)
async def generate_recipe(request: RecipeRequest):
    """
    Generate recipe based on ingredients and user preferences.
    For week 1 demo: returns mock recipe to demonstrate API structure.
    """
    try:
        # Simulate recipe generation time
        await asyncio.sleep(2.0)
        
        # Generate mock recipe
        recipe = generate_mock_recipe(request)
        return recipe
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Recipe generation failed: {str(e)}")

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