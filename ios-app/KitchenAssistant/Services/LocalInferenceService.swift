import CoreML
import Vision
import UIKit

enum LocalInferenceError: Error, LocalizedError {
    case modelLoadingFailed(String)
    case imageProcessingFailed(String)
    case predictionFailed(String)
    case postProcessingFailed(String)
    case sessionInitializationFailed(String)
    case noValidDetections

    var errorDescription: String? {
        switch self {
        case .modelLoadingFailed(let message):
            return "CoreML Model Loading Failed: \(message)"
        case .imageProcessingFailed(let message):
            return "Image Processing Failed: \(message)"
        case .predictionFailed(let message):
            return "Prediction Failed: \(message)"
        case .postProcessingFailed(let message):
            return "Post-processing Failed: \(message)"
        case .sessionInitializationFailed(let message):
            return "CoreML Session Initialization Failed: \(message)"
        case .noValidDetections:
            return "No valid detections found"
        }
    }
}

class LocalInferenceService: ObservableObject {
    private var visionModel: VNCoreMLModel?
    // 與服務器端 YOLO_TO_FOOD_MAPPING 一致的類別映射
    private let classLabels: [String] = [
        "beef", "pork", "chicken", "butter", "cheese", "milk",
        "broccoli", "carrot", "cucumber", "lettuce", "tomato"
    ]
    
    // 服務器端的類別映射（小寫 -> 大寫）
    private let classMapping: [String: String] = [
        "beef": "Beef",
        "pork": "Pork", 
        "chicken": "Chicken",
        "butter": "Butter",
        "cheese": "Cheese",
        "milk": "Milk",
        "broccoli": "Broccoli",
        "carrot": "Carrot",
        "cucumber": "Cucumber",
        "lettuce": "Lettuce",
        "tomato": "Tomato"
    ]
    private let inputSize: CGFloat = 640
    private let confidenceThreshold: Float = 0.1  // 與服務器端一致
    private let iouThreshold: Float = 0.45  // 與服務器端一致

    init() {
        setupModel()
    }

    private func setupModel() {
        // 首先檢查 bundle 內容
        print("🔍 檢查 Bundle 內容...")
        if let resourcePath = Bundle.main.resourcePath {
            print("📁 Bundle 資源路徑: \(resourcePath)")
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("📋 Bundle 內容:")
                for item in contents {
                    print("  - \(item)")
                }
            } catch {
                print("❌ 無法讀取 bundle 內容: \(error)")
            }
        }
        
        // 首先嘗試 .mlmodelc 格式（編譯後的 CoreML 模型）
        var modelURL: URL?
        if let mlmodelcURL = Bundle.main.url(forResource: "yolov8n_merged_food_cpu_aug_finetuned", withExtension: "mlmodelc") {
            modelURL = mlmodelcURL
            print("✅ 找到 .mlmodelc 文件: \(mlmodelcURL)")
        } else if let mlpackageURL = Bundle.main.url(forResource: "yolov8n_merged_food_cpu_aug_finetuned", withExtension: "mlpackage") {
            modelURL = mlpackageURL
            print("✅ 找到 .mlpackage 文件: \(mlpackageURL)")
        } else {
            print("❌ CoreML Model file not found in app bundle.")
            print("💡 請確保在 Xcode 中將 .mlpackage 文件添加到項目中")
            return
        }

        guard let finalModelURL = modelURL else {
            print("❌ No valid model URL found")
            return
        }

