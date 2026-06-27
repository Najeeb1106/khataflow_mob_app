# Production Deployment Guide

This guide walks you through compiling, signing, and deploying **KhataFlow** to the Google Play Store.

---

## 1. Keystore Signing Settings
Create and save a secure release keystore.

### A. Command
```bash
keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

### B. Link Keystore in Gradle
Add a `key.properties` configuration to the `android/` directory:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=key
storeFile=../release-keystore.jks
```

---

## 2. Compile Target Artifacts

### App Bundle (.aab)
Generates the optimized upload asset for the Play Console:
```bash
flutter build appbundle --release
```

### APK splits (by Architecture)
Generates lightweight APK binaries:
```bash
flutter build apk --split-per-abi --release
```
Binaries generated:
- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`
