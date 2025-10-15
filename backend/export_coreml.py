#!/usr/bin/env python3
"""
Export YOLOv8 to CoreML format for iOS deployment.
"""

from ultralytics import YOLO
from pathlib import Path
import os

def main():
    model_path = "yolov8n_merged_food_cpu_aug_finetuned.pt"

    if not Path(model_path).exists():
        print(f"❌ Model not found: {model_path}")
        return

    print(f"🔄 Loading model: {model_path}")
    model = YOLO(model_path)

    print("🔄 Exporting to CoreML format...")
    try:
        # Export to CoreML
        model.export(
            format='coreml',
            imgsz=640,
            optimize=True,
            half=False,
            dynamic=False,
            simplify=True,
            nms=True,  # Include NMS in the model
            batch=1    # Set batch size to 1 for mobile deployment
        )
        print("✅ CoreML export completed!")

        # Look for the exported file
        exported_file = model_path.replace('.pt', '.mlpackage')
        if Path(exported_file).exists():
            print(f"📁 Exported CoreML model: {exported_file}")

            # Show file size
            size_mb = Path(exported_file).stat().st_size / (1024 * 1024)
            print(f"📊 Model size: {size_mb:.1f} MB")

            print("\n📝 Next steps:")
            print("1. Copy the .mlpackage file to your iOS app bundle")
            print("2. Update LocalInferenceService.swift to use CoreML")
            print("3. Test the model in iOS Simulator or device")

        else:
            print("❌ CoreML file not found after export")

    except Exception as e:
        print(f"❌ CoreML export failed: {e}")
        print("💡 Make sure you have the required dependencies:")
        print("   pip install coremltools")

if __name__ == "__main__":
    main()