        do {
            let coreMLModel = try MLModel(contentsOf: finalModelURL)
            visionModel = try VNCoreMLModel(for: coreMLModel)
            print("✅ CoreML model loaded successfully.")
            print("📊 Model file: \(finalModelURL.lastPathComponent)")
            print("🎯 Input size: \(inputSize)x\(inputSize)")
            print("🔧 Classes: \(classLabels.count) food categories")
        } catch {
            print("❌ Failed to load CoreML model: \(error.localizedDescription)")
        }
    }

    func detect(image: UIImage) async throws -> [String] {
        guard let visionModel = visionModel else {
            throw LocalInferenceError.sessionInitializationFailed("CoreML model not loaded.")
        }

        guard let cgImage = image.cgImage else {
            throw LocalInferenceError.imageProcessingFailed("Could not get CGImage from UIImage.")
        }

        print("🚀 開始 CoreML YOLO 推理...")
        let startTime = CFAbsoluteTimeGetCurrent()

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNCoreMLRequest(model: visionModel) { [weak self] request, error in
                guard let self = self else {
                    continuation.resume(throwing: LocalInferenceError.sessionInitializationFailed("Self deallocated during request."))
                    return
                }

                if let error = error {
                    print("❌ VNCoreMLRequest failed: \(error.localizedDescription)")
                    continuation.resume(throwing: LocalInferenceError.predictionFailed(error.localizedDescription))
                    return
                }

                guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
                    print("❌ No VNCoreMLFeatureValueObservation results.")
                    continuation.resume(throwing: LocalInferenceError.predictionFailed("No VNCoreMLFeatureValueObservation results."))
                    return
                }

                do {
                    let detectedObjects = try self.postProcess(observations: observations)
                    let ingredientNames = detectedObjects.map { $0.label }
                    
                    let endTime = CFAbsoluteTimeGetCurrent()
                    let inferenceTime = endTime - startTime
                    print("⏱️ CoreML 推理時間: \(String(format: "%.3f", inferenceTime))秒")
                    print("🎯 檢測到食材: \(ingredientNames)")
                    
                    if ingredientNames.isEmpty {
                        continuation.resume(throwing: LocalInferenceError.noValidDetections)
                    } else {
                        continuation.resume(returning: ingredientNames)
                    }
                } catch {
                    print("❌ Post-processing failed: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
            }
            
            request.imageCropAndScaleOption = .scaleFill
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("❌ VNImageRequestHandler failed: \(error.localizedDescription)")
                continuation.resume(throwing: LocalInferenceError.predictionFailed("VNImageRequestHandler failed: \(error.localizedDescription)"))
            }
        }
    }

    private func postProcess(observations: [VNCoreMLFeatureValueObservation]) throws -> [DetectedObject] {
        // YOLOv8 CoreML output structure:
        // The model output is typically a single MLMultiArray with shape (1, num_boxes, num_classes + 4)
        // or a dictionary of MLMultiArrays.
        
        // Find the output that contains the detections
        // Common names are 'var_982', 'var_1000', 'output', 'feature_map', etc.
        guard let outputFeature = observations.first(where: { 
            $0.featureName == "var_982" ||
            $0.featureName == "var_1000" || 
            $0.featureName == "output" || 
            $0.featureName == "feature_map" ||
            $0.featureName == "output0"
        }) else {
            print("❌ Available feature names: \(observations.map { $0.featureName })")
            throw LocalInferenceError.postProcessingFailed("Could not find expected output feature.")
        }

        guard let multiArray = outputFeature.featureValue.multiArrayValue else {
            throw LocalInferenceError.postProcessingFailed("Output feature is not an MLMultiArray.")
        }

        print("🔍 CoreML output shape: \(multiArray.shape)")
        print("🔍 Total elements: \(multiArray.count)")

        // The output shape is typically (1, 16, 8400) for YOLOv8n, where 16 = 4 (bbox) + 1 (conf) + 11 (classes)
        // Reshape to (num_boxes, num_features) for easier processing
        let numBoxes = multiArray.shape[2].intValue // 8400
        let numFeatures = multiArray.shape[1].intValue // 16 (4 bbox + 1 obj_conf + 11 class_conf)
        
        print("🔍 解析參數: numBoxes=\(numBoxes), numFeatures=\(numFeatures), numClasses=\(classLabels.count)")

        var detections: [DetectedObject] = []
        var maxConfidence: Float = 0.0

        for i in 0..<numBoxes {
            let boxConfidence = multiArray[i * numFeatures + 4].floatValue // Objectness score
            
            if boxConfidence < 0.001 { continue } // Early filtering

            var classScores: [Float] = []
            for j in 0..<classLabels.count {
                classScores.append(multiArray[i * numFeatures + 5 + j].floatValue)
            }

            guard let maxClassScore = classScores.max(),
                  let classIndex = classScores.firstIndex(of: maxClassScore) else {
                continue
            }

            let finalConfidence = maxClassScore * boxConfidence
            
            if finalConfidence > maxConfidence {
                maxConfidence = finalConfidence
            }

            if finalConfidence < confidenceThreshold { continue }

            let label = classLabels[classIndex]

            // Bounding box coordinates (x, y, width, height) - normalized
            let x = multiArray[i * numFeatures].floatValue
            let y = multiArray[i * numFeatures + 1].floatValue
            let width = multiArray[i * numFeatures + 2].floatValue
            let height = multiArray[i * numFeatures + 3].floatValue

            // Convert YOLO format (center_x, center_y, width, height) to CGRect (min_x, min_y, width, height)
            let rect = CGRect(
                x: CGFloat(x - width / 2),
                y: CGFloat(y - height / 2),
                width: CGFloat(width),
                height: CGFloat(height)
            )

            detections.append(DetectedObject(rect: rect, confidence: finalConfidence, label: label))
        }

        print("📊 原始檢測數量: \(detections.count)")
        print("📊 最高信心度: \(String(format: "%.6f", maxConfidence))")

        // Apply Non-Maximum Suppression
        let nmsDetections = applyNMS(detections: detections, iouThreshold: iouThreshold)
        print("📊 NMS 後檢測數量: \(nmsDetections.count)")

        // 與服務器端一致的去重邏輯：按檢測結果去重，而不是按類別去重
        let uniqueDetections = removeDuplicatesByDetection(detections: nmsDetections)
        print("📊 去重後檢測數量: \(uniqueDetections.count)")

        return uniqueDetections
    }

    private func applyNMS(detections: [DetectedObject], iouThreshold: Float) -> [DetectedObject] {
        var sortedDetections = detections.sorted { $0.confidence > $1.confidence }
        var finalDetections: [DetectedObject] = []

        while !sortedDetections.isEmpty {
            let first = sortedDetections.removeFirst()
            finalDetections.append(first)

            sortedDetections = sortedDetections.filter {
                iou(box1: first.rect, box2: $0.rect) < iouThreshold
            }
        }
        return finalDetections
    }

    private func iou(box1: CGRect, box2: CGRect) -> Float {
        let intersectionRect = box1.intersection(box2)
        let intersectionArea = intersectionRect.width * intersectionRect.height

        let unionArea = (box1.width * box1.height) + (box2.width * box2.height) - intersectionArea

        if unionArea == 0 { return 0 }
        return Float(intersectionArea / unionArea)
    }
    
    private func removeDuplicatesByDetection(detections: [DetectedObject]) -> [DetectedObject] {
        // 與服務器端一致：使用 Set 來去重，避免重複的食材名稱
        var seenIngredients: Set<String> = []
        var uniqueDetections: [DetectedObject] = []
        
        for detection in detections {
            let mappedName = classMapping[detection.label] ?? detection.label
            if !seenIngredients.contains(mappedName) {
                seenIngredients.insert(mappedName)
                // 創建新的 DetectedObject 使用映射後的名稱
                let mappedDetection = DetectedObject(
                    rect: detection.rect,
                    confidence: detection.confidence,
                    label: mappedName
                )
                uniqueDetections.append(mappedDetection)
            }
        }
        
        return uniqueDetections.sorted { $0.confidence > $1.confidence }
    }
}

struct DetectedObject {
    let rect: CGRect
    let confidence: Float
    let label: String
}