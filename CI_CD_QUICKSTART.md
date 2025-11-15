# CI/CD Quick Start Guide

Get your CI/CD pipeline running in 15 minutes.

---

## ⚡ Quick Setup (5 Steps)

### Step 1: Enable GitHub Actions (1 min)

Your workflows are already created in `.github/workflows/`:
- ✅ `backend-ci-cd.yml` 
- ✅ `ios-ci-cd.yml`

They will activate automatically once secrets are configured.

---

### Step 2: Add Backend Secrets (3 min)

Go to: **GitHub Repository → Settings → Secrets and variables → Actions**

Click **New repository secret** and add:

```
Name: DOCKER_USERNAME
Value: [your Docker Hub username]

Name: DOCKER_PASSWORD  
Value: [your Docker Hub password or access token]

Name: EC2_HOST
Value: 18.188.20.164 (or your EC2 IP)

Name: EC2_USERNAME
Value: ec2-user

Name: EC2_SSH_KEY
Value: [paste full content of awss.pem file]
```

**Tip**: Get Docker Hub token at https://hub.docker.com → Account Settings → Security

---

### Step 3: Test Backend CI/CD (2 min)

```bash
# Make a small change
cd backend
echo "# Test CI/CD" >> README.md

# Commit and push
git add .
git commit -m "test: trigger backend CI/CD"
git push origin main
```

**Watch it run**:
1. Go to GitHub → Actions tab
2. Click on "Backend CI/CD" workflow
3. Watch the progress:
   - ✅ Tests (~3 min)
   - ✅ Build Docker (~2 min)
   - ✅ Deploy to EC2 (~1 min)

---

### Step 4: Add iOS Secrets (5 min)

**Required only if deploying to TestFlight**

```
Name: APPSTORE_ISSUER_ID
Value: [from App Store Connect → Users and Access → Keys]

Name: APPSTORE_KEY_ID
Value: [your API key ID]

Name: APPSTORE_PRIVATE_KEY
Value: [content of .p8 file]

Name: CERTIFICATES_P12
Value: [base64 encoded .p12 file]

Name: CERTIFICATES_PASSWORD
Value: [password for .p12 file]

Name: DEVELOPMENT_TEAM_ID
Value: [your Team ID, e.g., A1B2C3D4E5]
```

---

### Step 5: Test iOS CI/CD (2 min)

```bash
# Make a small change
cd ios-app
echo "# Test CI/CD" >> README.md

# Commit and push
git add .
git commit -m "test: trigger iOS CI/CD"
git push origin main
```

**Watch it run**:
1. GitHub → Actions → "iOS CI/CD"
2. Progress:
   - ✅ Build & Test (~5 min)
   - ✅ Archive & Upload (~10 min)

---

## 🎯 What You Get

### Backend CI/CD

**Every push to main**:
```
1. Runs all tests automatically
2. Builds Docker image
3. Pushes to Docker Hub
4. Deploys to EC2
5. Runs health check
```

**Time**: 6-10 minutes total

---

### iOS CI/CD

**Every push to main**:
```
1. Installs dependencies
2. Runs unit tests
3. Runs UI tests
4. Archives app
5. Uploads to TestFlight
```

**Time**: 13-20 minutes total

---

## 🔍 Verify It's Working

### Backend

```bash
# Check deployment
curl http://YOUR_EC2_IP:8000/health

# SSH to EC2 and check container
ssh -i awss.pem ec2-user@YOUR_EC2_IP
docker ps | grep kitchen-backend
docker logs kitchen-backend
```

### iOS

1. Go to https://appstoreconnect.apple.com
2. TestFlight section
3. Check for new build

---

## 🚀 Daily Workflow

### For Developers

**Before**:
```bash
# 1. Write code
# 2. Build locally (10 min)
# 3. Test manually (5 min)
# 4. Archive (10 min)
# 5. Upload to TestFlight (15 min)
# Total: 40 min of your time
```

**After (with CI/CD)**:
```bash
# 1. Write code
# 2. git push
# 3. Go get coffee ☕
# Total: 2 min of your time
```

---

## 📊 Monitoring

### View Workflow Status

```
GitHub → Actions Tab
├── Backend CI/CD (latest runs)
├── iOS CI/CD (latest runs)
└── Click any run to see logs
```

### Get Notifications

Add to workflows for Slack notifications:

```yaml
- name: Notify on failure
  if: failure()
  run: echo "Tests failed! Check logs."
```

---

## 🛠️ Run Tests Locally

### Backend

```bash
cd backend
pip install -r requirements-test.txt
pytest -v
```

### iOS

```bash
cd ios-app
xcodebuild test \
  -workspace KitchenAssistant.xcworkspace \
  -scheme KitchenAssistant \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

---

## 🔧 Troubleshooting

### Backend Tests Fail

```bash
# Run locally to debug
cd backend
pytest -v

# Check specific test
pytest tests/test_api.py::test_name -v
```

### Docker Build Fails

```bash
# Test Docker build locally
cd backend
docker build -f Dockerfile -t test-build .
```

### EC2 Deployment Fails

- Check EC2 is running
- Verify security group allows port 8000
- Test SSH connection
- Check Docker is running on EC2

### iOS Build Fails

- Verify Xcode version in workflow
- Check code signing certificates
- Ensure bundle ID matches
- Review build logs in Actions

---

## 📝 Files Created

```
Your Repository
├── .github/
│   ├── workflows/
│   │   ├── backend-ci-cd.yml    ✅ Backend pipeline
│   │   └── ios-ci-cd.yml        ✅ iOS pipeline
│   └── SECRETS_TEMPLATE.md      📋 Secrets reference
│
├── backend/
│   ├── tests/
│   │   ├── __init__.py
│   │   ├── conftest.py          ✅ Test fixtures
│   │   ├── test_api.py          ✅ API tests
│   │   ├── test_yolo.py         ✅ Model tests
│   │   └── test_unit.py         ✅ Unit tests
│   ├── pytest.ini               ⚙️ Pytest config
│   └── requirements-test.txt    📦 Test dependencies
│
├── ios-app/
│   ├── KitchenAssistantTests/
│   │   └── KitchenAssistantTests.swift  ✅ Unit tests
│   ├── KitchenAssistantUITests/
│   │   └── KitchenAssistantUITests.swift ✅ UI tests
│   └── ExportOptions.plist      ⚙️ Export config
│
├── CI_CD_SETUP.md               📚 Full documentation
└── CI_CD_QUICKSTART.md          ⚡ This file
```

---

## 🎉 Next Steps

1. ✅ **Push code** → CI/CD runs automatically
2. ✅ **Review test results** in Actions tab
3. ✅ **Monitor deployments** 
4. ✅ **Iterate and improve** your tests

---

## 💡 Pro Tips

### 1. Branch Protection

Enable: **Settings → Branches → Add rule**
- ✅ Require status checks to pass
- ✅ Require PR reviews

### 2. Only Deploy on Main

Workflows already configured to:
- Run tests on all branches
- Deploy only on main branch

### 3. Manual Approval

Add manual approval for production:

```yaml
environment:
  name: production
  url: http://your-ec2-ip:8000
```

Then require approval in: **Settings → Environments**

---

## 📞 Need Help?

See full documentation: [`CI_CD_SETUP.md`](CI_CD_SETUP.md)

Common issues:
- Secrets not working? Double-check names match exactly
- EC2 deployment fails? Test SSH connection manually
- iOS signing fails? Verify certificate and provisioning profile

---

**Time to set up**: ~15 minutes  
**Time saved per deployment**: ~40 minutes  
**Break even after**: 1 deployment 🎯

Happy coding! 🚀

