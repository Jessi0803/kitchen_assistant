# Edge-AI Kitchen Assistant: Complete Analysis of Model Conversion and Platform Differences

This document provides an in-depth analysis of the implementation differences between Server-side (Python) and iOS-side YOLOv8 models, including data structures, processing workflows, and reasons for accuracy discrepancies.

---

## 1. Model File Internal Structure Comparison

### .pt File (PyTorch)

```python
# .pt file is a PyTorch serialized dictionary
{
    'model': OrderedDict([
        ('model.0.conv.weight', tensor([[...]]),
        ('model.0.conv.bias', tensor([...])),
        # ... thousands of weight parameters
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
    },  # ← Class names stored here

    'nc': 11,  # number of classes
    'epoch': 30,
    'optimizer': {...},
    'train_args': {...},
    ...
}
```

**File Structure:**
```
yolov8n.pt (6 MB)
├── model (weights)
├── names (class names) ✅  ← Has this
└── other training information
```

### .mlpackage / .onnx (iOS)

```
yolov8n.mlpackage (6 MB)
├── model (weights) ✅
└── names ❌  ← Doesn't have this!
```

**Why don't iOS models have names?**
- CoreML/ONNX are **universal formats**, not tied to the YOLO framework
- Only preserve the "pure mathematical computation" part
- Class names belong to "post-processing logic", not inside the model file

---

## 2. How Class Names are "Baked" into .pt Models

### During Training (Automatically handled by Ultralytics internally)

```python
# 1. data.yaml (training configuration)
names: ['apple', 'banana', 'broccoli', ...]
nc: 11

# 2. Training script
model = YOLO('yolov8n.pt')
results = model.train(
    data='datasets/merged_food_dataset/data.yaml',  # ← Reads data.yaml
    epochs=30,
    ...
)

# 3. Ultralytics internally does these things (simplified version):
torch.save({
    'model': model.state_dict(),
    'names': {0: 'apple', 1: 'banana', ...},  # ← Baked in here
    'nc': 11,
    ...
}, 'best.pt')
```

### When Loading the Model

```python
model = YOLO('best.pt')
print(model.names)
# Output: {0: 'apple', 1: 'banana', 2: 'broccoli', ...}
# ↑ Automatically read from .pt file, no additional configuration needed
```

---

## 3. Detailed Model Conversion Process

### Complete Conversion Pipeline

```bash
[ .pt model ]  →  execute export_coreml.py  →  [ .onnx intermediate file ]  →  [ .mlpackage final file ]
(PyTorch)                                      (ONNX)                         (CoreML)
```

### export_coreml.py Key Parameter Analysis

```python
model.export(
    format='coreml',  # Target format
    imgsz=640,        # Input size 640x640
    optimize=True,    # Optimizations like constant folding
    half=False,       # Don't use FP16 (maintain FP32 precision)
    nms=True          # Bake NMS into the model
)
```

#### Parameter Details:

1. **format='coreml'**: Explicitly specifies the target format is CoreML
2. **imgsz=640**: Tells the converter that this model expects input image size of 640x640 pixels
3. **optimize=True**: Performs optimizations including "constant folding" to make the model smaller and faster
4. **half=False**: Don't convert model weights from FP32 to FP16, preserving maximum original precision
5. **nms=True**: Directly integrates NMS (Non-Maximum Suppression) logic into the CoreML model

---

## 4. Why is There Precision Loss After Conversion?

Even with `half=False` set, the model conversion process may still result in precision degradation due to the following reasons:

### 4.1 Subtle Differences in Operator Implementation (Main Reason)

PyTorch, ONNX, and CoreML may have extremely subtle differences in implementing the same mathematical operations:
- Convolution
- Upsampling
- Activation functions

When dozens or even hundreds of tiny differences accumulate in the model, the final output can produce significant deviations.

### 4.2 Operator Mismatch

ONNX and CoreML may not support native implementations of all operators used in PyTorch models. Conversion tools will attempt to simulate with equivalent operator combinations, but this may not be perfectly accurate.

### 4.3 Model Input/Output Metadata Errors

The input image format, normalization parameters, or output tensor layout defined in `export_coreml.py` may not match the actual processing in Swift.

---

## 5. End-to-End Data Flow Comparison (Including Data Formats and Shapes)

