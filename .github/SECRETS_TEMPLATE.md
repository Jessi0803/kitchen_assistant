# GitHub Secrets Template

Copy this template and fill in your values in GitHub repository settings.

## Backend Secrets

### Docker Hub
```
DOCKER_USERNAME=your-dockerhub-username
DOCKER_PASSWORD=your-dockerhub-password-or-access-token
```

### EC2 Deployment
```
EC2_HOST=18.188.20.164
EC2_USERNAME=ec2-user
EC2_SSH_KEY=
-----BEGIN RSA PRIVATE KEY-----
(paste full content of your .pem file here)
-----END RSA PRIVATE KEY-----
```

## iOS Secrets

### App Store Connect API
```
APPSTORE_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APPSTORE_KEY_ID=XXXXXXXXXX
APPSTORE_PRIVATE_KEY=
-----BEGIN PRIVATE KEY-----
(paste content of AuthKey_XXXXXXXXXX.p8)
-----END PRIVATE KEY-----
```

### Code Signing
```
CERTIFICATES_P12=(base64 encoded .p12 file)
CERTIFICATES_PASSWORD=your-p12-password
DEVELOPMENT_TEAM_ID=XXXXXXXXXX
```

## How to Add Secrets

1. Go to your GitHub repository
2. Click **Settings**
3. Click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Add each secret from above

## How to Generate Each Secret

### Docker Hub Token
1. Go to https://hub.docker.com
2. Account Settings → Security
3. New Access Token
4. Copy token

### EC2 SSH Key
```bash
cat awss.pem
```
Copy entire content including BEGIN/END lines

### App Store Connect API Key
1. https://appstoreconnect.apple.com
2. Users and Access → Keys
3. Generate API Key
4. Download .p8 file
5. Copy Issuer ID and Key ID

### Code Signing Certificate
```bash
# Export from Keychain as .p12
# Encode to base64
base64 -i Certificates.p12 | pbcopy
```

### Team ID
Find in:
- Xcode: Project → Signing & Capabilities
- Apple Developer: Account → Membership

