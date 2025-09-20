#!/usr/bin/env python3
"""
数据集聚合脚本 - 将所有food类别的images和labels合并到统一文件夹
Merge all food category datasets into unified images and labels folders
"""

import os
import shutil
from pathlib import Path
from collections import defaultdict
import yaml

def scan_dataset_structure(datasets_dir):
    """扫描datasets文件夹，识别所有包含images和labels的子文件夹"""
    datasets_dir = Path(datasets_dir)
    found_paths = []
    
    print("🔍 扫描数据集结构...")
    
    # 遍历所有food类别文件夹
    for food_category in datasets_dir.iterdir():
        if food_category.is_dir() and food_category.name not in ['.DS_Store', '__pycache__']:
            print(f"\n📁 检查类别: {food_category.name}")
            
            # 查找train/test/valid等文件夹
            for split_folder in food_category.iterdir():
                if split_folder.is_dir() and split_folder.name in ['train', 'test', 'valid', 'val']:
                    images_path = split_folder / 'images'
                    labels_path = split_folder / 'labels'
                    
                    if images_path.exists() and labels_path.exists():
                        image_count = len(list(images_path.glob('*.jpg'))) + len(list(images_path.glob('*.png')))
                        label_count = len(list(labels_path.glob('*.txt')))
                        
                        found_paths.append({
                            'category': food_category.name,
                            'split': split_folder.name,
                            'images_path': images_path,
                            'labels_path': labels_path,
                            'image_count': image_count,
                            'label_count': label_count
                        })
                        
                        print(f"  ✅ {split_folder.name}: {image_count} images, {label_count} labels")
                    else:
                        print(f"  ⚠️  {split_folder.name}: 缺少images或labels文件夹")
    
    return found_paths

def merge_datasets(datasets_dir, output_dir, test_ratio=0.15, val_ratio=0.15):
    """合并所有数据集到统一文件夹 - 所有images和labels聚合到单一文件夹"""
    datasets_dir = Path(datasets_dir)
    output_dir = Path(output_dir)
    
    # 创建输出目录结构 - 统一的images和labels文件夹
    merged_images = output_dir / 'images'
    merged_labels = output_dir / 'labels'
    
    # 创建目录
    merged_images.mkdir(parents=True, exist_ok=True)
    merged_labels.mkdir(parents=True, exist_ok=True)
    
    print(f"\n📁 创建合并目录: {output_dir}")
    
    # 扫描所有数据集
    found_paths = scan_dataset_structure(datasets_dir)
    
    total_images = 0
    total_labels = 0
    category_stats = defaultdict(int)
    file_conflicts = []
    
    print(f"\n🔄 开始合并数据集...")
    
    for data_info in found_paths:
        category = data_info['category']
        split = data_info['split']
        images_path = data_info['images_path']
        labels_path = data_info['labels_path']
        
        print(f"\n处理: {category}/{split}")
        
        # 所有数据都放到统一的images和labels文件夹中
        target_images_dir = merged_images
        target_labels_dir = merged_labels
        
        # 复制图片文件
        for img_file in images_path.glob('*.*'):
            if img_file.suffix.lower() in ['.jpg', '.jpeg', '.png']:
                # 生成唯一文件名避免冲突
                new_name = f"{category}_{split}_{img_file.name}"
                target_path = target_images_dir / new_name
                
                if target_path.exists():
                    file_conflicts.append(f"图片冲突: {new_name}")
                    new_name = f"{category}_{split}_{total_images}_{img_file.name}"
                    target_path = target_images_dir / new_name
                
                shutil.copy2(img_file, target_path)
                total_images += 1
                category_stats[category] += 1
        
        # 复制标签文件
        for label_file in labels_path.glob('*.txt'):
            # 确保标签文件名与对应的图片文件名匹配
            img_base_name = label_file.stem
            
            # 查找对应的图片文件
            corresponding_img = None
            for ext in ['.jpg', '.jpeg', '.png']:
                img_path = images_path / f"{img_base_name}{ext}"
                if img_path.exists():
                    corresponding_img = img_path
                    break
            
            if corresponding_img:
                # 使用与图片相同的命名规则
                new_img_name = f"{category}_{split}_{corresponding_img.name}"
                new_label_name = f"{category}_{split}_{label_file.name}"
                
                # 检查图片是否存在冲突，如果有则使用相同的解决方案
                target_img_path = target_images_dir / new_img_name
                if not target_img_path.exists():
                    # 寻找实际的图片文件名
                    for existing_img in target_images_dir.glob(f"{category}_{split}_*"):
                        if existing_img.stem.endswith(img_base_name):
                            new_label_name = existing_img.stem + '.txt'
                            break
                
                target_label_path = target_labels_dir / new_label_name
                
                if target_label_path.exists():
                    file_conflicts.append(f"标签冲突: {new_label_name}")
                    new_label_name = f"{category}_{split}_{total_labels}_{label_file.name}"
                    target_label_path = target_labels_dir / new_label_name
                
                shutil.copy2(label_file, target_label_path)
                total_labels += 1
    
    # 打印统计信息
    print(f"\n📊 合并完成统计:")
    print(f"总图片数: {total_images}")
    print(f"总标签数: {total_labels}")
    print(f"\n各类别图片数量:")
    for category, count in category_stats.items():
        print(f"  {category}: {count}")
    
    if file_conflicts:
        print(f"\n⚠️  文件名冲突解决数量: {len(file_conflicts)}")
        for conflict in file_conflicts[:5]:  # 只显示前5个
            print(f"  {conflict}")
        if len(file_conflicts) > 5:
            print(f"  ... 还有 {len(file_conflicts) - 5} 个冲突")
    
    # 计算合并后的总数量
    merged_images_count = len(list(merged_images.glob('*.*')))
    merged_labels_count = len(list(merged_labels.glob('*.*')))
    
    print(f"\n📈 合并后数据集:")
    print(f"  总图片数: {merged_images_count}")
    print(f"  总标签数: {merged_labels_count}")
    
    return {
        'total_images': total_images,
        'total_labels': total_labels,
        'category_stats': dict(category_stats),
        'merged_images_count': merged_images_count,
        'merged_labels_count': merged_labels_count,
        'conflicts': len(file_conflicts)
    }

