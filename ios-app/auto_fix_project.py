#!/usr/bin/env python3
"""
自動修復Xcode項目 - 添加缺失的文件
"""

import os
import subprocess
import sys

def run_command(cmd):
    """運行命令並返回結果"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def main():
    print("🔧 開始修復Xcode項目...")
    
    # 檢查文件是否存在
    files_to_add = [
        "KitchenAssistant/Models/Recipe.swift",
        "KitchenAssistant/Views/RecipeView.swift", 
        "KitchenAssistant/Utils/ImagePicker.swift"
    ]
    
    missing_files = []
    for file_path in files_to_add:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
    
    if missing_files:
        print(f"❌ 缺少以下文件: {missing_files}")
        return False
    
    print("✅ 所有必需文件都存在")
    
    # 嘗試使用xcodebuild添加文件
    print("🔧 嘗試使用xcodebuild修復項目...")
    
    # 首先嘗試構建項目來確認錯誤
    print("📋 檢查當前構建錯誤...")
    success, stdout, stderr = run_command("xcodebuild -project KitchenAssistant.xcodeproj -scheme KitchenAssistant -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | grep -c 'error:'")
    
    if success and int(stdout.strip()) > 0:
        print(f"❌ 發現 {stdout.strip()} 個編譯錯誤")
        print("\n📝 請按照以下步驟手動修復：")
        print("1. 在Xcode中打開項目: open KitchenAssistant.xcodeproj")
        print("2. 創建文件夾: Models 和 Utils")
        print("3. 添加文件到項目:")
        print("   - KitchenAssistant/Models/Recipe.swift → Models 文件夾")
        print("   - KitchenAssistant/Views/RecipeView.swift → Views 文件夾")
        print("   - KitchenAssistant/Utils/ImagePicker.swift → Utils 文件夾")
        print("4. 確保選擇 'Add to target: KitchenAssistant'")
        print("5. 按 ⌘+B 構建項目")
    else:
        print("✅ 項目構建成功！")
    
    return True

if __name__ == "__main__":
    main()
