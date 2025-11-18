# Architecture Diagram (Mermaid Format)

## Complete System Architecture with Three Modes

Copy this code to [Mermaid Live Editor](https://mermaid.live/) to generate the diagram:

```mermaid
graph TB
    subgraph iOS["iOS SwiftUI App (iPhone 12+, iOS 16+)"]
        UI[User Interface]
        Settings[Settings Toggles<br/>- Use Local Processing<br/>- Use MLX Generation]
        
        UI --> Settings
        
        Settings --> ServerMode[Server Mode]
        Settings --> LocalMode[Local Mode]
        Settings --> DevMode[Developer Mode]
    end
    
    subgraph Detection["STAGE 1: Detection Layer"]
        AWS["☁️ Server Mode<br/>───────────<br/>AWS EC2 FastAPI<br/>YOLOv8n PyTorch<br/>~500ms-1s"]
        CoreML1["📱 Local Mode<br/>───────────<br/>CoreML YOLO<br/>Neural Engine<br/>~100ms"]
        CoreML2["📱 Developer Mode<br/>───────────<br/>CoreML YOLO<br/>Neural Engine<br/>~100ms"]
    end
    
    subgraph Recipe["STAGE 2: Recipe Generation Layer"]
        MLX1["📱 Server Mode<br/>───────────<br/>MLX LLM<br/>Qwen2.5-0.5B<br/>10-30s<br/>⭐⭐ Good"]
        MLX2["📱 Local Mode<br/>───────────<br/>MLX LLM<br/>Qwen2.5-0.5B<br/>10-30s<br/>⭐⭐ Good"]
        Ollama["🖥️ Developer Mode<br/>───────────<br/>Ollama LLM<br/>Qwen2.5:3b<br/>5-10s<br/>⭐⭐⭐ Excellent"]
    end
    
    subgraph Result["STAGE 3: Recipe Display"]
        Recipe1[Recipe Detail View<br/>Title, Ingredients, Steps]
        Recipe2[Recipe Detail View<br/>Title, Ingredients, Steps]
        Recipe3[Recipe Detail View<br/>Title, Ingredients, Steps]
    end
    
    ServerMode -->|HTTP API| AWS
    LocalMode -->|On-Device| CoreML1
    DevMode -->|On-Device| CoreML2
    
    AWS -->|JSON Response| MLX1
    CoreML1 -->|On-Device| MLX2
    CoreML2 -->|HTTP to Mac| Ollama
    
    MLX1 --> Recipe1
    MLX2 --> Recipe2
    Ollama --> Recipe3
    
    style ServerMode fill:#e1f5ff,stroke:#01579b
    style LocalMode fill:#e8f5e9,stroke:#2e7d32
    style DevMode fill:#fff3e0,stroke:#e65100
    
    style AWS fill:#ffcdd2,stroke:#c62828
    style CoreML1 fill:#c8e6c9,stroke:#388e3c
    style CoreML2 fill:#c8e6c9,stroke:#388e3c
    
    style MLX1 fill:#b3e5fc,stroke:#0277bd
    style MLX2 fill:#b3e5fc,stroke:#0277bd
    style Ollama fill:#ffe0b2,stroke:#f57c00
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
        iOS->>Detection: ☁️ Upload to AWS EC2
        Detection-->>iOS: Ingredients JSON
        Note over iOS,Recipe: STAGE 2: Recipe Generation
        iOS->>Recipe: 📱 MLX on iPhone
        Recipe-->>Display: Recipe JSON
    else Local Mode
        Note over iOS,Detection: STAGE 1: Detection
        User->>iOS: Take Photo
        iOS->>Detection: 📱 CoreML (Neural Engine)
        Detection-->>iOS: Ingredients
        Note over iOS,Recipe: STAGE 2: Recipe Generation
        iOS->>Recipe: 📱 MLX on iPhone
        Recipe-->>Display: Recipe JSON
    else Developer Mode
        Note over iOS,Detection: STAGE 1: Detection
        User->>iOS: Take Photo
        iOS->>Detection: 📱 CoreML (Neural Engine)
        Detection-->>iOS: Ingredients
        Note over iOS,Recipe: STAGE 2: Recipe Generation
        iOS->>Recipe: 🖥️ HTTP to Mac Ollama
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
    
    Decision -->|Server Mode| Upload["☁️ STAGE 1: Server Mode<br/>Upload to AWS<br/>~300KB compressed"]
    Decision -->|Local Mode| CoreML1["📱 STAGE 1: Local Mode<br/>CoreML Input<br/>640x640 RGB"]
    Decision -->|Developer Mode| CoreML2["📱 STAGE 1: Developer Mode<br/>CoreML Input<br/>640x640 RGB"]
    
    Upload --> YOLO1[YOLOv8n PyTorch<br/>Output: Tensor<br/>5 objects detected]
    CoreML1 --> YOLO2[YOLOv8n CoreML<br/>Output: MLMultiArray<br/>5 objects detected]
    CoreML2 --> YOLO3[YOLOv8n CoreML<br/>Output: MLMultiArray<br/>5 objects detected]
    
    YOLO1 --> Ingredients1[Ingredients JSON<br/>~150 bytes]
    YOLO2 --> Ingredients2[Ingredients Array<br/>Swift [String]<br/>5 items]
    YOLO3 --> Ingredients3[Ingredients Array<br/>Swift [String]<br/>5 items]
    
    Ingredients1 --> MLX1["📱 STAGE 2: Server Mode<br/>MLX Inference<br/>Qwen2.5-0.5B<br/>10-30s"]
    Ingredients2 --> MLX2["📱 STAGE 2: Local Mode<br/>MLX Inference<br/>Qwen2.5-0.5B<br/>10-30s"]
    Ingredients3 --> Ollama1["🖥️ STAGE 2: Developer Mode<br/>Ollama Inference<br/>Qwen2.5:3b<br/>5-10s"]
    
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

