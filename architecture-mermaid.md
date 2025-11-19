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

## Data Flow with Sizes (Horizontal Layout)

```mermaid
graph LR
    Photo[User Photo<br/>UIImage<br/>~2MB JPEG]
    
    Photo --> Decision{Mode?}
    
    Decision -->|Server Mode| Upload["STAGE 1: Server<br/>Upload to AWS<br/>~300KB"]
    Decision -->|Local Mode| CoreML1["STAGE 1: Local<br/>CoreML Input<br/>640x640"]
    Decision -->|Developer Mode| CoreML2["STAGE 1: Developer<br/>CoreML Input<br/>640x640"]
    
    Upload --> YOLO1[YOLOv8n PyTorch<br/>Tensor Output<br/>5 objects]
    CoreML1 --> YOLO2[YOLOv8n CoreML<br/>MLMultiArray<br/>5 objects]
    CoreML2 --> YOLO3[YOLOv8n CoreML<br/>MLMultiArray<br/>5 objects]
    
    YOLO1 --> Ingredients1[Ingredients JSON<br/>~150 bytes]
    YOLO2 --> Ingredients2[Ingredients Array<br/>5 items]
    YOLO3 --> Ingredients3[Ingredients Array<br/>5 items]
    
    Ingredients1 --> MLX1["STAGE 2: Server<br/>MLX 0.5B<br/>10-30s"]
    Ingredients2 --> MLX2["STAGE 2: Local<br/>MLX 0.5B<br/>10-30s"]
    Ingredients3 --> Ollama1["STAGE 2: Developer<br/>Ollama 3B<br/>5-10s"]
    
    MLX1 --> RecipeJSON1[Recipe JSON<br/>~3-5KB]
    MLX2 --> RecipeJSON2[Recipe JSON<br/>~3-5KB]
    Ollama1 --> RecipeJSON3[Recipe JSON<br/>~3-5KB]
    
    RecipeJSON1 --> Parse1[JSONDecoder]
    RecipeJSON2 --> Parse2[JSONDecoder]
    RecipeJSON3 --> Parse3[JSONDecoder]
    
    Parse1 --> Display[SwiftUI Display]
    Parse2 --> Display
    Parse3 --> Display
    
    style Photo fill:#e1f5fe
    style Upload fill:#ffcdd2
    style CoreML1 fill:#c8e6c9
    style CoreML2 fill:#c8e6c9
    style MLX1 fill:#b3e5fc
    style MLX2 fill:#b3e5fc
    style Ollama1 fill:#ffe0b2
    style Display fill:#f3e5f5
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

## CI/CD Integration

### Backend CI/CD Pipeline

```mermaid
graph LR
    A[GitHub Push] --> B[GitHub Actions]
    B --> C[pytest<br/>Unit + API Tests]
    C --> D{Tests Pass?}
    D -->|Yes| E[Docker Build<br/>PyTorch CPU]
    D -->|No| F[❌ Pipeline Failed]
    E --> G[Push to<br/>Docker Hub]
    G --> H[Deploy to<br/>AWS EC2]
    H --> I[Pull Image<br/>on EC2]
    I --> J[Docker Run<br/>Port 8000]
    J --> K[Health Check<br/>/health endpoint]
    K --> L{Health OK?}
    L -->|Yes| M[✅ Deployment<br/>Success]
    L -->|No| N[❌ Deployment<br/>Failed]
    
    style A fill:#e3f2fd
    style B fill:#bbdefb
    style C fill:#90caf9
    style E fill:#64b5f6
    style G fill:#42a5f5
    style H fill:#2196f3
    style I fill:#1e88e5
    style J fill:#1976d2
    style K fill:#1565c0
    style M fill:#c8e6c9
    style F fill:#ffcdd2
    style N fill:#ffcdd2
```

### iOS CI/CD Pipeline

```mermaid
graph LR
    A[GitHub Push] --> B[GitHub Actions]
    B --> C[xcodebuild<br/>Build App]
    C --> D{Build Success?}
    D -->|Yes| E[XCTest<br/>Unit Tests]
    D -->|No| F[❌ Build Failed]
    E --> G{Tests Pass?}
    G -->|Yes| H[XCUITest<br/>UI Tests]
    G -->|No| I[❌ Tests Failed]
    H --> J{UI Tests Pass?}
    J -->|Yes| K[Archive Build]
    J -->|No| L[❌ UI Tests Failed]
    K --> M{Deploy?}
    M -->|Yes| N[Upload to<br/>TestFlight]
    M -->|No| O[✅ CI Complete]
    N --> P[✅ Deployment<br/>Complete]
    
    style A fill:#e8f5e9
    style B fill:#c8e6c9
    style C fill:#a5d6a7
    style E fill:#81c784
    style H fill:#66bb6a
    style K fill:#4caf50
    style N fill:#43a047
    style O fill:#c8e6c9
    style P fill:#c8e6c9
    style F fill:#ffcdd2
    style I fill:#ffcdd2
    style L fill:#ffcdd2
```

### CI/CD Workflow Comparison

```mermaid
graph TB
    subgraph Backend["Backend Pipeline (Server Mode)"]
        B1[Code Push] --> B2[Automated Tests]
        B2 --> B3[Docker Build]
        B3 --> B4[Push to Registry]
        B4 --> B5[Auto Deploy EC2]
        B5 --> B6[Health Check]
    end
    
    subgraph iOS["iOS Pipeline"]
        I1[Code Push] --> I2[Build App]
        I2 --> I3[Unit Tests]
        I3 --> I4[UI Tests]
        I4 --> I5[Optional: TestFlight]
    end
    
    Trigger[Git Push to Main] --> B1
    Trigger --> I1
    
    style Trigger fill:#fff3e0
    style Backend fill:#e3f2fd
    style iOS fill:#e8f5e9
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

