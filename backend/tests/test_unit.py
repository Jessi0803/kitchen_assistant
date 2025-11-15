"""
Unit Tests for Backend Functions
"""
import pytest
import sys
import os

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from main import YOLO_TO_FOOD_MAPPING, MOCK_INGREDIENTS

def test_food_mapping_not_empty():
    """Test that food mapping dictionary is not empty"""
    assert len(YOLO_TO_FOOD_MAPPING) > 0

def test_food_mapping_values():
    """Test that food mapping has correct value types"""
    for key, value in YOLO_TO_FOOD_MAPPING.items():
        assert isinstance(key, str)
        assert isinstance(value, str)
        assert len(value) > 0

def test_mock_ingredients_not_empty():
    """Test that mock ingredients list is not empty"""
    assert len(MOCK_INGREDIENTS) > 0

def test_mock_ingredients_values():
    """Test that mock ingredients are strings"""
    for ingredient in MOCK_INGREDIENTS:
        assert isinstance(ingredient, str)
        assert len(ingredient) > 0

def test_food_mapping_consistency():
    """Test that food mapping keys are lowercase"""
    for key in YOLO_TO_FOOD_MAPPING.keys():
        assert key == key.lower(), f"Key {key} is not lowercase"

