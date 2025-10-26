# Edge-AI 智能廚房助手

**完全離線的 AI 食譜生成器 - 100% 隱私保護**

---

## 🎯 專案特色

✨ **完全離線運作** - 所有 AI 推理都在你的裝置上執行  
🔒 **100% 隱私保護** - 資料永不離開你的裝置  
🤖 **雙 AI 引擎** - YOLOv8n 食材偵測 + Qwen2.5 食譜生成  
📱 **輕量高效** - 總模型大小僅 320MB  

---

## 🚀 功能介紹

### 1. 智能食材偵測
- 拍攝冰箱照片
- AI 自動識別食材
- 支援 15+ 種常見食材

### 2. 個性化食譜生成
- 根據偵測到的食材
- 輸入想吃的料理類型
- AI 即時生成完整食譜

### 3. 三種 AI 模式
- **🤖 完全離線模式**: 模型在裝置上運行
- **🔧 開發者模式**: 連接本地 Ollama 服務
- **🌐 雲端模式**: 連接遠端 API 伺服器

---

## 📱 使用方式

### 基本流程
```
1. 打開 App
2. 前往「Scan Fridge」分頁
3. 拍照或選擇冰箱照片
4. 點擊「Process Image」偵測食材
5. 輸入想吃的料理類型
6. 點擊「Generate Recipe」
7. 查看完整食譜！
```

### 設定 AI 模式
```
1. 前往「Settings」分頁
2. 選擇 AI 處理模式：

選項 A: 完全離線（推薦）
✅ Use Local AI Processing
✅ Use On-Device MLX LLM

選項 B: 雲端模式
❌ Use Local AI Processing
```

---

## 🎮 三種 AI 模式說明

### 🤖 完全離線模式
**最佳隱私保護**

- ✅ 100% 離線運作
- ✅ 資料不離開裝置
- ✅ 無需註冊或登入
- ⏱️ 生成時間：8-15 秒
- 📱 需求：iPhone 12+ 或 M1+ Mac

**適合**: 注重隱私的用戶

---

### 🔧 開發者模式
**快速測試專用**

- ✅ 生成速度快（2-5 秒）
- ✅ 仍然是本地運算
- ⚠️ 需要 Mac 上運行 Ollama
- 💻 僅限 Simulator 使用

**適合**: 開發者測試

---

### 🌐 雲端模式
**通用解決方案**

- ✅ 任何裝置都能使用
- ✅ 無硬體限制
- ⚠️ 需要網際網路連接
- ⚠️ 資料會傳到伺服器

**適合**: 舊裝置或網路穩定環境

---

## 📊 模式對比

| 項目 | 完全離線 | 開發者 | 雲端 |
|------|---------|--------|------|
| **隱私** | 🔒 最高 | 🔒 高 | ⚠️ 低 |
| **速度** | 中等 | 快 | 視網路 |
| **網路** | ❌ 不需要 | ❌ 不需要 | ✅ 需要 |
| **硬體** | iPhone 12+ | 任何 | 任何 |
| **其他用戶** | ✅ 可用 | ❌ 不可用 | ✅ 可用 |

---

## 🛠️ 技術架構

### AI 模型
- **食材偵測**: YOLOv8n (CoreML)
  - 模型大小：44MB
  - 推理時間：< 1 秒
  
- **食譜生成**: Qwen2.5-0.5B (MLX)
  - 模型大小：276MB
  - 推理時間：8-15 秒

### 技術棧
- **前端**: SwiftUI
- **AI 框架**: CoreML + MLX
- **後端**: FastAPI (選用)
- **部署**: iOS 16.0+

---

## 📈 效能表現

### iPhone 14 Pro
```
首次啟動:      15 秒（載入模型）
後續啟動:      < 1 秒
食材偵測:      < 1 秒
食譜生成:      11 秒
記憶體使用:    820 MB
```

### 建議配置
- **開發測試**: 使用開發者模式（快）
- **實機測試**: 使用完全離線模式（準確）
- **發佈版本**: 預設完全離線模式

---

## 🎯 使用場景

### 場景 1: 晚餐不知道吃什麼
```
1. 拍攝冰箱照片
2. AI 偵測：雞肉、洋蔥、紅蘿蔔
3. 輸入：「炒飯」
4. 獲得：黃金雞肉炒飯食譜
```

