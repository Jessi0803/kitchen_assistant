# Edge-AI Kitchen Assistant: 模型轉換與平台差異完整解析

本文件深入解析 YOLOv8 模型在 Server 端（Python）與 iOS 端的實作差異，包含資料結構、處理流程、以及為何會產生精度落差。

---

## 1. 模型檔案內部結構對比

### .pt 檔案（PyTorch）

```python
# .pt 檔案是 PyTorch 的序列化字典
{
    'model': OrderedDict([
        ('model.0.conv.weight', tensor([[...]]),
        ('model.0.conv.bias', tensor([...])),
        # ... 數千層的權重參數
    ]),

    'names': {
        0: 'apple',
        1: 'banana',
        2: 'broccoli',
        3: 'carrot',
        4: 'corn',
        5: 'cucumber',
        6: 'eggplant',
        7: 'onion',
        8: 'potato',
        9: 'tomato',
        10: 'zucchini'
    },  # ← 類別名稱儲存在這裡

    'nc': 11,  # number of classes
    'epoch': 30,
    'optimizer': {...},
    'train_args': {...},
    ...
}
```

**檔案結構：**
```
yolov8n.pt (6 MB)
├── model (權重)
├── names (類別名稱) ✅  ← 有這個
└── 其他訓練資訊
```

### .mlpackage / .onnx（iOS）

```
yolov8n.mlpackage (6 MB)
├── model (權重) ✅
└── names ❌  ← 沒有這個！
```

**為什麼 iOS 模型沒有 names？**
- CoreML/ONNX 是**通用格式**，不綁定 YOLO 框架
- 只保留「純數學運算」的部分
- 類別名稱屬於「後處理邏輯」，不在模型檔內

---

## 2. 類別名稱如何「烘焙」進 .pt 模型

### 訓練時（Ultralytics 內部自動處理）

```python
# 1. data.yaml (訓練配置)
names: ['apple', 'banana', 'broccoli', ...]
nc: 11

# 2. 訓練腳本
model = YOLO('yolov8n.pt')
results = model.train(
    data='datasets/merged_food_dataset/data.yaml',  # ← 讀取 data.yaml
    epochs=30,
    ...
)

# 3. Ultralytics 內部會做這些事（簡化版）：
torch.save({
    'model': model.state_dict(),
    'names': {0: 'apple', 1: 'banana', ...},  # ← 烘焙在這裡
    'nc': 11,
    ...
}, 'best.pt')
```

### 載入模型時

```python
model = YOLO('best.pt')
print(model.names)
# 輸出: {0: 'apple', 1: 'banana', 2: 'broccoli', ...}
# ↑ 自動從 .pt 檔讀取，不需要額外配置
```

---

## 3. 模型轉換流程詳解

### 完整轉換鏈路

```bash
[ .pt 模型 ]  →  執行 export_coreml.py  →  [ .onnx 中間檔 ]  →  [ .mlpackage 最終檔 ]
(PyTorch)                                    (ONNX)              (CoreML)
```

### export_coreml.py 關鍵參數解析

```python
model.export(
    format='coreml',  # 目標格式
    imgsz=640,        # 輸入尺寸 640x640
    optimize=True,    # 常量摺疊等優化
    half=False,       # 不使用 FP16（保持 FP32 精度）
    nms=True          # 將 NMS 烘焙進模型
)
```

#### 參數詳解：

1. **format='coreml'**: 明確指出要轉換的目標格式是 CoreML
2. **imgsz=640**: 告知轉換器，這個模型期望的輸入圖片尺寸是 640x640 像素
3. **optimize=True**: 進行優化，包括「常量摺疊」（constant folding）等步驟，讓模型更小、更快
4. **half=False**: 不將模型權重從 FP32 轉換為 FP16，最大程度保留原始精度
5. **nms=True**: 將 NMS（非極大值抑制）邏輯直接內置到 CoreML 模型中

---

## 4. 為何轉換後會有精度損失？

即使設定了 `half=False`，模型轉換過程中仍可能因以下原因產生精度下降：

### 4.1 運算子實現的細微差異（主要原因）

PyTorch、ONNX 和 CoreML 對同一個數學運算的實現可能有極微小的差異：
- 卷積（Convolution）
- 上採樣（Upsampling）
- 激活函數（Activation）

當數十個甚至數百個微小差異在模型中累積，最終輸出就可能產生顯著偏差。

### 4.2 運算子不匹配