def get_class_names(datasets_dir):
    """从data.yaml文件中提取所有类别名称"""
    datasets_dir = Path(datasets_dir)
    all_classes = set()
    
    print("\n🏷️  提取类别标签...")
    
    for food_category in datasets_dir.iterdir():
        if food_category.is_dir():
            data_yaml = food_category / 'data.yaml'
            if data_yaml.exists():
                try:
                    with open(data_yaml, 'r') as f:
                        data = yaml.safe_load(f)
                    
                    if 'names' in data:
                        if isinstance(data['names'], dict):
                            # names是字典格式 {0: 'class1', 1: 'class2'}
                            classes = list(data['names'].values())
                        else:
                            # names是列表格式 ['class1', 'class2']
                            classes = data['names']
                        
                        print(f"  {food_category.name}: {classes}")
                        all_classes.update(classes)
                        
                except Exception as e:
                    print(f"  ⚠️  读取 {food_category.name}/data.yaml 失败: {e}")
    
    return sorted(list(all_classes))

def create_merged_config(output_dir, class_names):
    """为合并后的数据集创建YOLO格式的配置文件"""
    output_dir = Path(output_dir)
    
    # 创建类别名称映射
    names_dict = {i: name for i, name in enumerate(class_names)}
    
    config = {
        'path': str(output_dir.absolute()),
        'train': 'images',  # 所有数据都在统一的images文件夹中
        'val': 'images',    # 指向同一个images文件夹
        'test': 'images',   # 指向同一个images文件夹
        'nc': len(class_names),
        'names': names_dict
    }
    
    # 保存配置文件
    config_path = output_dir / 'data.yaml'
    with open(config_path, 'w') as f:
        yaml.dump(config, f, default_flow_style=False)
    
    print(f"\n📄 配置文件已创建: {config_path}")
    print(f"类别数量: {len(class_names)}")
    print(f"类别名称: {class_names}")
    
    return config_path

def main():
    """主函数"""
    print("🍳 Kitchen Assistant - 数据集聚合工具")
    print("=" * 60)
    
    # 设置路径
    datasets_dir = Path(__file__).parent / 'datasets'
    output_dir = Path(__file__).parent / 'datasets' / 'merged_food_dataset'
    
    if not datasets_dir.exists():
        print(f"❌ 数据集目录不存在: {datasets_dir}")
        return
    
    # 确认操作
    print(f"📂 源目录: {datasets_dir}")
    print(f"📁 输出目录: {output_dir}")
    
    if output_dir.exists():
        response = input(f"\n⚠️  输出目录已存在，是否覆盖? (y/N): ")
        if response.lower() not in ['y', 'yes']:
            print("❌ 操作已取消")
            return
        shutil.rmtree(output_dir)
    
    try:
        # 1. 合并数据集
        stats = merge_datasets(datasets_dir, output_dir)
        
        # 2. 获取类别名称
        class_names = get_class_names(datasets_dir)
        
        # 3. 创建配置文件
        config_path = create_merged_config(output_dir, class_names)
        
        print(f"\n✅ 数据集聚合完成!")
        print(f"📊 总统计:")
        print(f"  - 图片总数: {stats['total_images']}")
        print(f"  - 标签总数: {stats['total_labels']}")
        print(f"  - 类别总数: {len(class_names)}")
        print(f"  - 合并后图片: {stats['merged_images_count']}")
        print(f"  - 合并后标签: {stats['merged_labels_count']}")
        
        print(f"\n🎯 可以使用以下配置开始训练:")
        print(f"  配置文件: {config_path}")
        print(f"  数据集路径: {output_dir}")
        
        print(f"\n💡 训练命令示例:")
        print(f"  python fine_tune_yolo.py --dataset {config_path}")
        
    except Exception as e:
        print(f"❌ 合并过程出错: {e}")
        raise

if __name__ == "__main__":
    main()