### 場景 2: 想做特定料理
```
1. 拍攝食材照片
2. AI 偵測：牛肉、馬鈴薯、紅酒
3. 輸入：「燉牛肉」
4. 獲得：紅酒燉牛肉食譜
```

### 場景 3: 飲食限制
```
1. 偵測食材
2. 設定：素食、無麩質
3. 輸入：「義大利麵」
4. 獲得：符合限制的素食義大利麵
```

---

## 📱 系統需求

### 最低需求
- iOS 16.0 或更高
- iPhone 8 或更高（雲端模式）

### 推薦配置
- iOS 17.0 或更高
- iPhone 12 或更高（完全離線模式）
- 500MB 可用空間

---

## 🔐 隱私聲明

### 完全離線模式
- ✅ 所有資料處理都在裝置上
- ✅ 照片不會上傳到任何伺服器
- ✅ 不收集任何個人資訊
- ✅ 不需要註冊或登入

### 雲端模式
- ⚠️ 照片會傳到 API 伺服器
- ⚠️ 伺服器會暫存資料用於處理
- ✅ 處理後立即刪除
- ✅ 不保存個人資訊

**建議**: 使用完全離線模式以獲得最佳隱私保護

---

## 🆕 最新更新

### v1.0.0 (2025-10-21)
- ✨ 新增 MLX on-device LLM 支援
- ✨ 實作三種 AI 模式切換
- ✨ 優化食譜生成品質
- ✨ 改善 UI/UX 體驗
- 🐛 修復記憶體洩漏問題

---

## 🛣️ 未來計劃

### 短期（v1.1）
- [ ] 添加食譜收藏功能
- [ ] 支援更多食材類型
- [ ] 優化生成速度
- [ ] 添加食譜分享

### 長期（v2.0）
- [ ] 支援多語言（英文、中文）
- [ ] 添加營養分析
- [ ] 實作購物清單
- [ ] 支援語音輸入

---

## 🤝 貢獻

歡迎提交 Issue 或 Pull Request！

### 開發環境設置
```bash
# 1. Clone 專案
git clone https://github.com/your-repo/edge-ai-kitchen-assistant.git

# 2. 進入 iOS App 目錄
cd edge-ai-kitchen-assistant/ios-app

# 3. 設置 MLX（自動下載模型）
./setup_mlx.sh

# 4. 打開 Xcode
open KitchenAssistant.xcodeproj

# 5. 添加 MLX Swift 套件
# File → Add Package Dependencies...
# URL: https://github.com/ml-explore/mlx-swift
```

詳細說明請參考：
- `START_HERE.md` - 快速開始
- `MLX_INTEGRATION_GUIDE.md` - 整合指南
- `README_MLX.md` - 完整文檔

---

## 📚 文件索引

### 使用者文件
- **本檔案** - 專案概述（中文）
- `README.md` - 專案概述（英文）

### 開發者文件
- `START_HERE.md` - 快速開始指南
- `QUICK_START.md` - 3 分鐘快速上手
- `MLX_INTEGRATION_GUIDE.md` - MLX 整合指南
- `README_MLX.md` - MLX 完整文檔
- `MLX_INTEGRATION_SUMMARY.md` - 整合完成報告

### 技術文件
- `backend/main.py` - FastAPI 後端
- `local_server.md` - 本地伺服器說明

---

## 📄 授權

MIT License

Copyright (c) 2025 Edge-AI Kitchen Assistant

---

## 📧 聯絡方式

- **GitHub**: [專案連結]
- **Email**: [你的 Email]
- **Issues**: [GitHub Issues]

---

## 🙏 致謝

### AI 模型
- [Ultralytics YOLOv8](https://github.com/ultralytics/ultralytics) - 食材偵測
- [Qwen2.5](https://huggingface.co/Qwen) - 食譜生成

### 框架與工具
- [MLX Swift](https://github.com/ml-explore/mlx-swift) - Apple Silicon AI 框架
- [Apple CoreML](https://developer.apple.com/documentation/coreml) - 機器學習框架
- [FastAPI](https://fastapi.tiangolo.com/) - Python Web 框架

---

## ⭐ Star History

如果這個專案對你有幫助，請給個 Star ⭐️

---

**🎉 享受你的 AI 廚房助手之旅！**

```
完全離線 · 100% 隱私 · 智能食譜
```

