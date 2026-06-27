# Developer Build Guide

Follow these steps to clean, generate code, and build the binaries of **KhataFlow**.

---

## 1. Prerequisites
- **Flutter SDK**: `^3.35.0` or higher.
- **Dart SDK**: `^3.9.0` or higher.
- **Java**: JDK 17.

## 2. Build Pipeline Commands
Run these commands in order in your shell terminal:

```bash
# 1. Clear previous compile outputs
flutter clean

# 2. Sync packages
flutter pub get

# 3. Generate dynamic models code (Isar schemas)
dart run build_runner build --delete-conflicting-outputs

# 4. Perform lint checks
flutter analyze

# 5. Execute test suite
flutter test

# 6. Build target APK
flutter build apk --release
```