ONNX 和 CoreML 可能不支持 PyTorch 模型中使用的所有運算子的原生實現。轉換工具會嘗試用等效的運算子組合來模擬，但這可能不完全精確。

### 4.3 模型輸入/輸出元數據錯誤

在 `export_coreml.py` 中定義的輸入圖像格式、標準化參數或輸出張量的佈局可能與 Swift 中的實際處理方式不匹配。

---

## 5. 端到端資料流程比較（含資料格式與形狀）

### 階段一：圖像預處理

#### ➡️ Server 端 (`main.py`)
- **輸入源**: `UploadFile` (來自 HTTP 請求的原始檔案)
- **處理流程**:
  1. 讀取為 bytes，再透過 `PIL.Image.open()` 解碼
     - 資料格式: `PIL.Image` 物件
  2. 傳遞給 `yolo_model()`，由 `ultralytics` 套件自動處理尺寸調整（Letterboxing）與標準化
     - 資料格式: `torch.Tensor`
     - **形狀: `[1, 3, 640, 640]`**
     - 型態: `float32`
     - (批次=1, 色彩通道=3, 高度=640, 寬度=640)

#### ➡️ Local 端 (`LocalInferenceService.swift`)
- **輸入源**: `UIImage` (來自 App UI)，從中獲取 `CGImage`
- **處理流程**:
  1. `CGImage` 被包裝在 `VNImageRequestHandler` 中
  2. Vision 框架根據 `request.imageCropAndScaleOption = .scaleFill` 的設定，在執行請求時自動處理圖像。它將圖像拉伸成 640x640
     - 資料格式: `CVPixelBuffer`，其屬性為 640x640
     - 像素格式: 32-bit BGRA 或 RGB
     - CoreML 在內部會將其視為 `MLMultiArray`
     - **形狀: `[1, 3, 640, 640]`**
     - 型態: `float32`

#### 🚨 確切差異分析
- **處理方式不同**: Server 端是補邊 (Letterbox)，保持長寬比；Local 端是拉伸 (Stretch)，扭曲長寬比
- **資料流程**: Server 端是 bytes → PIL.Image → torch.Tensor；Local 端是 UIImage → CGImage → CVPixelBuffer
- **核心問題**: 儘管流程不同，最終送入模型的資料形狀和型態是等價的，但縮放的**視覺內容不同**

### 階段二：模型推理

#### ➡️ Server 端 (`main.py`)
- **模型輸入**:
  - `torch.Tensor`
  - **形狀: `[1, 3, 640, 640]`**
  - 型態: `float32`
- **模型原始輸出**:
  - `torch.Tensor`
  - **形狀: `[1, 16, 8400]`**
  - 型態: `float32`
  - (批次=1, 特徵=16, 潛在邊界框=8400)
  - (16 個特徵 = 4個座標 + 1個物體信心度 + 11個分類信心度)

#### ➡️ Local 端 (`LocalInferenceService.swift`)
- **模型輸入**:
  - `CVPixelBuffer` (被 CoreML 視為 `MLMultiArray`)
  - **形狀: `[1, 3, 640, 640]`**
  - 型態: `float32`
- **模型原始輸出**:
  - `MLMultiArray`
  - **形狀: `[1, 16, 8400]`**
  - 型態: `float32`

#### 🚨 確切差異分析
- **資料格式等價**: 兩個平台在送入模型前和從模型獲取原始輸出時的資料形狀與型態是一致的
- **問題不在資料格式**: 而出在預處理的內容和後處理的邏輯

### 階段三：輸出後處理

#### ➡️ Server 端 (`main.py`)
- **輸入源**:
  - `ultralytics` 函式庫的 `Results` 物件
  - 這是一個已處理好的物件，無需手動解析 `[1, 16, 8400]` 的張量
  - 內部包含多個 `torch.Tensor`，如：
    - `results.boxes.xyxy` (座標)
    - `results.boxes.conf` (信心度)
    - `results.boxes.cls` (類別)
- **處理流程**:
  1. 遍歷 `Results` 物件中的每個偵測結果
  2. 用 `Set` 邏輯過濾重複的食材名稱
- **最終輸出**:
  - `DetectionResponse` (Pydantic 模型)，序列化後為 JSON dict
  - 範例: `{"ingredients": ["Beef", "Pork"], "confidence": [0.88, 0.75], ...}`

#### ➡️ Local 端 (`LocalInferenceService.swift`)
- **輸入源**:
  - `MLMultiArray`
  - **形狀: `[1, 16, 8400]`**
  - 型態: `float32`
