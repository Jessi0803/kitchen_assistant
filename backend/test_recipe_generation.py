#!/usr/bin/env python3
"""
Test script for recipe generation with Qwen2.5:3b
"""
import requests
import json

# Backend URL
BASE_URL = "http://localhost:8000"

def test_recipe_generation():
    """Test the /api/recipes endpoint with LLM"""

    print("🧪 Testing Recipe Generation with Qwen2.5:3b")
    print("-" * 60)

    # Test data
    test_request = {
        "ingredients": ["Tomato", "Cheese", "Chicken", "Broccoli"],
        "mealCraving": "pasta",
        "dietaryRestrictions": [],
        "preferredCuisine": "Italian"
    }

    print(f"📦 Request payload:")
    print(json.dumps(test_request, indent=2))
    print("-" * 60)

    try:
        # Send request
        print("🚀 Sending request to /api/recipes...")
        response = requests.post(
            f"{BASE_URL}/api/recipes",
            json=test_request,
            timeout=60  # LLM may take some time
        )

        # Check response
        if response.status_code == 200:
            recipe = response.json()
            print("✅ Recipe generation successful!\n")
            print("=" * 60)
            print(f"📖 Recipe: {recipe['title']}")
            print("=" * 60)
            print(f"📝 Description: {recipe['description']}")
            print(f"⏱️  Prep Time: {recipe['prep_time']} mins")
            print(f"🔥 Cook Time: {recipe['cook_time']} mins")
            print(f"👥 Servings: {recipe['servings']}")
            print(f"💪 Difficulty: {recipe['difficulty']}")
            print()
            print("🛒 Ingredients:")
            for ing in recipe['ingredients']:
                print(f"  - {ing['amount']} {ing.get('unit', '')} {ing['name']}")
            print()
            print("📋 Instructions:")
            for inst in recipe['instructions']:
                time_str = f" ({inst.get('time')} mins)" if inst.get('time') else ""
                print(f"  {inst['step']}. {inst['text']}{time_str}")
                if inst.get('tips'):
                    print(f"     💡 Tip: {inst['tips']}")
            print()
            print(f"🏷️  Tags: {', '.join(recipe['tags'])}")

            if recipe.get('nutrition_info'):
                print("\n🍎 Nutrition Info:")
                nutrition = recipe['nutrition_info']
                print(f"  - Calories: {nutrition.get('calories', 'N/A')}")
                print(f"  - Protein: {nutrition.get('protein', 'N/A')}")
                print(f"  - Carbs: {nutrition.get('carbs', 'N/A')}")
                print(f"  - Fat: {nutrition.get('fat', 'N/A')}")

            print("\n" + "=" * 60)
            print("✅ Test PASSED - Recipe generated successfully!")

        else:
            print(f"❌ Request failed with status code: {response.status_code}")
            print(f"Error: {response.text}")

    except requests.exceptions.ConnectionError:
        print("❌ Connection failed!")
        print("Make sure the backend server is running:")
        print("  cd backend")
        print("  source fresh_venv/bin/activate")
        print("  python main.py")
    except Exception as e:
        print(f"❌ Test failed: {e}")

if __name__ == "__main__":
    test_recipe_generation()
