#!/usr/bin/env python3
"""
Fine-tune YOLOv8n model on Food-101 dataset for kitchen assistant application.
"""

import os
import torch
from ultralytics import YOLO
from pathlib import Path
import shutil
import yaml
import time
from datetime import datetime
import sys

def setup_training_environment(use_tiny=True):
    """Setup the training environment and paths"""
    # Ensure we're in the backend directory
    backend_dir = Path(__file__).parent
    os.chdir(backend_dir)

    # Choose dataset based on preference
    if use_tiny:
        dataset_path = "food101_tiny_yolo.yaml"
        print("🍕 Using Food-101-Tiny dataset (10 classes)")
    else:
        dataset_path = "../datasets/food101_yolo.yaml"
        print("🍳 Using full Food-101 dataset (46 classes)")

    # Check if dataset exists
    if not Path(dataset_path).exists():
        if use_tiny:
            print(f"❌ Tiny dataset config not found at: {dataset_path}")
            print("💡 Run: python download_food101_tiny.py")
        raise FileNotFoundError(f"Dataset configuration not found at: {dataset_path}")

    # Check if pretrained model exists
    pretrained_model = "yolov8n.pt"
    if not Path(pretrained_model).exists():
        raise FileNotFoundError(f"Pretrained model not found at: {pretrained_model}")

    print(f"✅ Dataset config: {dataset_path}")
    print(f"✅ Pretrained model: {pretrained_model}")

    return dataset_path, pretrained_model

def update_dataset_config(dataset_path):
    """Update the dataset configuration with absolute paths"""
    backend_dir = Path(__file__).parent.absolute()

    # Check if it's a tiny dataset
    is_tiny = "tiny" in dataset_path

    if is_tiny:
        # For tiny dataset, use the config as-is but update path
        config_file = backend_dir / dataset_path
        with open(config_file, 'r') as f:
            config = yaml.safe_load(f)

        # Update path to absolute
        config['path'] = str(backend_dir / "datasets" / "food101_tiny")

        # Save updated config
        with open(config_file, 'w') as f:
            yaml.dump(config, f, default_flow_style=False)

        print(f"✅ Updated tiny dataset config: {config_file}")
        return str(config_file)
    else:
        # Original logic for full dataset
        dataset_dir = backend_dir.parent / "datasets"
        original_config = dataset_dir / "food101_yolo.yaml"
        with open(original_config, 'r') as f:
            config = yaml.safe_load(f)

        config['path'] = str(dataset_dir / "food101_yolo")
        backend_config = backend_dir / "food101_yolo.yaml"
        with open(backend_config, 'w') as f:
            yaml.dump(config, f, default_flow_style=False)

        print(f"✅ Updated dataset config saved to: {backend_config}")
        return str(backend_config)