### Stage 1: Image Preprocessing

#### ➡️ Server Side (`main.py`)
- **Input Source**: `UploadFile` (raw file from HTTP request)
- **Processing Flow**:
  1. Read as bytes, then decode via `PIL.Image.open()`
     - Data format: `PIL.Image` object
  2. Pass to `yolo_model()`, automatically handled by `ultralytics` package for size adjustment (Letterboxing) and normalization
     - Data format: `torch.Tensor`
     - **Shape: `[1, 3, 640, 640]`**
     - Type: `float32`
     - (batch=1, color channels=3, height=640, width=640)

#### ➡️ Local Side (`LocalInferenceService.swift`)
- **Input Source**: `UIImage` (from App UI), obtaining `CGImage` from it
- **Processing Flow**:
  1. `CGImage` is wrapped in `VNImageRequestHandler`
  2. Vision framework automatically handles the image based on `request.imageCropAndScaleOption = .scaleFill` setting when executing the request. It stretches the image to 640x640
     - Data format: `CVPixelBuffer`, with properties of 640x640
     - Pixel format: 32-bit BGRA or RGB
     - CoreML internally treats it as `MLMultiArray`
     - **Shape: `[1, 3, 640, 640]`**
     - Type: `float32`

#### 🚨 Exact Difference Analysis
- **Different processing methods**: Server side uses padding (Letterbox) to maintain aspect ratio; Local side uses stretching (Stretch), distorting aspect ratio
- **Data flow**: Server side is bytes → PIL.Image → torch.Tensor; Local side is UIImage → CGImage → CVPixelBuffer
- **Core issue**: Although the flow is different, the final data shape and type sent to the model are equivalent, but the scaling's **visual content is different**

### Stage 2: Model Inference

#### ➡️ Server Side (`main.py`)
- **Model Input**:
  - `torch.Tensor`
  - **Shape: `[1, 3, 640, 640]`**
  - Type: `float32`
- **Model Raw Output**:
  - `torch.Tensor`
  - **Shape: `[1, 16, 8400]`**
  - Type: `float32`
  - (batch=1, features=16, potential bounding boxes=8400)
  - (16 features = 4 coordinates + 1 object confidence + 11 class confidences)

#### ➡️ Local Side (`LocalInferenceService.swift`)
- **Model Input**:
  - `CVPixelBuffer` (treated by CoreML as `MLMultiArray`)
  - **Shape: `[1, 3, 640, 640]`**
  - Type: `float32`
- **Model Raw Output**:
  - `MLMultiArray`
  - **Shape: `[1, 16, 8400]`**
  - Type: `float32`

#### 🚨 Exact Difference Analysis
- **Data format equivalence**: The data shape and type before sending to the model and when getting raw output from the model are consistent on both platforms
- **Problem not in data format**: But in preprocessing content and post-processing logic

### Stage 3: Output Post-processing

#### ➡️ Server Side (`main.py`)
- **Input Source**:
  - `Results` object from `ultralytics` library
  - This is a pre-processed object, no need to manually parse `[1, 16, 8400]` tensor
  - Contains multiple `torch.Tensor` internally, such as:
    - `results.boxes.xyxy` (coordinates)
    - `results.boxes.conf` (confidence)
    - `results.boxes.cls` (class)
- **Processing Flow**:
  1. Iterate through each detection result in `Results` object
  2. Use `Set` logic to filter duplicate ingredient names
- **Final Output**:
  - `DetectionResponse` (Pydantic model), serialized as JSON dict
  - Example: `{"ingredients": ["Beef", "Pork"], "confidence": [0.88, 0.75], ...}`

#### ➡️ Local Side (`LocalInferenceService.swift`)
- **Input Source**:
  - `MLMultiArray`
  - **Shape: `[1, 16, 8400]`**
  - Type: `float32`
- **Processing Flow**:
  1. Manually iterate through 8400 potential bounding boxes
  2. For each box, calculate `finalConfidence` (object confidence × class confidence)
  3. Filter out results where `finalConfidence < 0.1`
     - Data format: Generate a `[DetectedObject]` array
  4. Pass `[DetectedObject]` into `applyNMS` function, use `iouThreshold = 0.45` for manual NMS
     - Data format: Output a reduced `[DetectedObject]` array
  5. Pass into `removeDuplicatesByDetection`, use `Set` logic to filter duplicate ingredient names
