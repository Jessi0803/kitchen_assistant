#!/bin/bash

# 修復Xcode項目 - 添加缺失的文件
echo "正在修復Xcode項目..."

# 備份原始項目文件
cp KitchenAssistant.xcodeproj/project.pbxproj KitchenAssistant.xcodeproj/project.pbxproj.backup

# 使用xcodebuild添加文件（如果支持的話）
echo "請在Xcode中手動添加以下文件到項目中："
echo "1. KitchenAssistant/Models/Recipe.swift -> Models 文件夾"
echo "2. KitchenAssistant/Views/RecipeView.swift -> Views 文件夾"  
echo "3. KitchenAssistant/Utils/ImagePicker.swift -> Utils 文件夾"
echo ""
echo "添加文件時請確保選擇 'Add to target: KitchenAssistant'"
echo ""
echo "完成後，項目應該能夠正常編譯。"

# 嘗試構建項目
echo "嘗試構建項目..."
xcodebuild -project KitchenAssistant.xcodeproj -scheme KitchenAssistant -destination 'platform=iOS Simulator,name=iPhone 16' build
