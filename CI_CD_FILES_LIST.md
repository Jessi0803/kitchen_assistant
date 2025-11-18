# CI/CD Files Inventory

## 📁 File Organization Structure

```
edge-ai-kitchen-assistant/
├── .github/
│   ├── workflows/
│   │   ├── backend-ci-cd.yml           ← Backend automation workflow
│   │   └── ios-ci-cd.yml               ← iOS automation workflow
│   └── SECRETS_TEMPLATE.md             ← GitHub Secrets configuration template
│
├── backend/
│   ├── tests/                          ← Test directory
│   │   ├── __init__.py                 ← Python package marker
│   │   ├── conftest.py                 ← pytest configuration and fixtures
│   │   ├── test_unit.py                ← Unit tests
│   │   ├── test_api.py                 ← API endpoint tests
│   │   └── test_yolo.py                ← YOLO model tests
│   │
│   ├── Dockerfile                      ← Docker image build file
│   ├── .dockerignore                   ← Docker build exclusion file
│   ├── pytest.ini                      ← pytest configuration
│   ├── requirements.txt                ← Python dependencies (full)
│   ├── requirements-ci.txt             ← CI environment dependencies (lightweight)
│   ├── requirements-docker.txt         ← Docker environment dependencies
│   ├── main.py                         ← FastAPI main program (dev version)
│   ├── main-docker.py                  ← FastAPI main program (Docker version)
│   └── best.pt                         ← YOLO model file
│
├── ios-app/
│   ├── KitchenAssistantTests/
│   │   └── KitchenAssistantTests.swift ← iOS unit tests
│   ├── KitchenAssistantUITests/
│   │   └── KitchenAssistantUITests.swift ← iOS UI tests
│   ├── ExportOptions.plist             ← IPA export configuration
│   ├── Podfile                         ← CocoaPods dependencies
│   └── Podfile.lock                    ← CocoaPods locked versions
│
└── Documentation/
    ├── CI_CD_IMPLEMENTATION.md         ← 📖 This file (complete implementation guide)
    ├── CI_CD_SETUP.md                  ← Detailed setup guide
    ├── CI_CD_QUICKSTART.md             ← 15-minute quick start
    ├── CI_CD_FILES_OVERVIEW.md         ← File functionality overview
    └── IMPLEMENTATION_SUMMARY.md       ← Implementation summary and metrics
```

---

## 🔧 Core Files Description

### 1. GitHub Actions Workflows

| File | Purpose | Runtime Environment | Trigger Condition |
|------|---------|---------|---------|
| `backend-ci-cd.yml` | Backend CI/CD | Ubuntu | `backend/**` changes |
| `ios-ci-cd.yml` | iOS CI/CD | macOS-13 | `ios-app/**` changes |

### 2. Docker Related

| File | Purpose | Size Impact |
|------|---------|---------|
| `Dockerfile` | Define image build rules | ~1.2GB (optimized) |
| `.dockerignore` | Exclude unnecessary files | Reduces build context |
| `main-docker.py` | Docker-specific code | No Ollama dependency |

### 3. Testing Related

| File | Test Type | Run Location |
|------|---------|---------|
| `test_unit.py` | Unit tests | CI + Local |
| `test_api.py` | API tests | CI + Local |
| `test_yolo.py` | Model tests | Local (CI optional) |
| `KitchenAssistantTests.swift` | iOS unit tests | CI + Local |
| `KitchenAssistantUITests.swift` | iOS UI tests | CI + Local |

### 4. Dependency Management

| File | Purpose | Environment |
|------|-----|------|
| `requirements.txt` | Full dependencies | Local development |
| `requirements-ci.txt` | Lightweight dependencies | GitHub Actions |
| `requirements-docker.txt` | Production dependencies | Docker container |
| `Podfile` | iOS dependencies | iOS development |

---

## 📊 File Size Statistics

| Type | File Count | Total Size |
|------|-------|--------|
| Workflows | 2 | ~10KB |
| Tests | 5 | ~15KB |
| Docker | 2 | ~2KB |
| Configuration | 5 | ~5KB |
| Documentation | 5 | ~150KB |
| **Total** | **19** | **~182KB** |

