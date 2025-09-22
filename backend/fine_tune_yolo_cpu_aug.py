#!/usr/bin/env python3
"""
Fine-tune YOLOv8n on merged_food_dataset (CPU) with explicit, moderate augmentations.
This script is a non-destructive variant of fine_tune_yolo.py with:
- workers: 2
- plots: True
- explicit augmentations (hsv_h=0.01, hsv_s=0.3, hsv_v=0.2, fliplr=0.5, mosaic=0.3, mixup=0.0)
- epochs: 30
"""

import os
from pathlib import Path
from datetime import datetime
import shutil
import yaml
from ultralytics import YOLO


def fine_tune_model(
    dataset_config: str,
    pretrained_model: str,
    epochs: int = 30,
    batch_size: int = 8,
    img_size: int = 640,
    project_name: str = "kitchen_assistant_training_cpu_aug",
    run_name: str = "merged_food_yolov8n_cpu_aug_30epochs",
):
    """Fine-tune YOLOv8n on CPU with explicit moderate augmentations."""

    print("🚀 Starting YOLOv8n fine-tuning (CPU + Moderate Augmentations)...")
    print("📊 Training parameters:")
    print(f"   - Epochs: {epochs}")
    print(f"   - Batch size: {batch_size}")
    print(f"   - Image size: {img_size}")
    print(f"   - Dataset: {dataset_config}")
    print(f"   - Base model: {pretrained_model}")
    print(f"   - Project: {project_name}")
    print(f"   - Run name: {run_name}")

    start_time = datetime.now()
    print(f"⏰ Training started at: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    # Model
    model = YOLO(pretrained_model)

    # Force CPU for stability and reproducibility
    device = "cpu"
    print(f"🖥️  Training device: {device}")
    print("=" * 60)

    # Callback for progress
    def on_train_epoch_end(trainer):
        epoch = trainer.epoch + 1
        epochs_total = trainer.epochs
        current_time = datetime.now()
        elapsed = current_time - start_time
        print(f"\n📈 Epoch {epoch}/{epochs_total} completed!")
        print(f"⏱️  Elapsed time: {elapsed}")
        if hasattr(trainer, "loss") and trainer.loss is not None:
            try:
                if len(trainer.loss) >= 3:
                    print(
                        f"📊 Latest losses - Box: {trainer.loss[0]:.4f}, Cls: {trainer.loss[1]:.4f}, DFL: {trainer.loss[2]:.4f}"
                    )
            except (IndexError, TypeError):
                print("📊 Loss information not available yet")
        if epoch < epochs_total:
            estimated_remaining = elapsed * (epochs_total - epoch) / max(epoch, 1)
            estimated_finish = current_time + estimated_remaining
            print(f"🔮 Estimated finish: {estimated_finish.strftime('%H:%M:%S')}")
        print("-" * 60)

    model.add_callback("on_train_epoch_end", on_train_epoch_end)

    # Train
    results = model.train(
        data=dataset_config,
        epochs=epochs,
        batch=batch_size,
        imgsz=img_size,
        device=device,
        project=project_name,
        name=run_name,
        exist_ok=True,
        resume=False,
        pretrained=True,
        optimizer="AdamW",
        lr0=0.0005,
        weight_decay=0.0005,
        warmup_epochs=2.0,
        # loss gains (keep defaults reasonable)
        box=7.5,
        cls=0.5,
        dfl=1.5,
        # saving/IO
        save=True,
        save_period=5,
        cache=False,
        workers=2,              # improved dataloading on CPU
        patience=20,            # avoid early stop too soon
        verbose=True,
        plots=True,             # enable plots on CPU
        save_json=True,
        val=True,
        amp=False,
        # explicit moderate augmentations
        hsv_h=0.01,
        hsv_s=0.3,
        hsv_v=0.2,
        fliplr=0.5,
        mosaic=0.3,
        mixup=0.0,
        degrees=0.0,
        translate=0.05,
        scale=0.2,
        shear=0.0,
        perspective=0.0,
        flipud=0.0,
    )

    end_time = datetime.now()
    print("=" * 60)
    print("✅ Training completed!")
    print(f"⏰ Finished at: {end_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"🕐 Total time: {end_time - start_time}")
    print("=" * 60)
    return results


def copy_best_model(project_name: str, run_name: str) -> str | None:
    """Copy best.pt to project root with a readable name."""
    training_dir = Path(f"{project_name}/{run_name}")
    best_model_path = training_dir / "weights" / "best.pt"
    if best_model_path.exists():
        dst = Path("yolov8n_merged_food_cpu_aug_finetuned.pt")
        shutil.copy2(best_model_path, dst)
        print(f"🎯 Fine-tuned model saved as: {dst}")
        return str(dst)
    print(f"⚠️  Best model not found at: {best_model_path}")
    return None


def validate_model(model_path: str, dataset_config: str):
    """Validate best model on CPU."""
    print(f"🔍 Validating model: {model_path}")
    model = YOLO(model_path)
    results = model.val(
        data=dataset_config,
        device="cpu",
        workers=2,
        plots=True,
        save_json=True,
    )
    print("📊 Validation Results:")
    print(f"   - mAP50: {results.box.map50:.4f}")
    print(f"   - mAP50-95: {results.box.map:.4f}")
    return results


def main():
    try:
        print("🍳 YOLOv8n Fine-tuning (CPU + Augmentations)")
        print("=" * 50)

        dataset_path = \
            "/Users/jc/Desktop/MSD/capstone/edge-ai-kitchen-assistant/datasets/merged_food_dataset/data.yaml"
        pretrained_model = \
            "/Users/jc/Desktop/MSD/capstone/edge-ai-kitchen-assistant/backend/kitchen_assistant_training_cpu_test/merged_food_yolov8n_cpu/weights/best.pt"

        if not Path(dataset_path).exists():
            raise FileNotFoundError(f"Dataset config not found: {dataset_path}")
        if not Path(pretrained_model).exists():
            raise FileNotFoundError(f"Pretrained model not found: {pretrained_model}")

        project_name = "kitchen_assistant_training_cpu_aug"
        run_name = "merged_food_yolov8n_cpu_aug_30epochs"

        results = fine_tune_model(
            dataset_config=dataset_path,
            pretrained_model=pretrained_model,
            epochs=30,
            batch_size=8,
            img_size=640,
            project_name=project_name,
            run_name=run_name,
        )

        best_model = copy_best_model(project_name, run_name)
        if best_model:
            validate_model(best_model, dataset_path)

        print("\n🎉 Process completed!")
        print(f"📁 Outputs: {project_name}/{run_name}")
        if best_model:
            print(f"🎯 Model: {best_model}")
    except Exception as e:
        print(f"💥 Failed: {e}")
        raise


if __name__ == "__main__":
    main()