- **處理流程**:
  1. 手動遍歷 8400 個潛在邊界框
  2. 對每個框，計算 `finalConfidence` (物體信心度 × 分類信心度)
  3. 過濾掉 `finalConfidence < 0.1` 的結果
     - 資料格式: 產生一個 `[DetectedObject]` 陣列
  4. 將 `[DetectedObject]` 傳入 `applyNMS` 函數，使用 `iouThreshold = 0.45` 進行手動 NMS
     - 資料格式: 輸出一個數量減少的 `[DetectedObject]` 陣列
  5. 傳入 `removeDuplicatesByDetection`，用 `Set` 邏輯過濾重複的食材名稱
- **最終輸出**:
  - `[String]` (Swift 字符串陣列)
  - 範例: `["Beef", "Pork"]`

#### 🚨 確切差異分析
- **輸入源不同**: Server 端直接使用函式庫處理好的乾淨結果；Local 端從最原始、龐大的 `[1, 16, 8400]` 張量開始手動解析，效率低且易出錯
- **NMS 邏輯不同**: Server 端使用函式庫內置的高效 NMS (IoU=0.7)；Local 端手動實現了一套低效且參數不同 (IoU=0.45) 的 NMS

---

## 6. CoreML 路徑的問題與解決方案

### 核心問題 1：圖像縮放方式錯誤（主要問題）

**問題所在**:
```swift
request.imageCropAndScaleOption = .scaleFill
```

`scaleFill` 這個選項會將圖片**強制拉伸或壓縮**成模型所需的 640x640 正方形，導致圖片中的物體（如蘿蔔、小黃瓜）嚴重變形。

**為何是問題**:
- 模型在訓練時，看到的是保持原始長寬比的圖片（透過 `ultralytics` 函式庫的 "Letterboxing" 補邊處理）
- 當它在 iOS 上看到被壓扁或拉長的物體時，自然無法準確識別

**解決方案**:
```swift
request.imageCropAndScaleOption = .scaleFit
```

`.scaleFit` 這個選項會保持圖片的原始長寬比，將圖片縮放到能放進 640x640 的框內，然後用黑邊填充剩餘的空白區域。這完美複製了伺服器端的行為。

### 核心問題 2：多餘且不一致的後處理（NMS）

**問題所在**:
1. **重複實現 NMS**: `export_coreml.py` 腳本中使用了 `nms=True`，這已經將高效的 NMS 邏輯整合進了 CoreML 模型。然而，Swift 程式碼忽略了這個優化，反而去解析模型的原始、巨大的輸出張量（`var_982`），然後在 `postProcess` 函數中手動執行了一遍自己寫的 NMS (`applyNMS`)
2. **NMS 參數不匹配**: 伺服器端的 NMS IoU 閾值預設是 0.7，而 Swift 程式碼中硬編碼為 `iouThreshold: Float = 0.45`。更低的 IoU 閾值會更嚴格地過濾掉重疊的框，可能過早地刪除了正確的檢測結果

**為何是問題**:
手動解析並執行 NMS 不僅效率低下，而且因為參數不一致，導致了與伺服器端不同的過濾行為，進一步降低了檢測準確率。

**解決方案**:
最理想、最高效的做法是完全移除手動的後處理和 NMS 邏輯 (`postProcess` 函數的大部分內容)，直接使用 CoreML 模型內置的 NMS 輸出。Vision 框架可以將這些結果直接作為 `VNRecognizedObjectObservation` 對象返回，極大地簡化程式碼。

---

## 7. 總結：Server vs iOS 的核心差異