---

## 🔑 Required GitHub Secrets

### Backend (5 secrets)
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`
- `EC2_HOST`
- `EC2_USERNAME`
- `EC2_SSH_KEY`

### iOS (6 secrets)
- `CERTIFICATES_P12`
- `CERTIFICATES_PASSWORD`
- `APPSTORE_ISSUER_ID`
- `APPSTORE_KEY_ID`
- `APPSTORE_PRIVATE_KEY`
- `DEVELOPMENT_TEAM_ID`

---

## 🚀 Quick Checklist

### Backend CI/CD ✅

- [ ] `.github/workflows/backend-ci-cd.yml` created
- [ ] `backend/tests/` directory contains test files
- [ ] `backend/Dockerfile` optimized (CPU PyTorch)
- [ ] `backend/.dockerignore` excludes large files
- [ ] `backend/pytest.ini` configured correctly
- [ ] `backend/requirements-ci.txt` doesn't include ollama
- [ ] All GitHub Secrets configured (5 total)
- [ ] EC2 Security Group allows ports 22, 8000
- [ ] Docker installed on EC2

### iOS CI/CD ✅

- [ ] `.github/workflows/ios-ci-cd.yml` created
- [ ] `KitchenAssistantTests` Target created
- [ ] `KitchenAssistantUITests` Target created
- [ ] `ExportOptions.plist` configured correctly
- [ ] `Podfile` dependencies installed
- [ ] All GitHub Secrets configured (6 total)
- [ ] Apple certificates and Provisioning Profile valid
- [ ] App Store Connect API Key created

---

## 📖 Command Reference

### Local Testing

```bash
# Backend tests
cd backend
pytest -v

# iOS tests
cd ios-app
xcodebuild test -workspace KitchenAssistant.xcworkspace \
  -scheme KitchenAssistant \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Docker Operations

```bash
# Build image
docker build -t kitchen-backend backend/

# Run container
docker run -d -p 8000:8000 --name kitchen-backend kitchen-backend

# View logs
docker logs -f kitchen-backend

# Cleanup
docker stop kitchen-backend
docker rm kitchen-backend
docker system prune -af
```

### EC2 Operations

```bash
# Connect to EC2
ssh -i awss.pem ubuntu@your-ec2-ip

# View running containers
docker ps

# View all containers
docker ps -a

# View images
docker images

# Check disk usage
df -h
docker system df
```

---

## 🔍 Troubleshooting Quick Reference

| Issue | Possible Cause | Check File |
|------|---------|---------|
| Tests fail | Missing dependencies | `requirements-ci.txt` |
| Docker build fails | Base image issue | `Dockerfile` |
| Docker image too large | GPU PyTorch | `Dockerfile` line 25-26 |
| EC2 connection fails | Security group config | AWS Console → Security Groups |
| API no response after deploy | Port not open | Security Group port 8000 |
| iOS build fails | Certificate issue | GitHub Secrets |
| UI tests fail | CI environment limitation | `ios-ci-cd.yml` line 75 |

---

## 📅 Maintenance Schedule

### Weekly Checks
- [ ] Review GitHub Actions execution history
- [ ] Check EC2 disk usage
- [ ] Review Docker Hub image count

### Monthly Checks
- [ ] Update Python dependency versions
- [ ] Update iOS CocoaPods dependencies
- [ ] Check Apple certificate expiration
- [ ] Review GitHub Actions usage

### Quarterly Checks
- [ ] Review CI/CD process efficiency
- [ ] Optimize Docker image size
- [ ] Update Xcode version
- [ ] Evaluate test coverage

---

## 📚 Further Reading

### Official Documentation
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [pytest Documentation](https://docs.pytest.org/)
- [XCTest Documentation](https://developer.apple.com/documentation/xctest)

### Best Practices
- [12 Factor App](https://12factor.net/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [iOS Testing Best Practices](https://developer.apple.com/documentation/xcode/testing-your-apps-in-xcode)

---

**Created**: 2024-01-01  
**Last Updated**: 2024-01-01  
**Version**: v1.0.0
