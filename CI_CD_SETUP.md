# CI/CD Setup Guide

Complete guide for setting up Continuous Integration and Continuous Deployment for Kitchen Assistant.

---

## 📋 Table of Contents

1. [Backend CI/CD](#backend-cicd)
2. [iOS CI/CD](#ios-cicd)
3. [GitHub Secrets Configuration](#github-secrets-configuration)
4. [Testing Locally](#testing-locally)
5. [Troubleshooting](#troubleshooting)

---

## Backend CI/CD

### Architecture

```
Push to main
    ↓
Run Tests (pytest)
    ├─ Unit Tests
    ├─ API Tests
    └─ YOLO Tests
    ↓
Build Docker Image
    ↓
Push to Docker Hub
    ↓
SSH to EC2
    ↓
Pull New Image
    ↓
Restart Container
    ↓
Health Check
```

### What Gets Automated

✅ **Automated Testing**
- Unit tests for core functions
- API endpoint tests
- YOLO model inference tests
- Coverage reports

✅ **Docker Build & Push**
- Automatic image building
- Tagging with commit SHA
- Push to Docker Hub/ECR
- Build caching for speed

✅ **EC2 Deployment**
- SSH into EC2
- Stop old container
- Pull latest image
- Start new container
- Health check
- Cleanup old images

---

## iOS CI/CD

### Architecture

```
Push to main
    ↓
Install Dependencies (CocoaPods)
    ↓
Build for Testing
    ↓
Run Unit Tests (XCTest)
    ↓
Run UI Tests
    ↓
Archive App
    ↓
Export IPA
    ↓
Upload to TestFlight
    ↓
Notify Success
```

### What Gets Automated

✅ **Automated Testing**
- Unit tests for models and logic
- UI tests for user flows
- Performance tests
- Test result uploads

✅ **Build & Archive**
- Clean build
- Code signing
- Archive creation
- IPA export

✅ **TestFlight Upload**
- Automatic version increment
- Upload to App Store Connect
- Beta distribution

---

## GitHub Secrets Configuration

### For Backend CI/CD

Navigate to: **Repository Settings → Secrets and variables → Actions**

Add the following secrets:

#### Docker Hub Credentials

```
Secret Name: DOCKER_USERNAME
Value: your-dockerhub-username
```

```
Secret Name: DOCKER_PASSWORD
Value: your-dockerhub-password
```

#### EC2 Deployment

```
Secret Name: EC2_HOST
Value: 18.188.20.164 (your EC2 IP)
```

```
Secret Name: EC2_USERNAME
Value: ec2-user
```

```
Secret Name: EC2_SSH_KEY
Value: (paste entire content of awss.pem file)
```

**How to add SSH key**:
```bash
# Copy your SSH key
cat awss.pem | pbcopy  # macOS
# or
cat awss.pem | xclip -selection clipboard  # Linux

# Paste in GitHub Secrets
# Make sure to include -----BEGIN RSA PRIVATE KEY----- and -----END RSA PRIVATE KEY-----
```

---

### For iOS CI/CD

#### App Store Connect API

```
Secret Name: APPSTORE_ISSUER_ID
Value: (from App Store Connect → Users and Access → Keys)
```

```
Secret Name: APPSTORE_KEY_ID
Value: (your API key ID)
```

```
Secret Name: APPSTORE_PRIVATE_KEY
Value: (content of .p8 file)
```

**How to get App Store Connect API key**:
1. Go to https://appstoreconnect.apple.com
2. Users and Access → Keys
3. Click + to create new key
4. Download .p8 file
5. Copy issuer ID and key ID

#### Code Signing

```
Secret Name: CERTIFICATES_P12
Value: (base64 encoded .p12 file)
```

```
Secret Name: CERTIFICATES_PASSWORD
Value: (password for .p12 file)
```

**How to create .p12 and encode**:
```bash
# Export certificate from Keychain as .p12
# Then encode to base64
base64 -i Certificates.p12 | pbcopy

# Paste the output in GitHub Secrets
```

#### Development Team

```
Secret Name: DEVELOPMENT_TEAM_ID
Value: (your Apple Team ID, e.g., A1B2C3D4E5)
```

---

## Testing Locally

### Backend Tests

```bash
cd backend

# Install test dependencies
pip install -r requirements-test.txt

# Run all tests
pytest

# Run specific test file
pytest tests/test_api.py -v

# Run with coverage
pytest --cov=. --cov-report=html

# View coverage report
open htmlcov/index.html
```

### iOS Tests

```bash
cd ios-app

# Install dependencies
pod install

# Run unit tests
xcodebuild test \
  -workspace KitchenAssistant.xcworkspace \
  -scheme KitchenAssistant \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run UI tests only
xcodebuild test \
  -workspace KitchenAssistant.xcworkspace \
  -scheme KitchenAssistant \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:KitchenAssistantUITests
```

---

## Workflow Triggers

### Backend CI/CD Triggers

✅ **Runs on**:
- Push to `main` branch
- Push to `develop` branch
- Pull requests to `main`
- Only when `backend/**` files change

❌ **Does NOT run on**:
- iOS file changes
- Documentation changes (unless backend files also changed)

### iOS CI/CD Triggers

✅ **Runs on**:
- Push to `main` branch
- Push to `develop` branch
- Pull requests to `main`
- Only when `ios-app/**` files change

❌ **Does NOT run on**:
- Backend file changes
- Documentation changes (unless iOS files also changed)

---

## CI/CD Pipeline Status

### Backend Pipeline

```yaml
✅ Test (3-5 min)
   ├─ Unit Tests
   ├─ API Tests
   └─ YOLO Tests
   
✅ Build Docker (2-3 min)
   ├─ Docker Build
   └─ Push to Registry
   
✅ Deploy to EC2 (1-2 min)
   ├─ SSH Connection
   ├─ Pull Image
   ├─ Restart Container
   └─ Health Check
```

**Total time**: ~6-10 minutes

---

### iOS Pipeline

```yaml
✅ Build and Test (5-8 min)
   ├─ Install Dependencies
   ├─ Build for Testing
   ├─ Unit Tests
   └─ UI Tests
   
✅ Archive and Upload (8-12 min)
   ├─ Archive App
   ├─ Export IPA
   └─ Upload to TestFlight
```

**Total time**: ~13-20 minutes

---

## Monitoring CI/CD

### View Workflow Runs

1. Go to GitHub repository
2. Click **Actions** tab
3. Select workflow:
   - Backend CI/CD
   - iOS CI/CD
4. View logs and status

### View Test Results

- Test results uploaded as artifacts
- Coverage reports available
- Download from Actions → Workflow run → Artifacts

### Check Deployment Status

**Backend**:
```bash
# Check if container is running
ssh -i awss.pem ec2-user@YOUR_EC2_IP
docker ps | grep kitchen-backend

# Check logs
docker logs kitchen-backend

# Test endpoint
curl http://YOUR_EC2_IP:8000/health
```

**iOS**:
1. Go to App Store Connect
2. TestFlight section
3. Check build status
4. View processing/available builds

---

## Optional: AWS ECR Instead of Docker Hub

If you prefer AWS ECR over Docker Hub:

### 1. Create ECR Repository

```bash
aws ecr create-repository --repository-name kitchen-assistant-backend
```

### 2. Update Workflow

Replace in `.github/workflows/backend-ci-cd.yml`:

```yaml
# Change this
env:
  DOCKER_REGISTRY: docker.io

# To this
env:
  DOCKER_REGISTRY: YOUR_ACCOUNT_ID.dkr.ecr.us-east-2.amazonaws.com
```

### 3. Add AWS Secrets

```
Secret Name: AWS_ACCESS_KEY_ID
Secret Name: AWS_SECRET_ACCESS_KEY
Secret Name: AWS_REGION
```

### 4. Update Login Step

```yaml
- name: Log in to Amazon ECR
  uses: aws-actions/amazon-ecr-login@v1
```

---

## Troubleshooting

### Backend Issues

#### Tests Fail

```bash
# Check if dependencies are installed
pip list

# Run tests locally first
pytest -v

# Check specific failing test
pytest tests/test_api.py::test_function_name -v
```

#### Docker Build Fails

```bash
# Test build locally
cd backend
docker build -f Dockerfile -t test-image .

# Check Dockerfile syntax
docker build --no-cache -f Dockerfile -t test-image .
```

#### EC2 Deployment Fails

```bash
# Test SSH connection
ssh -i awss.pem ec2-user@YOUR_EC2_IP

# Check if Docker is running on EC2
docker ps

# Check EC2 security group allows port 8000
```

---

### iOS Issues

#### Code Signing Errors

- Verify `.p12` file is correct
- Check password is correct
- Ensure Team ID matches
- Update provisioning profile

#### Tests Fail in CI but Pass Locally

- Check Xcode version matches
- Verify simulator is available
- Check for environment-specific code
- Review test logs in artifacts

#### TestFlight Upload Fails

- Verify App Store Connect API key
- Check bundle identifier matches
- Ensure app version is incremented
- Review export options

---

## Best Practices

### 1. Branch Protection

Enable in: **Settings → Branches → Add rule**

- Require status checks to pass
- Require pull request reviews
- Require tests to pass before merge

### 2. Notifications

Setup Slack/Email notifications:

```yaml
- name: Notify on failure
  if: failure()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### 3. Caching

Already configured for:
- Python pip packages
- CocoaPods
- Docker layers

### 4. Security

- Never commit secrets
- Use GitHub Secrets
- Rotate keys regularly
- Use minimal permissions

---

## Quick Reference

### Backend Commands

```bash
# Run tests
pytest

# Build Docker locally
docker build -f backend/Dockerfile -t kitchen-backend backend/

# Run container locally
docker run -p 8000:8000 kitchen-backend

# Push to Docker Hub
docker tag kitchen-backend YOUR_USERNAME/kitchen-assistant-backend
docker push YOUR_USERNAME/kitchen-assistant-backend
```

### iOS Commands

```bash
# Install dependencies
pod install

# Build
xcodebuild build -workspace KitchenAssistant.xcworkspace -scheme KitchenAssistant

# Test
xcodebuild test -workspace KitchenAssistant.xcworkspace -scheme KitchenAssistant -destination 'platform=iOS Simulator,name=iPhone 15'

# Archive
xcodebuild archive -workspace KitchenAssistant.xcworkspace -scheme KitchenAssistant -archivePath build/App.xcarchive
```

---

## Support

If you encounter issues:

1. Check workflow logs in Actions tab
2. Review error messages
3. Test locally first
4. Check GitHub Secrets are set correctly
5. Verify SSH keys and certificates

---

**Last Updated**: 2024-01-15
**Maintained By**: Kitchen Assistant Team