| 比較項目 | Server 端（Python + PyTorch） | iOS 端（Swift + CoreML） | 說明 |
|---------|---------------------------|----------------------|------|
| **🗂️ 模型格式** | `.pt` (PyTorch 序列化檔) | `.mlpackage` (CoreML) 或 `.onnx` | `.pt` 包含權重+metadata；CoreML/ONNX 只有權重 |
| **📝 類別名稱來源** | 從 `.pt` 檔內嵌的 `names` 字典動態讀取 | 手動在 Swift 程式碼中維護陣列 | Server 端：`model.names[0]`；iOS 端：`classNames[0]` |
| **🔄 模型更新後** | 自動同步，無需修改程式碼 | 需手動同步更新 `classNames` 陣列 | 忘記同步會導致類別名稱錯誤或 crash |
| **⚠️ 錯誤風險** | 低（模型和名稱綁定） | 高（陣列順序錯、數量不符） | iOS 端容易因新增/刪除/重排類別而出錯 |
| **🖼️ 圖像輸入源** | `UploadFile` → `bytes` → `PIL.Image` | `UIImage` → `CGImage` → `CVPixelBuffer` | 不同平台的圖像物件 |
| **📐 預處理方式** | `ultralytics` 自動 Letterboxing（補黑邊保持長寬比） | Vision 框架，需手動設定 `.scaleFit`（預設 `.scaleFill` 會變形） | 預處理不一致是主要精度損失原因 |
| **📦 預處理後格式** | `torch.Tensor` <br> 形狀: `[1, 3, 640, 640]` <br> 型態: `float32` | `CVPixelBuffer` → CoreML 視為 `MLMultiArray` <br> 形狀: `[1, 3, 640, 640]` <br> 型態: `float32` | 形狀和型態等價，但視覺內容因縮放方式而異 |
| **🧠 模型推理** | PyTorch 引擎 | CoreML 引擎 | 底層運算子實現有微小差異，會累積誤差 |
| **📤 模型原始輸出** | `torch.Tensor` <br> 形狀: `[1, 16, 8400]` | `MLMultiArray` <br> 形狀: `[1, 16, 8400]` | 16 = 4座標 + 1物體信心度 + 11分類信心度；8400 個候選框 |
| **🧹 NMS 處理** | `ultralytics` 框架自動處理 <br> IoU 閾值: 0.7 | 可內置於模型（`nms=True`）或手動實現 <br> 手動實現常用 IoU: 0.45 | NMS 參數不一致會影響最終結果 |
| **🔧 後處理複雜度** | 自動，無需手動解析 | 需手動解析 `[1, 16, 8400]` 張量<br>或使用 Vision 框架的 `VNRecognizedObjectObservation` | 手動解析易出錯且效率低 |
| **📊 後處理輸入** | `Results` 物件（已處理好）<br>包含 `.boxes.xyxy`, `.boxes.conf`, `.boxes.cls` | 原始 `MLMultiArray [1, 16, 8400]`<br>或 `[VNRecognizedObjectObservation]` | Server 端使用高階封裝；iOS 端需從原始數據開始 |
| **🎯 最終輸出格式** | JSON dict <br> `{"ingredients": ["Beef", "Pork"], "confidence": [0.88, 0.75]}` | `[String]` 陣列 <br> `["Beef", "Pork"]` | 不同的資料結構 |
| **💻 開發複雜度** | 極簡：1 行程式碼搞定推理 <br> `results = model('image.jpg')` | 中等：需理解 Vision 框架、CoreML、後處理邏輯 <br> 30-50+ 行程式碼 | Server 端高度封裝；iOS 端需手動處理多個環節 |
| **🛠️ 除錯難度** | 容易（框架提供完整錯誤訊息） | 困難（需追蹤張量形狀、數值範圍） | iOS 端需手動驗證每個處理步驟 |
| **📱 依賴環境** | Python + `ultralytics` + PyTorch | Swift + Vision + CoreML | 不同的技術棧 |
| **🌐 網路需求** | 需要（上傳圖片到伺服器） | 無（本地推理） | iOS 端可離線運作 |
| **🔒 隱私性** | 低（圖片需上傳） | 高（圖片不離開裝置） | iOS 端更保護使用者隱私 |
| **💰 營運成本** | 高（伺服器、頻寬） | 低（無伺服器費用） | iOS 端長期成本較低 |
| **⚡ 運算資源** | 可使用多核 CPU、大記憶體 | 受限於裝置硬體（手機/平板） | Server 端可處理更複雜的模型 |
| **🔄 模型更新** | 簡單（替換 `.pt` 檔，重啟服務） | 複雜（需重新打包 App，通過審核） | Server 端更新更靈活 |
| **📈 精度** | 最高（原始模型） | 略低於 Server（轉換損失 + 預處理差異） | 轉換過程中運算子實現差異會累積 |

**核心概念**:
- **Server = 拆好的便當**（直接吃）：框架高度封裝，開箱即用
- **iOS = 食材包**（自己煮）：需要自己處理預處理、後處理、類別映射

---

## 8. 為何 Server 端可以直接取得類別名稱，iOS 端卻不行？

### Server 端（Python + YOLO）

```python
# 一行搞定 - YOLO框架幫你處理好一切
results = model('image.jpg')
ingredients = [model.names[int(box.cls)] for box in results[0].boxes]
# 輸出: ['apple', 'banana', 'carrot']
```