- **Final Output**:
  - `[String]` (Swift string array)
  - Example: `["Beef", "Pork"]`

#### 🚨 Exact Difference Analysis
- **Different input sources**: Server side directly uses clean results processed by the library; Local side starts manually parsing from the most raw, huge `[1, 16, 8400]` tensor, inefficient and error-prone
- **Different NMS logic**: Server side uses library's built-in efficient NMS (IoU=0.7); Local side manually implements an inefficient and different parameter (IoU=0.45) NMS

---

## 6. CoreML Path Problems and Solutions

### Core Problem 1: Incorrect Image Scaling Method (Main Issue)

**Problem Location**:
```swift
request.imageCropAndScaleOption = .scaleFill
```

The `scaleFill` option will **forcibly stretch or compress** the image into the model's required 640x640 square, causing objects in the image (like carrots, cucumbers) to be severely distorted.

**Why is this a problem**:
- During training, the model saw images maintaining original aspect ratio (through "Letterboxing" padding by the `ultralytics` library)
- When it sees flattened or elongated objects on iOS, it naturally cannot accurately recognize them

**Solution**:
```swift
request.imageCropAndScaleOption = .scaleFit
```

The `.scaleFit` option will maintain the image's original aspect ratio, scale the image to fit within a 640x640 frame, then fill the remaining space with black borders. This perfectly replicates server-side behavior.

### Core Problem 2: Redundant and Inconsistent Post-processing (NMS)

**Problem Location**:
1. **Duplicate NMS implementation**: The `export_coreml.py` script uses `nms=True`, which has already integrated efficient NMS logic into the CoreML model. However, the Swift code ignores this optimization, instead parsing the model's raw, huge output tensor (`var_982`), then manually executes its own NMS (`applyNMS`) in the `postProcess` function
2. **NMS parameter mismatch**: Server-side NMS IoU threshold defaults to 0.7, while Swift code is hard-coded as `iouThreshold: Float = 0.45`. A lower IoU threshold more strictly filters overlapping boxes, potentially prematurely removing correct detection results

**Why is this a problem**:
Manually parsing and executing NMS is not only inefficient, but also causes different filtering behavior from the server side due to inconsistent parameters, further reducing detection accuracy.

**Solution**:
The ideal, most efficient approach is to completely remove manual post-processing and NMS logic (most of the `postProcess` function content), directly using the CoreML model's built-in NMS output. Vision framework can return these results directly as `VNRecognizedObjectObservation` objects, greatly simplifying the code.

---

## 7. Summary: Core Differences Between Server vs iOS

