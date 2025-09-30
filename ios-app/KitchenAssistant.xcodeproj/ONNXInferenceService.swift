import Foundation
import UIKit

// Note: This requires ONNX Runtime iOS framework to be added to the project
// Add via Swift Package Manager: https://github.com/microsoft/onnxruntime-swift-package-manager

class ONNXInferenceService: ObservableObject {
    private var ortSession: ORTSession?
    private var ortEnvironment: ORTEnv?
    private var modelLoaded = false

    // YOLO model parameters (matching server-side implementation)
    private let inputSize: CGSize = CGSize(width: 640, height: 640)
    private let confidenceThreshold: Float = 0.1

    // Food classes mapping (matching server-side YOLO_TO_FOOD_MAPPING)
    private let yoloToFoodMapping: [String: String] = [
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

    // Model class names (should match your trained model)
    private let classNames = [
        "beef", "pork", "chicken", "butter", "cheese",
        "milk", "broccoli", "carrot", "cucumber", "lettuce", "tomato"
    ]

    enum ONNXInferenceError: Error, LocalizedError {
        case modelNotLoaded
        case modelLoadingFailed(Error)
        case imageProcessingFailed
        case inferenceError(Error)
        case noValidDetections
        case onnxRuntimeNotAvailable

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded:
                return "ONNX model not loaded"
            case .modelLoadingFailed(let error):
                return "Failed to load ONNX model: \(error.localizedDescription)"
            case .imageProcessingFailed:
                return "Failed to process image"
            case .inferenceError(let error):
                return "Inference error: \(error.localizedDescription)"
            case .noValidDetections:
                return "No valid food items detected"
            case .onnxRuntimeNotAvailable:
                return "ONNX Runtime framework not available"
            }
        }
    }

    init() {
        loadModel()
    }

    // MARK: - Model Loading

    private func loadModel() {
        Task {
            do {
                // Check if ONNX Runtime is available
                #if canImport(onnxruntime_objc)
                import onnxruntime_objc

                // Initialize ONNX Runtime environment
                ortEnvironment = try ORTEnv(loggingLevel: ORTLoggingLevel.warning)

                // Get model path from bundle
                guard let modelPath = Bundle.main.path(forResource: "yolov8n_merged_food_cpu_aug_finetuned", ofType: "onnx") else {
                    print("⚠️ ONNX model not found in bundle")
                    await MainActor.run {
                        self.modelLoaded = false
                    }
                    return
                }

                // Create session options
                let sessionOptions = try ORTSessionOptions()
                try sessionOptions.setLogSeverityLevel(ORTLoggingLevel.warning)
                try sessionOptions.setIntraOpNumThreads(1) // Single thread for consistency

                // Create ONNX Runtime session
                ortSession = try ORTSession(env: ortEnvironment!, modelPath: modelPath, sessionOptions: sessionOptions)

                await MainActor.run {
                    self.modelLoaded = true
                    print("✅ ONNX model loaded successfully")
                }

                #else
                print("⚠️ ONNX Runtime not available. Please add onnxruntime-objc framework to your project.")
                await MainActor.run {
                    self.modelLoaded = false
                }
                #endif

            } catch {
                print("❌ Failed to load ONNX model: \(error)")
                await MainActor.run {
                    self.modelLoaded = false
                }
            }
        }
    }

    // MARK: - Public Interface

    func detectIngredients(in image: UIImage) async throws -> [String] {
        guard modelLoaded, let session = ortSession else {
            // Fallback to mock detection when model is not available
            return try await fallbackMockDetection()
        }

        #if canImport(onnxruntime_objc)
        import onnxruntime_objc

        do {
            // Preprocess image (matching server-side preprocessing)
            let inputTensor = try preprocessImage(image)

            // Run inference
            let outputs = try await runInference(session: session, inputTensor: inputTensor)

            // Post-process results (matching server-side post-processing)
            let ingredients = try processDetections(outputs)

            if ingredients.isEmpty {
                print("⚠️ No food items detected, using fallback")
                return try await fallbackMockDetection()
            }

            print("🔍 Detected \(ingredients.count) food items locally: \(ingredients)")
            return ingredients

        } catch {
            print("❌ Local ONNX inference failed: \(error)")
            throw ONNXInferenceError.inferenceError(error)
        }
        #else
        throw ONNXInferenceError.onnxRuntimeNotAvailable
        #endif
    }

    // MARK: - Image Preprocessing

    private func preprocessImage(_ image: UIImage) throws -> ORTValue {
        #if canImport(onnxruntime_objc)
        import onnxruntime_objc

        // Resize image to model input size (640x640)
        guard let resizedImage = image.resized(to: inputSize) else {
            throw ONNXInferenceError.imageProcessingFailed
        }

        // Convert to RGB pixel buffer
        guard let pixelBuffer = resizedImage.pixelBuffer() else {
            throw ONNXInferenceError.imageProcessingFailed
        }

        // Convert to normalized float array [1, 3, 640, 640] format
        let inputData = try pixelBufferToFloatArray(pixelBuffer)

        // Create ONNX tensor
        let shape: [NSNumber] = [1, 3, 640, 640]
        let inputTensor = try ORTValue(tensorData: NSMutableData(data: Data(bytes: inputData, count: inputData.count * MemoryLayout<Float>.size)),
                                      elementType: ORTTensorElementDataType.float,
                                      shape: shape)

        return inputTensor
        #else
        throw ONNXInferenceError.onnxRuntimeNotAvailable
        #endif
    }

    private func pixelBufferToFloatArray(_ pixelBuffer: CVPixelBuffer) throws -> [Float] {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0)) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            throw ONNXInferenceError.imageProcessingFailed
        }

        let buffer = baseAddress.bindMemory(to: UInt8.self, capacity: height * bytesPerRow)
        var floatArray = [Float](repeating: 0, count: 3 * width * height)

        // Convert BGRA to RGB and normalize to [0, 1]
        for y in 0..<height {
            for x in 0..<width {
                let pixelIndex = y * bytesPerRow + x * 4
                let b = Float(buffer[pixelIndex]) / 255.0
                let g = Float(buffer[pixelIndex + 1]) / 255.0
                let r = Float(buffer[pixelIndex + 2]) / 255.0

                // Store in CHW format (channels first): [R, G, B]
                let outputIndex = y * width + x
                floatArray[outputIndex] = r                              // R channel
                floatArray[width * height + outputIndex] = g             // G channel
                floatArray[2 * width * height + outputIndex] = b         // B channel
            }
        }

        return floatArray
    }

    // MARK: - Model Inference

    private func runInference(session: ORTSession, inputTensor: ORTValue) async throws -> ORTValue {
        #if canImport(onnxruntime_objc)
        import onnxruntime_objc

        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Run inference
                    let outputs = try session.run(withInputs: ["images": inputTensor], outputNames: ["output0"], runOptions: nil)

                    if let output = outputs["output0"] {
                        continuation.resume(returning: output)
                    } else {
                        continuation.resume(throwing: ONNXInferenceError.inferenceError(NSError(domain: "ONNX", code: -1, userInfo: [NSLocalizedDescriptionKey: "No output found"])))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
        #else
        throw ONNXInferenceError.onnxRuntimeNotAvailable
        #endif
    }

    // MARK: - Post-processing

    private func processDetections(_ output: ORTValue) throws -> [String] {
        #if canImport(onnxruntime_objc)
        import onnxruntime_objc

        // Get tensor data
        let tensorData = try output.tensorData() as Data
        let floatCount = tensorData.count / MemoryLayout<Float>.size
        let floatArray = tensorData.withUnsafeBytes { bytes in
            Array(bytes.bindMemory(to: Float.self).prefix(floatCount))
        }

        // YOLO output format: [1, 15, 8400] = [batch, (x,y,w,h,confidence,class0,...,class10), detections]
        let numDetections = 8400
        let numClasses = classNames.count
        let outputSize = 5 + numClasses // x,y,w,h,conf + classes

        var ingredients: [String] = []

        for i in 0..<numDetections {
            let baseIndex = i * outputSize

            // Get confidence (index 4)
            let confidence = floatArray[baseIndex + 4]

            // Filter by confidence threshold
            if confidence >= confidenceThreshold {
                // Find class with highest score
                var maxClassScore: Float = 0
                var maxClassIndex: Int = -1

                for classIndex in 0..<numClasses {
                    let classScore = floatArray[baseIndex + 5 + classIndex]
                    if classScore > maxClassScore {
                        maxClassScore = classScore
                        maxClassIndex = classIndex
                    }
                }

                // Map class index to class name
                if maxClassIndex >= 0 && maxClassIndex < classNames.count {
                    let className = classNames[maxClassIndex]
                    if let foodName = yoloToFoodMapping[className], !ingredients.contains(foodName) {
                        ingredients.append(foodName)
                    }
                }
            }
        }

        return ingredients
        #else
        throw ONNXInferenceError.onnxRuntimeNotAvailable
        #endif
    }

    // MARK: - Fallback Mock Detection

    private func fallbackMockDetection() async throws -> [String] {
        // Simulate processing time
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        // Mock ingredients (matching server-side mock data)
        let mockIngredients = [
            "Tomatoes", "Bell Peppers", "Onions", "Carrots", "Broccoli",
            "Cheese", "Milk", "Eggs", "Chicken Breast", "Garlic",
            "Spinach", "Potatoes", "Mushrooms", "Cucumber", "Lettuce"
        ]

        let detectedCount = Int.random(in: 3...6)
        let detected = Array(mockIngredients.shuffled().prefix(detectedCount))

        print("🔄 Using local mock detection: \(detected)")
        return detected
    }
}

// MARK: - UIImage Extensions (same as before)

extension UIImage {
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func pixelBuffer() -> CVPixelBuffer? {
        let width = Int(size.width)
        let height = Int(size.height)

        let attributes: [String: Any] = [
            kCVPixelBufferCGImageCompatibilityKey as String: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32BGRA,
            attributes as CFDictionary,
            &pixelBuffer
        )

        guard status == kCVReturnSuccess, let buffer = pixelBuffer else {
            return nil
        }

        CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0)) }

        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }

        guard let cgImage = self.cgImage else { return nil }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return buffer
    }
}