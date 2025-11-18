# Architecture Diagram (Mermaid Format)

## Complete System Architecture with Three Modes

Copy this code to [Mermaid Live Editor](https://mermaid.live/) to generate the diagram:

```mermaid
graph TB
    subgraph iOS["iOS KITCHEN ASSISTANT APP (iPhone 12+, iOS 16+)"]
        Workflow["USER WORKFLOW:<br/>Photo → Detect → Input → Recipe"]
        Settings["SETTINGS:<br/>Use Local Processing<br/>Use MLX Generation"]
        
        Workflow --> Settings
        
        Settings --> Mode1[MODE 1<br/>Server Mode]
        Settings --> Mode2[MODE 2<br/>Local Mode]
        Settings --> Mode3[MODE 3<br/>Developer Mode]
    end
    
    subgraph Stage1["STAGE 1: INGREDIENT DETECTION"]
        ServerDetect["☁️ Server Mode<br/>━━━━━━━━━━━━━━━<br/>AWS EC2 Server<br/>FastAPI Backend<br/><br/>Model: YOLOv8n PyTorch<br/>Size: N/A<br/>Need: WiFi<br/>Speed: 0.5-1s<br/>Privacy: Med"]
        
        LocalDetect["📱 Local Mode<br/>━━━━━━━━━━━━━━━<br/>CoreML<br/>Neural Engine<br/><br/>Model: yolov8n.mlmodel<br/>Size: ~6MB<br/>Need: None<br/>Speed: ~100ms<br/>Privacy: High"]
        
        DevDetect["📱 Developer Mode<br/>━━━━━━━━━━━━━━━<br/>CoreML<br/>Neural Engine<br/><br/>Model: yolov8n.mlmodel<br/>Size: ~6MB<br/>Need: None<br/>Speed: ~100ms<br/>Privacy: High"]
    end
    
    subgraph Stage2["STAGE 2: RECIPE GENERATION"]
        ServerRecipe["📱 Server Mode<br/>━━━━━━━━━━━━━━━<br/>iPhone MLX<br/>Model: Qwen2.5-0.5B<br/>4-bit quantized<br/><br/>Size: ~300MB<br/>Params: 500M<br/>Hardware: iPhone GPU<br/>Need: None<br/>Speed: 10-30s<br/>Quality: Good<br/>Privacy: High"]
        
        LocalRecipe["📱 Local Mode<br/>━━━━━━━━━━━━━━━<br/>iPhone MLX<br/>Model: Qwen2.5-0.5B<br/>4-bit quantized<br/><br/>Size: ~300MB<br/>Params: 500M<br/>Hardware: iPhone GPU<br/>Need: None<br/>Speed: 10-30s<br/>Quality: Good<br/>Privacy: High"]
        
        DevRecipe["🖥️ Developer Mode<br/>━━━━━━━━━━━━━━━<br/>Mac Ollama<br/>Model: Qwen2.5:3b<br/>Full model<br/><br/>Size: ~2GB<br/>Params: 3B<br/>Hardware: Mac GPU (M3)<br/>Need: WiFi<br/>Speed: 5-10s<br/>Quality: Excellent<br/>Privacy: High"]
    end
    
    subgraph Stage3["STAGE 3: DISPLAY TO USER"]
        Display["Recipe Detail View<br/>━━━━━━━━━━━━━━━<br/>Chicken Tomato Pasta<br/>25 min | 4 servings<br/><br/>INGREDIENTS (8)<br/>STEPS (6)<br/>NUTRITION"]
    end
    
    Mode1 --> ServerDetect
    Mode2 --> LocalDetect
    Mode3 --> DevDetect
    
    ServerDetect -->|Detected<br/>Ingredients| ServerRecipe
    LocalDetect -->|Detected<br/>Ingredients| LocalRecipe
    DevDetect -->|Detected<br/>Ingredients| DevRecipe
    
    ServerRecipe -->|Recipe JSON| Display
    LocalRecipe -->|Recipe JSON| Display
    DevRecipe -->|Recipe JSON| Display
    
    style Mode1 fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    style Mode2 fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style Mode3 fill:#fff3e0,stroke:#e65100,stroke-width:2px
    
    style ServerDetect fill:#ffcdd2,stroke:#c62828,stroke-width:2px
    style LocalDetect fill:#c8e6c9,stroke:#388e3c,stroke-width:2px
    style DevDetect fill:#c8e6c9,stroke:#388e3c,stroke-width:2px
    
    style ServerRecipe fill:#b3e5fc,stroke:#0277bd,stroke-width:2px
    style LocalRecipe fill:#b3e5fc,stroke:#0277bd,stroke-width:2px
    style DevRecipe fill:#ffe0b2,stroke:#f57c00,stroke-width:2px
    
    style Display fill:#f3e5f5,stroke:#7b1fa2,stroke-width:3px
```

---

## Detailed Flow Diagram

```mermaid
sequenceDiagram
    participant User
    participant iOS as iOS App
    participant Settings
    participant Detection
    participant Recipe as Recipe Gen
    participant Display

    User->>iOS: Open App
    iOS->>Settings: Check Mode Settings
    
    alt Server Mode
        Note over iOS,Detection: STAGE 1: Detection
        User->>iOS: Take Photo
        iOS->>Detection: Upload to AWS EC2
        Detection-->>iOS: Ingredients JSON
        Note over iOS,Recipe: STAGE 2: Recipe Generation
        iOS->>Recipe: MLX on iPhone
        Recipe-->>Display: Recipe JSON
    else Local Mode
        Note over iOS,Detection: STAGE 1: Detection
        User->>iOS: Take Photo
        iOS->>Detection: CoreML (Neural Engine)
        Detection-->>iOS: Ingredients
        Note over iOS,Recipe: STAGE 2: Recipe Generation
        iOS->>Recipe: MLX on iPhone
        Recipe-->>Display: Recipe JSON
    else Developer Mode
        Note over iOS,Detection: STAGE 1: Detection
        User->>iOS: Take Photo
        iOS->>Detection: CoreML (Neural Engine)
        Detection-->>iOS: Ingredients
        Note over iOS,Recipe: STAGE 2: Recipe Generation
        iOS->>Recipe: HTTP to Mac Ollama
        Recipe-->>Display: Recipe JSON
    end
    
    Note over Display,User: STAGE 3: Display
    Display->>User: Show Recipe
```

---

## Component Architecture

```mermaid
graph LR
    subgraph App["iOS Application"]
        Views[SwiftUI Views]
        VM[ViewModels]
        Services[Services]
        Models[Data Models]
        
        Views --> VM
        VM --> Services
        Services --> Models
    end
    
    subgraph Services["Service Layer"]
        API[APIClient<br/>Server Mode]
        Local[LocalInferenceService<br/>CoreML]
        MLXGen[MLXRecipeGenerator<br/>MLX LLM]
        OllamaGen[LocalLLMRecipeGenerator<br/>Ollama]
    end
    
    subgraph External["External Services"]
        EC2[AWS EC2<br/>FastAPI Backend]
        Mac[Mac Ollama<br/>Qwen2.5:3b]
    end
    
    API -->|HTTP| EC2
    OllamaGen -->|HTTP| Mac
    
    style Views fill:#e3f2fd
    style VM fill:#bbdefb
    style Services fill:#90caf9
    style Models fill:#64b5f6
    
    style API fill:#ffcdd2
    style Local fill:#c8e6c9
    style MLXGen fill:#b3e5fc
    style OllamaGen fill:#ffe0b2
```

---

## Data Flow with Sizes

```mermaid
graph TD
    Photo[User Photo<br/>UIImage<br/>~2MB JPEG]
    
    Photo --> Decision{Mode?}
    
    Decision -->|Server Mode| Upload["STAGE 1: Server Mode<br/>Upload to AWS<br/>~300KB compressed"]
    Decision -->|Local Mode| CoreML1["STAGE 1: Local Mode<br/>CoreML Input<br/>640x640 RGB"]
    Decision -->|Developer Mode| CoreML2["STAGE 1: Developer Mode<br/>CoreML Input<br/>640x640 RGB"]
    
    Upload --> YOLO1[YOLOv8n PyTorch<br/>Output: Tensor<br/>5 objects detected]
    CoreML1 --> YOLO2[YOLOv8n CoreML<br/>Output: MLMultiArray<br/>5 objects detected]
    CoreML2 --> YOLO3[YOLOv8n CoreML<br/>Output: MLMultiArray<br/>5 objects detected]
    
    YOLO1 --> Ingredients1[Ingredients JSON<br/>~150 bytes]
    YOLO2 --> Ingredients2[Ingredients Array<br/>Swift String<br/>5 items]
    YOLO3 --> Ingredients3[Ingredients Array<br/>Swift String<br/>5 items]
    
    Ingredients1 --> MLX1["STAGE 2: Server Mode<br/>MLX Inference<br/>Qwen2.5-0.5B<br/>10-30s"]
    Ingredients2 --> MLX2["STAGE 2: Local Mode<br/>MLX Inference<br/>Qwen2.5-0.5B<br/>10-30s"]
    Ingredients3 --> Ollama1["STAGE 2: Developer Mode<br/>Ollama Inference<br/>Qwen2.5:3b<br/>5-10s"]
    
    MLX1 --> RecipeJSON1[Recipe JSON<br/>~3-5KB<br/>snake_case]
    MLX2 --> RecipeJSON2[Recipe JSON<br/>~3-5KB<br/>snake_case]
    Ollama1 --> RecipeJSON3[Recipe JSON<br/>~3-5KB<br/>snake_case]
    
    RecipeJSON1 --> Parse1[JSONDecoder<br/>Convert to Swift]
    RecipeJSON2 --> Parse2[JSONDecoder<br/>Convert to Swift]
    RecipeJSON3 --> Parse3[JSONDecoder<br/>Convert to Swift]
    
    Parse1 --> Display1[SwiftUI Display]
    Parse2 --> Display2[SwiftUI Display]
    Parse3 --> Display3[SwiftUI Display]
    
    style Photo fill:#e1f5fe
    style Upload fill:#ffcdd2
    style CoreML1 fill:#c8e6c9
    style CoreML2 fill:#c8e6c9
    style MLX1 fill:#b3e5fc
    style MLX2 fill:#b3e5fc
    style Ollama1 fill:#ffe0b2
```

---

## Hardware Utilization

```mermaid
graph TB
    subgraph iPhone["iPhone 12+ (iOS 16+)"]
        CPU[CPU<br/>A14+ Bionic]
        NE[Neural Engine<br/>16-core]
        GPU[GPU<br/>Apple-designed]
        RAM[RAM<br/>4-6GB]
        
        CoreMLService[CoreML YOLO] --> NE
        MLXService[MLX LLM] --> GPU
        MLXService --> RAM
        App[App Logic] --> CPU
    end
    
    subgraph Server["AWS EC2 t2.micro"]
        SCPU[CPU<br/>1 vCPU]
        SRAM[RAM<br/>1GB]
        
        FastAPI[FastAPI Backend] --> SCPU
        YOLOServer[YOLOv8n Model] --> SCPU
        YOLOServer --> SRAM
    end
    
    subgraph Mac["MacBook (M1/M2/M3)"]
        MCPU[CPU<br/>8-10 cores]
        MGPU[GPU<br/>8-10 cores]
        MRAM[RAM<br/>16GB unified]
        
        OllamaService[Ollama Service] --> MGPU
        OllamaService --> MRAM
        Qwen[Qwen2.5:3b Model] --> MGPU
    end
    
    App -.->|HTTP| FastAPI
    App -.->|HTTP| OllamaService
    
    style NE fill:#4caf50
    style GPU fill:#2196f3
    style MGPU fill:#ff9800
```

---

## Performance Comparison

```mermaid
graph LR
    subgraph Metrics["Performance Metrics"]
        Detection[Detection Speed]
        Generation[Recipe Generation]
        Quality[Recipe Quality]
        Privacy[Privacy Level]
    end
    
    Detection --> D1[Server: 500ms-1s]
    Detection --> D2[Local: ~100ms]
    Detection --> D3[Dev: ~100ms]
    
    Generation --> G1[Server: 10-30s<br/>0.5B model]
    Generation --> G2[Local: 10-30s<br/>0.5B model]
    Generation --> G3[Dev: 5-10s<br/>3B model]
    
    Quality --> Q1[Server: Good<br/>Limited params]
    Quality --> Q2[Local: Good<br/>Limited params]
    Quality --> Q3[Dev: Excellent<br/>6x more params]
    
    Privacy --> P1[Server: Partial<br/>Detection to cloud]
    Privacy --> P2[Local: 100%<br/>All on-device]
    Privacy --> P3[Dev: 100%<br/>Local network only]
    
    style D2 fill:#c8e6c9
    style D3 fill:#c8e6c9
    style G3 fill:#ffe0b2
    style Q3 fill:#ffe0b2
    style P2 fill:#c8e6c9
    style P3 fill:#c8e6c9
```

---

## Instructions to Generate Diagrams

1. **Copy any of the Mermaid code blocks above**
2. **Go to**: https://mermaid.live/
3. **Paste the code** into the editor
4. **Export options**:
   - PNG (recommended for README)
   - SVG (recommended for high-quality)
   - PDF (for documentation)

Or use VS Code with Mermaid extension:
```bash
# Install Mermaid extension
code --install-extension bierner.markdown-mermaid
```

Or render in GitHub README (GitHub supports Mermaid natively):
````markdown
```mermaid
graph TB
    A[iOS App] --> B[Detection]
    B --> C[Recipe]
```
````

