# KhataFlow

[![Platform Support](https://img.shields.io/badge/Platform-Android-007ACC?logo=android&logoColor=white)](#)
[![Flutter SDK](https://img.shields.io/badge/Flutter-^3.35.0-02569B?logo=flutter&logoColor=white)](#)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

**KhataFlow** is a secure, offline-first personal ledger and expense bookkeeping manager built with Flutter. It helps individuals, freelancers, and small businesses track transactions, manage debts/credits, generate PDF statements, and set automated reminders—all without requiring an active internet connection.

---

## 📱 Features

- **Biometric & PIN Lock Screen**: Fast, secure fingerprint and 4-digit PIN access powered by Android Keystore (SHA-256 salted hashes).
- **Offline-First Storage**: Local database operations using high-performance [Isar](https://isar.dev/) queries optimized for speed and large datasets (>50,000 transactions).
- **Statement Generation & Sharing**: Create professionally formatted PDF ledger statements with running balance logs, status cards, and direct sharing to WhatsApp.
- **Ledger Reminders & Notifications**: Local notification alerts for scheduled reviews and a daily summary review.
- **Trash Bin Recovery**: Safe deletion framework supporting soft-deletes and automatic 30-day purge management.

---

## 🛠️ Technology Stack

- **Framework**: [Flutter](https://flutter.dev) (Dart)
- **State Management**: [Riverpod](https://riverpod.dev) (Auto-generated providers, async state tracking)
- **Local Database**: [Isar Database](https://isar.dev)
- **Local Notifications**: `flutter_local_notifications`
- **PDF & Share**: `pdf`, `share_plus`, `url_launcher`
- **Routing**: [GoRouter](https://pub.dev/packages/go_router)

---

## 🏗️ Project Architecture

KhataFlow follows a **feature-first** structure to separate concerns and scale modularly:

```
lib/
├── core/                        # Shared configurations and services
│   ├── database/                # Isar Service setup and initialization
│   ├── errors/                  # App exceptions and error handling
│   ├── presentation/            # Shared base widgets (offline banner, etc.)
│   ├── router/                  # GoRouter router declaration
│   └── services/                # Notification, security, and purge services
└── features/                    # Modular feature directories
    ├── auth/                    # PIN/Biometric lock and unlock screens
    ├── dashboard/               # Main overview and balance widgets
    ├── khata/                   # Ledger accounts CRUD and details
    ├── notifications/           # Reminders and alert schedules
    ├── onboarding/              # Welcome screens and initial profile creation
    ├── people/                  # Customer/contacts directory
    ├── reports/                 # PDF ledger statements and generator
    ├── settings/                # App preferences and configurations
    ├── transactions/            # Add, edit, filter, and detail transactions
    └── trash/                   # Soft-delete recovery screen
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.35.0`
- **Dart SDK**: `^3.9.0`
- **Java**: JDK 17
- **Android Studio** or **VS Code** with Flutter extensions installed

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/codrix-dev/khata_app.git
   cd khata_app
   ```

2. **Sync packages**:
   ```bash
   flutter pub get
   ```

3. **Generate dynamic models code (Isar & Riverpod schemas)**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**:
   - For Android (emulator or physical device):
     ```bash
     flutter run
     ```

---

## 📘 Documentation Guides

- For code generation, static analysis, and running unit tests locally, check the [Developer Build Guide](BUILD_GUIDE.md).
- For signing configurations, Gradle linking, and compiling release APKs/App Bundles, check the [Production Deployment Guide](DEPLOYMENT_GUIDE.md).
- To read the functional requirements and architectural specifications of the application, check the [Product Requirements Document (PRD)](KhataFlow_PRD.md).

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
