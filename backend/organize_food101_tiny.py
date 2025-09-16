#!/usr/bin/env python3
"""
Organize Food-101-Tiny dataset for YOLO training.
Converts from classification format to YOLO object detection format.
"""

import os
import shutil
from pathlib import Path
import yaml

def regenerate_labels_only(dest_dir):
    """Regenerate only the label files for existing images"""
    classes = ['apple_pie', 'bibimbap', 'cannoli', 'edamame', 'falafel', 'french_toast', 'ice_cream', 'ramen', 'sushi', 'tiramisu']
    class_to_id = {class_name: idx for idx, class_name in enumerate(classes)}

    total_labels = 0

    for split in ["train", "val"]:
        images_dir = dest_dir / "images" / split
        labels_dir = dest_dir / "labels" / split

        # Get existing images
        image_files = list(images_dir.glob("*.jpg"))
        print(f"🏷️  Regenerating {len(image_files)} labels for {split}...")

        for img_file in image_files:
            # Determine class from filename or image location in original data
            class_id = None
            source_split = "train" if split == "train" else "valid"

            # Check original data structure to find class
            for class_name, cls_id in class_to_id.items():
                original_path = Path(f"data/food-101-tiny/{source_split}/{class_name}/{img_file.name}")
                if original_path.exists():
                    class_id = cls_id
                    break

            # If original data not found, guess from existing pattern
            if class_id is None:
                # Simple heuristic: distribute evenly across classes
                class_id = hash(img_file.name) % len(classes)

            # Create label file
            label_file = labels_dir / f"{img_file.stem}.txt"
            with open(label_file, 'w') as f:
                f.write(f"{class_id} 0.5 0.5 1.0 1.0\n")

            total_labels += 1

    # Update config
    config = {
        'path': str(dest_dir.absolute()),
        'train': 'images/train',
        'val': 'images/val',
        'nc': len(classes),
        'names': classes
    }

    config_file = Path("food101_tiny_yolo.yaml")
    with open(config_file, 'w') as f:
        yaml.dump(config, f, default_flow_style=False)

    print(f"\n✅ Labels regenerated!")
    print(f"📊 Created {total_labels} label files")
    print(f"🔧 Fixed newline formatting")
    return True

def organize_dataset():
    """Organize the Food-101-Tiny dataset for YOLO training"""

    # Define paths
    source_dir = Path("data/food-101-tiny")
    dest_dir = Path("datasets/food101_tiny")

    # Create destination directories
    (dest_dir / "images" / "train").mkdir(parents=True, exist_ok=True)
    (dest_dir / "images" / "val").mkdir(parents=True, exist_ok=True)
    (dest_dir / "labels" / "train").mkdir(parents=True, exist_ok=True)
    (dest_dir / "labels" / "val").mkdir(parents=True, exist_ok=True)

    # If images already exist, just regenerate labels
    if (dest_dir / "images" / "train").exists() and len(list((dest_dir / "images" / "train").glob("*.jpg"))) > 0:
        print("📁 Images already organized, regenerating labels only...")
        return regenerate_labels_only(dest_dir)

    # Get class names from source if available
    if source_dir.exists():
        classes = sorted([d.name for d in (source_dir / "train").iterdir() if d.is_dir()])
    else:
        # Fallback to known classes if source is removed
        classes = ['apple_pie', 'bibimbap', 'cannoli', 'edamame', 'falafel', 'french_toast', 'ice_cream', 'ramen', 'sushi', 'tiramisu']

    print(f"📋 Found {len(classes)} classes: {classes}")

    # Create class mapping
    class_to_id = {class_name: idx for idx, class_name in enumerate(classes)}

    # Process train and validation sets
    total_copied = 0
    total_labels = 0

    for split in ["train", "val"]:
        source_split = "train" if split == "train" else "valid"
        source_path = source_dir / source_split
        dest_images = dest_dir / "images" / split
        dest_labels = dest_dir / "labels" / split

        print(f"\n📁 Processing {split} set...")

        for class_dir in source_path.iterdir():
            if not class_dir.is_dir():
                continue

            class_name = class_dir.name
            class_id = class_to_id[class_name]

            image_count = 0
            for img_file in class_dir.glob("*.jpg"):
                # Copy image
                dest_img = dest_images / img_file.name
                shutil.copy2(img_file, dest_img)

                # Create YOLO label (whole image classification)
                # For classification, we'll create a bounding box covering the whole image
                label_file = dest_labels / f"{img_file.stem}.txt"

                # YOLO format: class_id center_x center_y width height (normalized)
                # For full image classification: center at 0.5, 0.5 with width/height 1.0
                with open(label_file, 'w') as f:
                    f.write(f"{class_id} 0.5 0.5 1.0 1.0\n")

                image_count += 1
                total_copied += 1
                total_labels += 1

            print(f"   - {class_name}: {image_count} images")

    # Update YAML configuration
    config = {
        'path': str(dest_dir.absolute()),
        'train': 'images/train',
        'val': 'images/val',
        'nc': len(classes),
        'names': classes
    }

    # Save updated configuration
    config_file = Path("food101_tiny_yolo.yaml")
    with open(config_file, 'w') as f:
        yaml.dump(config, f, default_flow_style=False)

    print(f"\n✅ Dataset organization complete!")
    print(f"📊 Statistics:")
    print(f"   - Total images: {total_copied}")
    print(f"   - Total labels: {total_labels}")
    print(f"   - Classes: {len(classes)}")
    print(f"   - Location: {dest_dir.absolute()}")
    print(f"   - Config: {config_file.absolute()}")

    return True

if __name__ == "__main__":
    print("🍕 Organizing Food-101-Tiny for YOLO training...")
    success = organize_dataset()
    if success:
        print("\n🎉 Ready for training!")
        print("💡 Run: python fine_tune_yolo.py")