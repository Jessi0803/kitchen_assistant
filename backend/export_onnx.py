#!/usr/bin/env python3
"""
Export YOLOv8 to ONNX format for iOS deployment.
ONNX can then be converted to CoreML using external tools.
"""

from ultralytics import YOLO
from pathlib import Path

def main():
    model_path = "yolov8n_merged_food_cpu_aug_finetuned.pt"

    if not Path(model_path).exists():
        print(f"❌ Model not found: {model_path}")
        return

    print(f"🔄 Loading model: {model_path}")
    model = YOLO(model_path)

    print("🔄 Exporting to ONNX format...")
    try:
        # Export to ONNX
        model.export(
            format='onnx',
            imgsz=640,
            optimize=True,
            half=False,
            dynamic=False,
            simplify=True,
            opset=10
        )
        print("✅ ONNX export completed!")

        # Look for the exported file
        exported_file = model_path.replace('.pt', '.onnx')
        if Path(exported_file).exists():
            print(f"📁 Exported ONNX model: {exported_file}")

            # Show file size
            size_mb = Path(exported_file).stat().st_size / (1024 * 1024)
            print(f"📊 Model size: {size_mb:.1f} MB")

            print("\n📝 Next steps:")

            print("2. Or use online converters like Netron to inspect the model")
            print("3. For iOS, you can also use ONNX Runtime iOS framework directly")

        else:
            print("❌ ONNX file not found after export")

    except Exception as e:
        print(f"❌ ONNX export failed: {e}")

if __name__ == "__main__":
    main()