| Comparison Item | Server Side (Python + PyTorch) | iOS Side (Swift + CoreML) | Detailed Explanation | Example |
|---------|---------------------------|----------------------|----------|------|
| **Model Format** | `.pt` (PyTorch serialized file) | `.mlpackage` (CoreML) or `.onnx` | `.pt` is Python's serialization format, containing not only model weights but also training configuration, class names, optimizer state and other metadata. CoreML/ONNX are cross-platform universal formats that only preserve pure mathematical computation weight parameters for compatibility, all metadata is removed during conversion. | **Server Side:** `yolov8n_merged_food.pt` (6.3MB) includes complete training history<br>**iOS Side:** `yolov8n_merged_food.mlpackage` (6.0MB) only has weights |
| **Class Name Source** | Dynamically read from `names` dictionary embedded in `.pt` file | Manually maintain array in Swift code | Server side automatically saves class names from `data.yaml` into `.pt` file during training, can use `model.names[0]` to retrieve. iOS side because CoreML/ONNX don't preserve metadata, must manually create `let classNames = ["apple", "banana", ...]` array in code to map model output numeric indices. | **Server Side:** `model.names[0]` outputs `"apple"`<br>**iOS Side:** `classNames[0]` outputs `"apple"` (needs manual definition) |
| **After Model Update** | Automatically synced, no code modification needed | Requires manual sync update of `classNames` array | After retraining the model on server side, new class names are automatically saved in the new `.pt` file, code doesn't need modification. After retraining model on iOS side, must manually check `data.yaml` and sync update the `classNames` array in Swift code, otherwise class name errors will occur. | **Scenario:** Add "garlic" class<br>**Server Side:** Just replace `.pt` file<br>**iOS Side:** Must modify code to add `"garlic"` |
| **Error Risk** | Low (model and names are bound) | High (array order wrong, count mismatch) | Server side because class names and model are bound in the same file, won't have sync issues. iOS side prone to three types of errors: (1) add class but forget to extend array → crash; (2) class order changes but array not synced → display wrong name; (3) delete class but array not removed → index confusion. | **Error Example:** Model outputs class 11, but `classNames` only has 11 elements (indices 0-10) → array out of bounds crash |
| **Image Input Source** | `UploadFile` → `bytes` → `PIL.Image` | `UIImage` → `CGImage` → `CVPixelBuffer` | Server side receives binary data from HTTP request, loads as Image object via Python's PIL library. iOS side gets UIImage from camera or photo album (iOS native image format), converts to CGImage (Core Graphics' bitmap representation), finally wraps as CVPixelBuffer (pixel buffer for video processing) for CoreML use. | **Server Side:** JPEG binary from HTTP upload → PIL.Image<br>**iOS Side:** Camera-captured UIImage → CVPixelBuffer |
| **Preprocessing Method** | `ultralytics` automatic Letterboxing (pad black borders to maintain aspect ratio) | Vision framework, requires manual setting of `.scaleFit` (default `.scaleFill` will distort) | Server side's `ultralytics` automatically executes Letterboxing: scales image proportionally into a 640x640 frame, fills insufficient parts with black borders, ensuring objects don't distort. iOS side when using Vision framework, default `.scaleFill` will forcibly stretch image into square, causing severe object distortion, must change to `.scaleFit` to achieve same effect. This is the main cause of precision differences. | **Original:** 800x600 (horizontal rectangle)<br>**Server Side:** 640x480 + 80px black borders top and bottom = 640x640<br>**iOS Side (wrong):** Forcibly stretched to 640x640 (objects become fat) |
| **Preprocessed Format** | `torch.Tensor` <br> Shape: `[1, 3, 640, 640]` <br> Type: `float32` | `CVPixelBuffer` → CoreML treats as `MLMultiArray` <br> Shape: `[1, 3, 640, 640]` <br> Type: `float32` | Data after preprocessing on both platforms is mathematically equivalent: batch size=1, 3 color channels (RGB), 640x640 pixels, 32-bit floating point (0.0-1.0 range). But key difference is in visual content: if iOS side uses wrong scaling option, even if tensor shape is same, image content will be different due to distortion, causing model to fail recognition. | **Both platforms' tensors:** All 1,228,800 floating point numbers (1×3×640×640)<br>**Value range:** 0.0 (black) ~ 1.0 (white) |
| **Model Inference** | PyTorch engine | CoreML engine (automatically selects hardware) | Server side uses PyTorch's C++ backend for tensor operations, supports complete operator set. iOS side uses Apple's CoreML engine, automatically selects optimal hardware based on model and device: prioritizes Neural Engine (ANE), then Metal GPU, lastly CPU. Different hardware operator implementations have subtle differences (like floating point precision handling, matrix multiplication algorithms), which accumulate into small errors. | **Server Side:** PyTorch C++ backend<br>**iOS Side:** CoreML auto-selects<br>• M series/A series: Neural Engine (ANE)<br>• Older devices: Metal GPU or CPU |
| **Model Raw Output** | `torch.Tensor` <br> Shape: `[1, 16, 8400]` <br> Type: `float32` | `MLMultiArray` <br> Shape: `[1, 16, 8400]` <br> Type: `float32` | Model output is a 3D tensor: batch=1 (single image), 16 features (first 4 are bounding box x, y, w, h coordinates, 5th is object existence confidence, last 11 are class classification scores), 8400 candidate boxes (from different scale feature maps). Both platforms' tensor format is completely same, just different encapsulating data structures (PyTorch uses Tensor, CoreML uses MLMultiArray). | **Output array:** 134,400 floating point numbers (1×16×8400)<br>**0th box:** Indices 0-3 are coordinates, index 4 is confidence, indices 5-15 are 11 class scores |
| **NMS Processing** | `ultralytics` framework automatic handling <br> IoU threshold: 0.7 | Can be built into model (`nms=True`) or manually implemented <br> Manual implementation commonly uses IoU: 0.45 | Non-Maximum Suppression (NMS) is used to eliminate overlapping bounding boxes. Server side's `ultralytics` uses efficient C++ implementation, IoU threshold 0.7 means boxes with overlap exceeding 70% will be merged. iOS side can add `nms=True` during conversion to bake NMS into model, or manually implement in Swift. Manual implementation commonly uses stricter 0.45 threshold, causing different filtering logic, potentially removing correct detection results. | **Scenario:** Same apple has 3 overlapping boxes<br>**Server Side (IoU 0.7):** Keep highest score 1 box<br>**iOS Side (IoU 0.45):** May keep 2 boxes (less filtering) |
| **Post-processing Complexity** | Automatic, no manual parsing needed | Need to manually parse `[1, 16, 8400]` tensor<br>or use Vision framework's `VNRecognizedObjectObservation` | Server side's `ultralytics` automatically parses raw `[1, 16, 8400]` output into structured `Results` object, containing coordinates, confidence, class fields. iOS side must manually iterate through 8400 candidate boxes, calculate final confidence for each box (object confidence × highest class score), filter low confidence results, execute NMS, finally get final detection results. Or use Vision framework to let it handle automatically. | **Server Side:** `results` object automatically contains all info<br>**iOS Side:** Need to manually write loop to process 8400 boxes, about 50 lines of code |
| **Post-processing Input** | `Results` object (already processed)<br>Contains `.boxes.xyxy`, `.boxes.conf`, `.boxes.cls` | Raw `MLMultiArray [1, 16, 8400]`<br>or `[VNRecognizedObjectObservation]` | Server side directly gets high-level encapsulated object, can use `results.boxes.xyxy` to get bounding box coordinate array, `results.boxes.conf` to get confidence array, `results.boxes.cls` to get class index array. iOS side receives flattened floating point array, needs to manually extract data according to index calculation rules (like `floatArray[4 * 8400 + i]` is object confidence of i-th box), or use Vision framework to get parsed `VNRecognizedObjectObservation` objects. | **Server Side:** `results.boxes.xyxy[0]` gets 1st box coordinates<br>**iOS Side:** Need to calculate `floatArray[0]`, `floatArray[8400]`, `floatArray[16800]`, `floatArray[25200]` combine into coordinates |
| **Final Output Format** | JSON dict <br> `{"ingredients": ["Beef", "Pork"], "confidence": [0.88, 0.75]}` | `[String]` array <br> `["Beef", "Pork"]` | Server side returns structured JSON via FastAPI, including detected ingredient list, respective confidence, processing time info, convenient for frontend parsing and display. iOS side usually only needs ingredient name list, so returns simple string array, confidence and coordinates are discarded after internal processing (or stored separately). | **Server Side:** Complete JSON can display confidence bars<br>**iOS Side:** Simple list displays "Beef, Pork" |
| **Development Complexity** | Extremely simple: 1 line of code for inference <br> `results = model('image.jpg')` | Medium: Need to understand Vision framework, CoreML, post-processing logic <br> 30-50+ lines of code | Server side only needs `results = model('image.jpg')` one line of code, `ultralytics` framework automatically handles all details. iOS side needs to write 30-50+ lines of code to handle image preprocessing (resize, format conversion), call CoreML inference, parse output tensor, execute NMS, map class names, requires deep understanding of Vision framework API and model output format. | **Server Side:** `main.py` inference part only needs 1 line<br>**iOS Side:** `LocalInferenceService.swift` needs 200+ lines |
| **Debugging Difficulty** | Easy (framework provides complete error messages) | Difficult (need to track tensor shapes, value ranges) | Server side if error occurs, `ultralytics` provides clear Python error messages, like "image format not supported", "model file corrupted". iOS side when error occurs needs to manually check each step: tensor shape correct (`[1, 3, 640, 640]` vs `[1, 640, 640, 3]`), value range correct (0-1 vs 0-255), class index out of bounds, NMS parameters reasonable, debugging process requires lots of print and visualization. | **Server Side error:** `ValueError: Expected RGB image, got RGBA`<br>**iOS Side error:** No clear message, need to manually print tensor to check |
| **Dependency Environment** | Python + `ultralytics` + PyTorch | Swift + Vision + CoreML | Server side needs to install Python 3.8+, `ultralytics` package, PyTorch library, total installation size about 1-2GB. iOS side uses Apple native Swift language, Vision framework (image processing), CoreML framework (machine learning inference), all built into iOS SDK, no need to install additional third-party packages. | **Server Side:** `pip install ultralytics torch` (1.5GB)<br>**iOS Side:** Xcode built-in (0 extra installation) |
| **Network Requirements** | Required (upload image to server) | None (local inference) | Server side operation: user takes photo in App → upload image via HTTP POST (usually 1-5MB) → server processes → returns JSON result. Needs stable network connection, upload time depends on network speed. iOS side all computation executes locally on device, image doesn't need to leave phone, works normally even in airplane mode or no network environment. | **Server Side:** 4G network upload 2MB image needs 2-3 seconds<br>**iOS Side:** Can use in airplane mode |
| **Privacy** | Low (image needs to be uploaded) | High (image doesn't leave device) | Server side user images are transmitted over network to server, server administrator theoretically can store, view these images, privacy leakage risk exists (although can use encrypted transmission). iOS side image processing entirely on device, image data doesn't leave phone, third parties (including App developers) cannot access, meets highest privacy protection standards. | **Server Side:** Server logs may record all uploaded images<br>**iOS Side:** Images only exist in user phone memory |
| **Operating Cost** | High (server, bandwidth) | Low (no server fees) | Server side needs to rent cloud server (like AWS EC2, GCP Compute Engine), costs include: virtual machine rent (CPU/memory), network bandwidth fees (per GB upload/download), storage space fees. Assuming 100k requests per month, total cost about $50-200/month. iOS side has no server cost, all computation borne by user's device, developer only needs to pay one-time App Store developer account fee ($99/year). | **Server Side:** AWS t3.medium ($30/month) + bandwidth ($20/month) + storage ($10/month) = $60/month<br>**iOS Side:** Apple Developer ($99/year) = $8.25/month |
| **Computational Resources** | Can use multi-core CPU, large memory | Limited by device hardware (phone/tablet) | Server side can deploy on high-end servers, like 32-core CPU, 128GB RAM, GPU acceleration, can simultaneously process multiple requests, run larger models (like YOLOv8x). iOS side limited by phone hardware, like iPhone 14 only has 6 cores (2 performance + 4 efficiency), 6GB RAM, can only run lightweight models (like YOLOv8n), and inference speed slower (100-300ms vs 30-50ms). | **Server Side:** AWS c5.9xlarge (36 cores, 72GB RAM)<br>**iOS Side:** iPhone 14 (6 cores, 6GB RAM) |
| **Model Update** | Simple (replace `.pt` file, restart service) | Complex (need to repackage App, pass review) | Server side updating model only needs: replace old file with new `.pt` file on server, restart FastAPI service (or use hot reload), takes effect immediately, all users automatically use new model. iOS side updating model requires: reconvert to CoreML, update Xcode project, recompile App, submit App Store review (needs 1-3 days), wait for users to update App, entire process needs 3-7 days. | **Server Side:** 5 minutes (upload file + restart)<br>**iOS Side:** 3-7 days (convert + compile + review + user update) |
| **Accuracy** | Highest (original model) | Slightly lower than Server (conversion loss + preprocessing differences) | Server side uses original PyTorch model, no conversion loss, theoretical highest accuracy. iOS side during `.pt` → `.onnx` → `.mlpackage` conversion, operator implementation differences, floating point precision, different preprocessing methods and other factors accumulate causing 5-10% accuracy degradation. For example Server side mAP50 is 0.85, iOS side may drop to 0.78-0.80. | **Server Side:** mAP50 = 0.85 (85% accuracy)<br>**iOS Side:** mAP50 = 0.78-0.80 (78-80% accuracy) |

**Core Concepts**:
- **Server = Pre-packed lunch box** (just eat): Framework highly encapsulated, ready to use out of the box
- **iOS = Ingredient package** (cook yourself): Need to handle preprocessing, post-processing, class mapping yourself

---

## 8. Why Can Server Side Directly Get Class Names, But iOS Side Cannot?

### Server Side (Python + YOLO)

```python
# One line solves it - YOLO framework handles everything for you
results = model('image.jpg')
ingredients = [model.names[int(box.cls)] for box in results[0].boxes]
# Output: ['apple', 'banana', 'carrot']
```

**Key: `model.names` is not hard-coded!**

`model.names` is **dynamically read** from the `.pt` model file:
- Stored inside the `.pt` model weight file
- Automatically embedded into the model from `data.yaml` during training

### iOS Side (CoreML/ONNX)

```swift
// Need to manually parse raw output
let output = model.prediction(from: image)  // Raw tensor

// Output format: [1, 84, 8400] floating point array
// 84 = 4(coordinates) + 80(class probabilities)
// 8400 = prediction boxes at different scales

// You need to manually:
// 1. Parse each prediction box's 80 class scores
// 2. Find highest score class index
// 3. Apply NMS to filter overlapping boxes
// 4. Use hard-coded array to map class names
let classNames = ["apple", "banana", "carrot", ...]  // Must manually maintain
let ingredient = classNames[classIndex]
```

---

## 9. Why Does iOS Need to Manually Maintain Class Name Array?

### Models Actually Output Numbers, Not Text!

#### iOS Model Output:
```swift
// Model sees apple
let prediction = model.predict(image)
// Output: class = 0, confidence = 0.95

// Model sees banana
let prediction = model.predict(image)
// Output: class = 1, confidence = 0.87
```

The model only gives you **numbers 0, 1, 2...**, it won't give you "apple", "banana"!

#### Why Need Swift Array?

To turn numbers into meaningful names:

```swift
// If there's no array
let classIndex = 0
// You can only display: "Detected class 0" ❓

// With this array
let classNames = ["apple", "banana", "carrot", ...]
let detectedFood = classNames[classIndex]  // "apple"
// Can display: "Detected apple 🍎" ✅
```

#### Contrast with Server Side

```python
# Python YOLO framework does this conversion for you
results = model('image.jpg')

# What it does internally:
# 1. Model outputs class=0
# 2. Automatically looks up table model.names[0] = 'apple'
# 3. box.cls directly gives you 'apple'

for box in results[0].boxes:
    print(box.cls)  # Already 'apple', not 0
```

| | Model Output | Need Manual Conversion? |
|---|---|---|
| **iOS** | Numbers (0, 1, 2...) | ✅ Need classNames array |
| **Server** | Numbers → YOLO framework auto converts | ❌ Framework handled |

**No Swift array = Your App can only display "class 0" "class 1", users can't understand!**

---

## 10. Synchronization Risks When Updating Model

### Scenario 1: Adding Classes

```python
# Original data.yaml (11 classes)
names: ['apple', 'banana', 'broccoli', 'carrot', 'corn',
        'cucumber', 'eggplant', 'onion', 'potato', 'tomato', 'zucchini']

# Retrain, add new ingredients (13 classes)
names: ['apple', 'banana', 'broccoli', 'carrot', 'corn',
        'cucumber', 'eggplant', 'onion', 'potato', 'tomato', 'zucchini',
        'garlic', 'ginger']  # ← Added

# Export new model to iOS
# ❌ But forgot to update Swift code's classNames array
```

**Result:**
- Model detects garlic (class 11)
- Swift array only has 11 elements → **crash** or display error

### Scenario 2: Changing Order

```python
# First training
names: ['apple', 'banana', 'carrot']  # apple=0, banana=1, carrot=2

# After reorganizing dataset
names: ['banana', 'apple', 'carrot']  # banana=0, apple=1, carrot=2

# ❌ iOS's classNames didn't sync update order
let classNames = ["apple", "banana", "carrot"]  // Still old order
```

**Result:**
- Camera sees banana → model outputs class 0
- Swift looks up array `classNames[0]` → displays "apple" ❌

### Scenario 3: Deleting Classes

```python
# Originally 11 classes, found zucchini data too little, remove it
names: ['apple', 'banana', 'broccoli', 'carrot', 'corn',
        'cucumber', 'eggplant', 'onion', 'potato', 'tomato']  # 10 classes left

# ❌ iOS still keeps 11 class names
```

**Result:**
- Model will never output class 10
- But Swift array still has 'zucchini' → waste memory, and index confusion