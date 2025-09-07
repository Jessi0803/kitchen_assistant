#!/usr/bin/env python3

import re

def fix_project_paths():
    # 讀取project.pbxproj文件
    with open('KitchenAssistant.xcodeproj/project.pbxproj', 'r') as f:
        content = f.read()
    
    # 修復文件路徑映射
    path_fixes = {
        'KitchenAssistantApp.swift': 'KitchenAssistant/KitchenAssistantApp.swift',
        'ContentView.swift': 'KitchenAssistant/ContentView.swift', 
        'CameraView.swift': 'KitchenAssistant/Views/CameraView.swift',
        'APIClient.swift': 'KitchenAssistant/Services/APIClient.swift',
        'Assets.xcassets': 'KitchenAssistant/Assets.xcassets',
        'Info.plist': 'KitchenAssistant/Info.plist',
        'Recipe.swift': 'KitchenAssistant/Models/Recipe.swift',
        'RecipeView.swift': 'KitchenAssistant/Views/RecipeView.swift',
        'ImagePicker.swift': 'KitchenAssistant/Utils/ImagePicker.swift'
    }
    
    # 應用修復
    for old_path, new_path in path_fixes.items():
        # 修復PBXFileReference中的路徑
        pattern = f'path = {re.escape(old_path)}; sourceTree = "<group>";'
        replacement = f'path = {new_path}; sourceTree = "<group>";'
        content = content.replace(pattern, replacement)
    
    # 寫回文件
    with open('KitchenAssistant.xcodeproj/project.pbxproj', 'w') as f:
        f.write(content)
    
    print("文件路徑已修復！")

if __name__ == "__main__":
    fix_project_paths()