def fine_tune_model(dataset_config, pretrained_model, epochs=2, batch_size=16, img_size=640,
                    project_name="food101_training", run_name="food101_yolov8n"):
    """Fine-tune the YOLOv8n model on Food-101 dataset"""

    # Determine dataset type from project name
    dataset_type = "Food-101-Tiny" if "tiny" in project_name else "Food-101"

    print(f"🚀 Starting YOLOv8n fine-tuning on {dataset_type} dataset...")
    print(f"📊 Training parameters:")
    print(f"   - Epochs: {epochs}")
    print(f"   - Batch size: {batch_size}")
    print(f"   - Image size: {img_size}")
    print(f"   - Dataset: {dataset_config}")
    print(f"   - Base model: {pretrained_model}")
    print(f"   - Project: {project_name}")
    print(f"   - Run name: {run_name}")

    start_time = datetime.now()
    print(f"⏰ Training started at: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*60)

    # Load the pretrained YOLOv8n model
    model = YOLO(pretrained_model)

    # Force CPU training for stability (MPS has validation bugs)
    device = 'cpu'
    print(f"🖥️  Training device: {device}")

    # Override any automatic device detection
    import torch
    torch.backends.mps.is_available = lambda: False  # Force disable MPS
    print(f"💾 Model will be saved every epoch")
    print("="*60)

    # Add progress callback for real-time monitoring
    def on_train_epoch_end(trainer):
        epoch = trainer.epoch + 1
        epochs_total = trainer.epochs
        current_time = datetime.now()
        elapsed = current_time - start_time

        print(f"\n📈 Epoch {epoch}/{epochs_total} completed!")
        print(f"⏱️  Elapsed time: {elapsed}")

        if hasattr(trainer, 'loss') and trainer.loss is not None:
            try:
                if len(trainer.loss) >= 3:
                    print(f"📊 Latest losses - Box: {trainer.loss[0]:.4f}, Cls: {trainer.loss[1]:.4f}, DFL: {trainer.loss[2]:.4f}")
            except (IndexError, TypeError):
                print("📊 Loss information not available yet")

        if epoch < epochs_total:
            estimated_remaining = elapsed * (epochs_total - epoch) / epoch
            print(f"🔮 Estimated remaining: {estimated_remaining}")
            estimated_finish = current_time + estimated_remaining
            print(f"🏁 Estimated finish: {estimated_finish.strftime('%H:%M:%S')}")

        print("-"*60)

    # Add the callback to the model
    model.add_callback("on_train_epoch_end", on_train_epoch_end)

    # Start training
    try:
        # Check if resuming from checkpoint
        is_resuming = str(pretrained_model).endswith('best.pt') or str(pretrained_model).endswith('last.pt')

        results = model.train(
            data=dataset_config,
            epochs=epochs,
            batch=batch_size,
            imgsz=img_size,
            device=device,
            project=project_name,
            name=run_name,
            exist_ok=True,
            resume=is_resuming,  # Resume if using checkpoint
            pretrained=not is_resuming,  # Only use pretrained if not resuming
            optimizer='AdamW',
            lr0=0.001,  # Initial learning rate
            weight_decay=0.0005,
            warmup_epochs=1,  # Reduced warmup for short training
            box=7.5,    # Box loss gain
            cls=0.5,    # Classification loss gain
            dfl=1.5,    # Distribution focal loss gain
            save=True,
            save_period=1,  # Save checkpoint every epoch
            cache=False,  # Don't cache images to save disk space
            workers=0,
            patience=5,  # Early stopping patience
            verbose=True,
            plots=False,  # Disable plots for stability on MPS
            save_json=False,   # Disable JSON saving
            val=True,         # Enable validation with our train/val split!
            amp=False         # Disable AMP to avoid MPS validation bug
        )

        end_time = datetime.now()
        training_duration = end_time - start_time
        print("="*60)
        print("✅ Training completed successfully!")
        print(f"⏰ Training finished at: {end_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"🕐 Total training time: {training_duration}")
        print("="*60)
        return results

    except Exception as e:
        print(f"❌ Training failed: {e}")
        raise

def copy_best_model(project_name="food101_training", run_name="food101_yolov8n"):
    """Copy the best trained model to replace the original YOLOv8n model"""

    # Find the best model from training
    training_dir = Path(f"{project_name}/{run_name}")
    best_model_path = training_dir / "weights" / "best.pt"

    if best_model_path.exists():
        # Create backup of original model
        original_model = Path("yolov8n.pt")
        backup_model = Path("yolov8n_original_backup.pt")

        if original_model.exists() and not backup_model.exists():
            shutil.copy2(original_model, backup_model)
            print(f"📦 Original model backed up to: {backup_model}")

        # Generate appropriate model name based on dataset type
        model_suffix = "tiny" if "tiny" in project_name else "food101"
        output_model = f"yolov8n_{model_suffix}_finetuned.pt"

        # Copy the fine-tuned model
        shutil.copy2(best_model_path, output_model)
        print(f"🎯 Fine-tuned model saved as: {output_model}")

        return output_model
    else:
        print(f"❌ Best model not found at: {best_model_path}")
        return None

def validate_model(model_path, dataset_config):
    """Validate the fine-tuned model"""
    print(f"🔍 Validating model: {model_path}")

    try:
        model = YOLO(model_path)

        # Run validation
        # Force CPU validation for stability on macOS/MPS
        results = model.val(
            data=dataset_config,
            device='cpu',
            workers=0,
            plots=False,
            save_json=False
        )

        print("📊 Validation Results:")
        print(f"   - mAP50: {results.box.map50:.4f}")
        print(f"   - mAP50-95: {results.box.map:.4f}")

        return results

    except Exception as e:
        print(f"❌ Validation failed: {e}")
        return None

def main():
    """Main fine-tuning function"""
    try:
        print("🍳 Food-101 YOLOv8n Fine-tuning Script")
        print("=" * 50)

        # Use complete merged food dataset for final training
        dataset_path = "/Users/jc/Desktop/MSD/capstone/edge-ai-kitchen-assistant/datasets/merged_food_dataset/data.yaml"
        pretrained_model = "yolov8n.pt"

        if not Path(dataset_path).exists():
            raise FileNotFoundError(f"Dataset config not found: {dataset_path}")
        if not Path(pretrained_model).exists():
            raise FileNotFoundError(f"Pretrained model not found: {pretrained_model}")

        print(f"✅ Using fixed merged dataset: {dataset_path}")
        print(f"✅ Pretrained model: {pretrained_model}")

        # Use merged food dataset for full training (20 epochs)
        is_tiny = False  # We're using our merged dataset, not tiny
        project_name = "kitchen_assistant_training_full"
        run_name = "merged_food_yolov8n_20epochs"

        # Check if we should resume from existing checkpoint
        best_model_path = Path(f"{project_name}/{run_name}/weights/best.pt")
        if best_model_path.exists():
            print(f"🔄 Found existing checkpoint: {best_model_path}")
            pretrained_model = str(best_model_path)
            print(f"🚀 Resuming training from: {pretrained_model}")

        # Use dataset path directly (already configured correctly)
        dataset_config = dataset_path

        # Full training with 20 epochs
        training_results = fine_tune_model(
            dataset_config=dataset_config,
            pretrained_model=pretrained_model,
            epochs=20,       # Full training
            batch_size=8,    # Increase batch size for better training
            img_size=640,    # Standard image size
            project_name=project_name,
            run_name=run_name
        )

        # Copy the best model
        best_model_path = copy_best_model(project_name, run_name)

        if best_model_path:
            # Validate the fine-tuned model
            validation_results = validate_model(best_model_path, dataset_config)

        print("\n🎉 Fine-tuning process completed!")
        print(f"📁 Training outputs saved in: {project_name}/")
        if best_model_path:
            print(f"🎯 Fine-tuned model: {best_model_path}")
            print("\n💡 To use the fine-tuned model in your application:")
            print(f"   Update main.py to load: {best_model_path}")
        else:
            print("⚠️  No model was saved (training may have been too short)")

        dataset_name = "Tiny" if is_tiny else "Food-101"
        print(f"\n📊 Check {dataset_name} training results in:")
        print(f"   - {project_name}/{run_name}/results.png")
        print(f"   - {project_name}/{run_name}/weights/")

        if is_tiny:
            print(f"\n🍕 Food-101-Tiny training completed!")
            print(f"   - Only 10 food classes (vs 46 in full dataset)")
            print(f"   - Faster training and inference")
            print(f"   - Perfect for prototyping and testing")

    except Exception as e:
        print(f"💥 Fine-tuning failed: {e}")
        raise

if __name__ == "__main__":
    main()