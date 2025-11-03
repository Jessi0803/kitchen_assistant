# AWS EC2 Deployment Guide

**Kitchen Assistant Backend - YOLO Detection Service**

Complete guide for deploying the YOLO ingredient detection service to AWS EC2 Free Tier.

---

## 📋 Table of Contents

1. [System Architecture](#system-architecture)
2. [Deployment Steps](#deployment-steps)
3. [Troubleshooting](#troubleshooting)
4. [Cost Analysis](#cost-analysis)

---

## 🏗️ System Architecture

### Three Operating Modes

#### 1. ☁️ Cloud Mode (Recommended - Real Device)

```
┌─────────────┐      HTTP      ┌──────────────┐
│   iPhone    │───────────────>│  AWS EC2     │
│             │<───────────────│  YOLO CPU    │
│  Detection: │   Ingredients  │  Port 8000   │
│  AWS Server │                └──────────────┘
│             │
│ Generation: │   ┌──────────────────┐
│ MLX On-device│──>│ Qwen2.5-0.5B-4bit│
└─────────────┘   └──────────────────┘
```

- **Detection:** AWS EC2 YOLOv8n (CPU inference)
- **Generation:** On-device MLX LLM
- **Settings:** Turn OFF "Use Local AI Processing"
- **Benefits:** Hybrid architecture, cost-effective

#### 2. 📱 Offline Mode (Recommended - Real Device)

```
┌─────────────┐
│   iPhone    │
│ Detection:  │──> CoreML YOLOv8n
│ Generation: │──> MLX LLM (Qwen2.5-0.5B)
└─────────────┘
```

- **Settings:** Turn ON both toggles
- **Benefits:** 100% offline, complete privacy

#### 3. 🔧 Developer Mode

```
┌─────────────┐      HTTP      ┌──────────────┐
│   iPhone    │───────────────>│  Mac Server  │
│ Detection:  │<───────────────│  Ollama      │
│ CoreML      │   Recipe       │  Port 11434  │
│ Generation: │                └──────────────┘
│ Ollama API  │
└─────────────┘
```

- **Settings:** Turn ON "Use Local AI Processing", OFF "Use On-Device MLX LLM"
- **Benefits:** Fast generation for development

---

## 🚀 Deployment Steps

### Prerequisites

- AWS Account (Free Tier)
- EC2 Instance: t3.micro (2 vCPU, 904MB RAM, 8GB disk)
- OS: Amazon Linux 2023
- Region: us-east-2 (Ohio)
- IP: `18.188.20.164` (example)

### Step 1: Connect to EC2

```bash
# Set permissions for SSH key
chmod 400 awss.pem

# SSH to EC2
ssh -i awss.pem ec2-user@18.188.20.164
```

### Step 2: Install Docker

```bash
# Update packages
sudo yum update -y

# Install Docker
sudo yum install docker -y

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add user to docker group
sudo usermod -aG docker ec2-user

# Re-login for permissions to take effect
exit
ssh -i awss.pem ec2-user@18.188.20.164

# Verify
docker --version
```

### Step 3: Configure Swap (Fix Memory Issues)

```bash
# Create 1GB swap file
sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Verify
free -h
```

**Why?** t3.micro only has 904MB RAM. Swap provides virtual memory for Docker builds.

### Step 4: Upload Files to EC2

**From local Mac:**

```bash
# Upload files
scp -i awss.pem \
    backend/Dockerfile-cpu \
    backend/main-docker.py \
    backend/requirements-docker-cpu.txt \
    backend/best.pt \
    ec2-user@18.188.20.164:~/backend/
```

### Step 5: Build Docker Image

```bash
# SSH to EC2
ssh -i awss.pem ec2-user@18.188.20.164
cd ~/backend

# Build image (5-10 minutes)
docker build -f Dockerfile-cpu -t kitchen-assistant-backend .

# Verify
docker images | grep kitchen
```

### Step 6: Start Container

```bash
# Run container
docker run -d \
  -p 8000:8000 \
  --name kitchen-backend \
  --restart unless-stopped \
  kitchen-assistant-backend

# Check status
docker ps

# View logs
docker logs kitchen-backend
```

**Expected output:**
```
✅ YOLO model loaded successfully
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Step 7: Configure Security Group

**AWS Console:**

1. EC2 Dashboard → Instances
2. Select instance → Security tab
3. Click Security groups link
4. Edit inbound rules → Add rule:
   - Type: Custom TCP
   - Port: 8000
   - Source: 0.0.0.0/0
   - Description: Kitchen Assistant API
5. Save rules

### Step 8: Test API

```bash
# From EC2 (internal)
curl http://localhost:8000/health

# From Mac (external)
curl http://18.188.20.164:8000/health
```

**Expected:**
```json
{
  "status": "healthy",
  "timestamp": 1762201737.406632,
  "yolo_model_loaded": true
}
```

### Step 9: Update iOS App

#### APIClient.swift

```swift
class APIClient: ObservableObject {
    private struct ServerConfig {
        static let awsEC2 = "http://18.188.20.164:8000"
        static let localMac = "http://192.168.86.27:8000"
        static let localhost = "http://127.0.0.1:8000"
    }

    private let baseURL: String = {
        #if targetEnvironment(simulator)
        return ServerConfig.localhost
        #else
        return ServerConfig.awsEC2  // Real device uses AWS
        #endif
    }()
}
```

#### Info.plist (Add ATS Exception)

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>18.188.20.164</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
        </dict>
    </dict>
</dict>
```

---

## 🐛 Troubleshooting

### Issue 1: Package Not Found

**Error:**
```
E: Package 'libgl1-mesa-glx' has no installation candidate
```

**Fix:** Change `Dockerfile-cpu` line 17:
```dockerfile
# Before
libgl1-mesa-glx

# After
libgl1
```

### Issue 2: Out of Memory During Build

**Error:**
```
Killed
```

**Fix:** Create swap (see Step 3)

### Issue 3: Disk Space Full

**Error:**
```
No space left on device
```

**Fix:**
```bash
# Clean Docker cache
docker system prune -af

# Clean system temp
sudo rm -rf /tmp/*

# Check disk usage
df -h
```

### Issue 4: iOS App Transport Security

**Error:**
```
App Transport Security policy requires secure connection
```

**Fix:** Add ATS exception in Info.plist (see Step 9)

### Issue 5: NumPy Incompatibility

**Error:**
```
RuntimeError: module compiled against NumPy 1.x cannot run in NumPy 2.x
```

**Fix:** Add to `requirements-docker-cpu.txt`:
```txt
numpy<2.0
```

Then rebuild:
```bash
# Upload fixed file
scp -i awss.pem backend/requirements-docker-cpu.txt ec2-user@18.188.20.164:~/backend/

# Rebuild on EC2
docker stop kitchen-backend
docker rm kitchen-backend
docker rmi kitchen-assistant-backend
docker build -f Dockerfile-cpu -t kitchen-assistant-backend .
docker run -d -p 8000:8000 --name kitchen-backend --restart unless-stopped kitchen-assistant-backend
```

### Issue 6: Connection Timeout

**Error:**
```
curl: (7) Failed to connect to 18.188.20.164 port 8000
```

**Fix:** Configure Security Group (see Step 7)

---

## 💰 Cost Analysis

### AWS Free Tier (12 months)

| Resource | Free Tier | Usage | Cost |
|----------|-----------|-------|------|
| EC2 t3.micro | 750 hrs/month | 720 hrs/month | $0 |
| Data Transfer | 100GB/month | <1GB/month | $0 |
| EBS Storage | 30GB | 8GB | $0 |
| **Monthly Total** | - | - | **$0** |

### After Free Tier

| Item | Price | Monthly Cost |
|------|-------|--------------|
| t3.micro | $0.0104/hr | ~$7.49 |
| EBS 8GB | $0.10/GB | $0.80 |
| Data Transfer | $0.09/GB | ~$0.09 |
| **Total** | - | **~$8.38/month** |

### vs GPU Solution

| Solution | Instance | Cost/Month | Performance |
|----------|----------|------------|-------------|
| **Current (CPU)** | t3.micro | $0 (Free Tier) | YOLO: 2s |
| GPU | g4dn.xlarge | ~$440 | YOLO: 0.1s |

**Savings:** $440/month = $5,280/year 🎉

---

## 🔧 Maintenance

### Common Commands

```bash
# SSH to EC2
ssh -i awss.pem ec2-user@18.188.20.164

# View container status
docker ps

# View logs (real-time)
docker logs -f kitchen-backend

# Restart container
docker restart kitchen-backend

# Check disk space
df -h

# Check memory
free -h
```

### Update Deployment

```bash
# 1. Stop container
docker stop kitchen-backend
docker rm kitchen-backend

# 2. Upload new code
scp -i awss.pem backend/main-docker.py ec2-user@18.188.20.164:~/backend/

# 3. Rebuild
docker rmi kitchen-assistant-backend
docker build -f Dockerfile-cpu -t kitchen-assistant-backend .

# 4. Start
docker run -d -p 8000:8000 --name kitchen-backend --restart unless-stopped kitchen-assistant-backend
```

---

## 📄 Key Files

```
backend/
├── Dockerfile-cpu              # CPU-optimized Dockerfile
├── main-docker.py              # Backend (YOLO only)
├── requirements-docker-cpu.txt # Python dependencies
└── best.pt                     # YOLO model

ios-app/
├── Services/APIClient.swift    # API client
└── Info.plist                  # iOS config (ATS)

awss.pem                        # AWS SSH key (DO NOT COMMIT)
```

---

## ✅ Verification

### Test Cloud Mode (iOS App)

1. Settings → Turn OFF "Use Local AI Processing"
2. Scan Fridge → Take photo
3. Check Xcode console:
```
🌐 Using server processing
🌐🤖 Cloud mode: Using MLX on-device for recipe generation
```

### Performance Metrics

| Mode | Detection | Generation | Total | Network |
|------|-----------|------------|-------|---------|
| Cloud | ~2.0s (AWS) | ~45s (MLX) | ~47s | Required |
| Offline | ~0.5s (CoreML) | ~45s (MLX) | ~45.5s | Not Required |
| Developer | ~0.5s (CoreML) | ~8s (Ollama) | ~8.5s | Required |

---

## 📚 Quick Reference

### Problem → Solution

| Problem | Quick Fix |
|---------|-----------|
| API not responding | Check Security Group port 8000 |
| Out of memory | Create 1GB swap |
| Disk full | `docker system prune -af` |
| NumPy error | Add `numpy<2.0` to requirements |
| iOS can't connect | Add ATS exception in Info.plist |
| Container crashed | `docker restart kitchen-backend` |

### Essential Commands

```bash
# Docker
docker ps                    # List containers
docker logs -f name          # View logs
docker restart name          # Restart container
docker system prune -af      # Clean all

# System
df -h                        # Disk usage
free -h                      # Memory usage
top                          # Process monitor

# AWS
ssh -i key.pem ec2-user@IP   # Connect
scp -i key.pem file IP:path  # Upload file
```

---

## 🎯 Summary

**What We Built:**
- Deployed YOLO detection to AWS EC2 Free Tier
- Hybrid cloud-edge architecture (AWS detection + on-device MLX)
- Cost: $0/month for 12 months, then ~$8.38/month
- Savings: $440/month vs GPU solution

**Key Achievements:**
- ✅ Optimized for t3.micro (904MB RAM, 8GB disk)
- ✅ CPU-only PyTorch (no GPU needed)
- ✅ NumPy compatibility fixed
- ✅ Three operating modes (Cloud/Offline/Developer)
- ✅ Complete iOS integration

---

**Version:** 1.0
**Last Updated:** 2025-11-03
**Deployment:** AWS EC2 us-east-2
**Maintainer:** Kitchen Assistant Team
