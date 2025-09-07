# 修復Xcode項目 - 添加缺失文件

## 問題
您的Xcode項目缺少以下關鍵文件，導致14個編譯錯誤：
- `Recipe.swift` (包含 Recipe、Ingredient、Instruction、NutritionInfo 類型)
- `RecipeView.swift` (RecipeView 視圖)  
- `ImagePicker.swift` (ImagePickerView 組件)

## 解決步驟

### 方法1: 在Xcode中手動添加文件

1. **打開Xcode項目**
   ```bash
   open KitchenAssistant.xcodeproj
   ```

2. **創建文件夾結構**
   - 在項目導航器中右鍵點擊 "KitchenAssistant" 文件夾
   - 選擇 "New Group" 創建以下文件夾：
     - `Models`
     - `Utils`

3. **添加文件到項目**
   - 將 `KitchenAssistant/Models/Recipe.swift` 拖拽到 `Models` 文件夾
   - 將 `KitchenAssistant/Views/RecipeView.swift` 拖拽到 `Views` 文件夾
   - 將 `KitchenAssistant/Utils/ImagePicker.swift` 拖拽到 `Utils` 文件夾
   - **重要：** 添加文件時確保選擇 "Add to target: KitchenAssistant"

4. **驗證修復**
   - 按 ⌘+B 構建項目
   - 所有編譯錯誤應該消失

### 方法2: 使用命令行修復（推薦）

運行以下命令來自動修復項目：

```bash
cd /Users/jc/Desktop/MSD/capstone/edge-ai-kitchen-assistant/ios-app
./fix_project.sh
```

## 預期結果
修復後，您的項目應該能夠：
- 成功編譯 (⌘+B)
- 在iOS模擬器中運行
- 所有類型定義都能正確識別

## 文件結構
修復後的項目結構：
```
KitchenAssistant/
├── Models/
│   └── Recipe.swift
├── Views/
│   ├── ContentView.swift
│   ├── CameraView.swift
│   └── RecipeView.swift
├── Services/
│   └── APIClient.swift
├── Utils/
│   └── ImagePicker.swift
└── KitchenAssistantApp.swift
```
