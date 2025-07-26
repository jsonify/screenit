# Code Signing and Notarization Setup

This document explains how to set up code signing and notarization for the screenit macOS application in GitHub Actions.

## Overview

The release workflow includes optional code signing and notarization steps that will only run if the appropriate secrets are configured. This allows the workflow to work in development environments while enabling production-ready signed releases when needed.

## Required Apple Developer Account

To use code signing and notarization, you need:

1. **Apple Developer Account** - Individual or Organization account with macOS distribution capabilities
2. **Developer ID Application Certificate** - For signing applications distributed outside the App Store
3. **App-Specific Password** - For notarization service authentication

## GitHub Secrets Configuration

Configure the following secrets in your GitHub repository settings (Settings → Secrets and variables → Actions):

### Required for Code Signing

| Secret Name | Description | How to Generate |
|-------------|-------------|-----------------|
| `DEVELOPER_ID_CERTIFICATE_P12` | Base64-encoded Developer ID certificate | Export from Keychain Access as .p12, then `base64 -i certificate.p12` |
| `CERTIFICATE_PASSWORD` | Password for the .p12 certificate file | Set when exporting from Keychain Access |
| `KEYCHAIN_PASSWORD` | Password for temporary GitHub Actions keychain | Any secure password (e.g., generated UUID) |

### Required for Notarization

| Secret Name | Description | How to Generate |
|-------------|-------------|-----------------|
| `NOTARIZATION_USERNAME` | Apple ID email address | Your Apple Developer account email |
| `NOTARIZATION_PASSWORD` | App-specific password | Generate at appleid.apple.com → Sign-In and Security → App-Specific Passwords |
| `TEAM_ID` | Apple Developer Team ID | Found in Apple Developer Portal → Membership |

## Step-by-Step Setup

### 1. Generate Developer ID Certificate

1. Open **Keychain Access** on macOS
2. Go to **Keychain Access** → **Certificate Assistant** → **Request a Certificate from a Certificate Authority**
3. Enter your email and name, select "Saved to disk"
4. Upload the CSR to Apple Developer Portal → Certificates → Create Certificate → Developer ID Application
5. Download and install the certificate in Keychain Access

### 2. Export Certificate for GitHub Actions

1. In Keychain Access, find your "Developer ID Application" certificate
2. Right-click → **Export** → Choose .p12 format
3. Set a strong password (this becomes `CERTIFICATE_PASSWORD`)
4. Convert to base64: `base64 -i your-certificate.p12`
5. Copy the base64 output to `DEVELOPER_ID_CERTIFICATE_P12` secret

### 3. Set Up Notarization Credentials

1. Go to [appleid.apple.com](https://appleid.apple.com)
2. Sign in with your Apple Developer account
3. Go to **Sign-In and Security** → **App-Specific Passwords**
4. Generate a new password for "GitHub Actions Notarization"
5. Copy the generated password to `NOTARIZATION_PASSWORD` secret
6. Use your Apple ID email as `NOTARIZATION_USERNAME`
7. Find your Team ID in Apple Developer Portal → Membership

### 4. Configure Additional Secrets

- Set `KEYCHAIN_PASSWORD` to a secure random password (e.g., UUID)
- Ensure all secrets are configured correctly in GitHub repository settings

## Workflow Behavior

### With Code Signing Configured
- Application is built with Release configuration
- Archive is created with universal binary (Intel + Apple Silicon)
- Application is signed with Developer ID certificate
- Application is submitted for notarization
- Both ZIP and DMG files are created and attached to GitHub release

### Without Code Signing (Development)
- Application is built with Development configuration
- No signing or notarization is performed
- Only ZIP file is created and attached to GitHub release
- Applications will show security warnings when downloaded

## Verification

After a successful signed release:

1. Download the released application
2. Verify signing: `codesign --verify --verbose screenit.app`
3. Check notarization: `spctl --assess --verbose screenit.app`
4. The application should launch without security warnings

## Troubleshooting

### Common Issues

1. **Certificate Import Fails**
   - Ensure the .p12 file is valid and password is correct
   - Check that the certificate hasn't expired
   - Verify the certificate is a "Developer ID Application" certificate

2. **Notarization Fails**
   - Ensure app-specific password is correct and hasn't expired
   - Verify Team ID matches your Apple Developer account
   - Check that your Apple Developer account has active membership

3. **Code Signing Fails**
   - Ensure the certificate identity name matches "Developer ID Application"
   - Check that all binaries and frameworks are properly signed
   - Verify hardened runtime entitlements are configured correctly

### Manual Testing

You can test the scripts locally (with your own certificates):

```bash
# Run code signing tests
./scripts/test_code_signing.sh

# Test certificate installation (requires actual secrets)
security create-keychain -p "test" test.keychain
# ... (certificate import steps)
```

## Security Considerations

- Never commit certificates or passwords to the repository
- Use strong passwords for certificate files and keychains
- Regularly rotate app-specific passwords
- Monitor certificate expiration dates
- Review and audit access to GitHub repository secrets

## References

- [Apple Code Signing Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)