**關鍵：`model.names` 不是硬編碼！**

`model.names` 是從 `.pt` 模型文件中**動態讀取**的：
- 儲存在 `.pt` 模型權重檔內
- 訓練時從 `data.yaml` 自動嵌入模型中

### iOS 端（CoreML/ONNX）

```swift
// 需要手動解析原始輸出
let output = model.prediction(from: image)  // 原始張量

// 輸出格式: [1, 84, 8400] 的浮點數陣列
// 84 = 4(座標) + 80(類別機率)
// 8400 = 不同尺度的預測框

// 你需要手動做：
// 1. 解析每個預測框的 80 個類別分數
// 2. 找出最高分數的類別索引
// 3. 套用 NMS 過濾重疊框
// 4. 用硬編碼的陣列對應類別名稱
let classNames = ["apple", "banana", "carrot", ...]  // 必須手動維護
let ingredient = classNames[classIndex]
```

---

## 9. 為什麼 iOS 需要手動維護類別名稱陣列？

### 模型實際輸出的是數字，不是文字！

#### iOS 模型輸出：
```swift
// 模型看到蘋果
let prediction = model.predict(image)
// 輸出: class = 0, confidence = 0.95

// 模型看到香蕉
let prediction = model.predict(image)
// 輸出: class = 1, confidence = 0.87
```

模型只給你 **數字 0, 1, 2...**，不會給你 "apple", "banana"！

#### 為什麼需要 Swift 陣列？

要把數字變成有意義的名稱：

```swift
// 如果沒有這個陣列
let classIndex = 0
// 你只能顯示：「偵測到 class 0」❓

// 有了這個陣列
let classNames = ["apple", "banana", "carrot", ...]
let detectedFood = classNames[classIndex]  // "apple"
// 可以顯示：「偵測到 蘋果 🍎」✅
```

#### 對比 Server 端

```python
# Python YOLO 框架幫你做了這個轉換
results = model('image.jpg')

# 內部做的事：
# 1. 模型輸出 class=0
# 2. 自動查表 model.names[0] = 'apple'
# 3. box.cls 直接給你 'apple'

for box in results[0].boxes:
    print(box.cls)  # 已經是 'apple'，不是 0
```

| | 模型輸出 | 需要手動轉換？ |
|---|---|---|
| **iOS** | 數字 (0, 1, 2...) | ✅ 需要 classNames 陣列 |
| **Server** | 數字 → YOLO 框架自動轉換 | ❌ 框架已處理 |

**沒有 Swift 陣列 = 你的 App 只能顯示「class 0」「class 1」，使用者看不懂！**

---

## 10. 模型更新時的同步風險

### 情境 1：新增類別

```python
# 原本的 data.yaml (11 類)
names: ['apple', 'banana', 'broccoli', 'carrot', 'corn',
        'cucumber', 'eggplant', 'onion', 'potato', 'tomato', 'zucchini']

# 重新訓練，加入新食材 (13 類)
names: ['apple', 'banana', 'broccoli', 'carrot', 'corn',
        'cucumber', 'eggplant', 'onion', 'potato', 'tomato', 'zucchini',
        'garlic', 'ginger']  # ← 新增

# 匯出新模型到 iOS
# ❌ 但忘記更新 Swift 程式碼的 classNames 陣列
```

**結果：**
- 模型偵測到 garlic (class 11)
- Swift 陣列只有 11 個元素 → **crash** 或顯示錯誤

### 情境 2：改變順序

```python
# 第一次訓練
names: ['apple', 'banana', 'carrot']  # apple=0, banana=1, carrot=2

# 重新整理資料集後
names: ['banana', 'apple', 'carrot']  # banana=0, apple=1, carrot=2

# ❌ iOS 的 classNames 沒同步更新順序
let classNames = ["apple", "banana", "carrot"]  // 還是舊順序
```

**結果：**
- 鏡頭看到香蕉 → 模型輸出 class 0
- Swift 查陣列 `classNames[0]` → 顯示 "apple" ❌

### 情境 3：刪除類別

```python
# 原本 11 類，發現 zucchini 資料太少，移除它
names: ['apple', 'banana', 'broccoli', 'carrot', 'corn',
        'cucumber', 'eggplant', 'onion', 'potato', 'tomato']  # 剩 10 類

# ❌ iOS 還是保留 11 個類別名稱
```

**結果：**
- 模型永遠不會輸出 class 10
- 但 Swift 陣列還有 'zucchini' → 浪費記憶體，且索引混亂