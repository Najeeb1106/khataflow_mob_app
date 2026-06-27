# GitHub Professional Repository Standards — Mobile Applications

**Engineering Excellence Guide — Version 1.0**

---

## Purpose

This document defines the professional standards every engineer must meet before publishing or updating a mobile application repository on GitHub. Every commit, every README, and every repository must reflect production-quality mobile engineering — whether the target is Android, iOS, or cross-platform (Flutter, React Native, Expo).

---

## 1. Repository Structure

A well-structured mobile repository communicates professionalism before a single line of code is read. Apply these standards to every project.

### 1.1 Folder Organization

- Separate concerns clearly: `lib/` or `src/`, `assets/`, `test/`, `docs/`, `scripts/`, platform folders (`android/`, `ios/`).
- Follow the conventions of your framework:
  - **Flutter:** `lib/` with feature-first or layer-first architecture (`features/`, `core/`, `shared/`).
  - **React Native / Expo:** `src/` with `screens/`, `components/`, `hooks/`, `navigation/`, `services/`.
  - **Native Android:** standard Gradle structure (`app/src/main/java/`, `res/`, `manifests/`).
  - **Native iOS:** standard Xcode project structure (`Sources/`, `Resources/`, `Tests/`).
- Maintain consistent naming conventions across the entire project (snake_case for Dart, camelCase/PascalCase for JS/TS/Swift/Kotlin, as appropriate to the language).
- Remove all unnecessary files: build artifacts, generated files, IDE-specific configs, OS artifacts (`.DS_Store`, `Thumbs.db`).

### 1.2 Essential Root Files

| File | Required? | Purpose |
|------|-----------|---------|
| `README.md` | Mandatory | Primary project documentation |
| `LICENSE` | Mandatory (public repos) | Legal usage rights — omitting means all rights reserved |
| `.gitignore` | Mandatory | Prevents secrets, build artifacts, and keystore files from being committed |
| `.env.example` | Mandatory (if env vars used) | Documents required env vars without exposing real values |
| `pubspec.yaml` / `package.json` | Mandatory | Dependency manifest (framework-specific) |
| `CONTRIBUTING.md` | Recommended | Contribution guidelines for collaborators |
| `CHANGELOG.md` | Recommended | Version history and release notes |
| `CODE_OF_CONDUCT.md` | Optional | Community behavior standards for open source projects |

### 1.3 What Must Be in `.gitignore`

The following must never be committed:

```
# Flutter
.dart_tool/
build/
*.g.dart (generated files)
pubspec.lock (for apps — commit for packages)

# React Native / Expo
node_modules/
.expo/
android/app/build/
ios/build/
ios/Pods/

# Android
*.jks
*.keystore
local.properties
/build
/captures
.gradle/

# iOS
*.xcworkspace/xcuserdata
DerivedData/
*.ipa
*.dSYM.zip

# General
.env
*.log
.DS_Store
Thumbs.db
```

---

## 2. README.md Requirements

The README is the front door of your repository. It must be clear, complete, and visually organized. Every public or portfolio repository requires a professional README.

### 2.1 Required Sections

- Project title with a concise one-line description
- Platform and OS support badges (Android, iOS, minimum SDK/OS version)
- Badges (build status, coverage, license, version) where applicable
- Feature list highlighting key capabilities
- Full tech stack (language, framework, state management, backend integration, external SDKs)
- Prerequisites (Flutter SDK version, Xcode version, Android Studio version, Node version, etc.)
- Installation and environment setup instructions
- How to run the app (on emulator and physical device)
- Usage instructions with annotated screenshots or demo GIFs — **required for all UI-facing apps**
- Store links (if published to Google Play or App Store)
- Folder structure diagram or explanation
- API documentation summary or link to full docs
- Known limitations or future improvements
- License section

### 2.2 Optional but Recommended

- Architecture diagram (MVC, MVVM, Clean Architecture, BLoC, etc.)
- State management strategy explanation
- Deep link and notification setup instructions
- Challenges faced and engineering decisions made
- Contributing section with PR and issue guidelines
- Table of contents for longer READMEs

---

## 3. Code Quality Standards

Code pushed to the main branch must be readable, modular, and maintainable. These are non-negotiable for any repository intended to be seen by others.

### 3.1 Readability and Modularity

- Functions and widgets/components must do one thing clearly. Split large widgets.
- Use descriptive, intention-revealing names for variables, functions, classes, and routes.
- Keep files and functions small and focused. A single widget or screen file should rarely exceed 300 lines.
- Apply consistent formatting — use the framework's standard formatter:
  - Flutter: `dart format .`
  - React Native / Expo: ESLint + Prettier
  - Native Android: Android Studio formatter / ktlint
  - Native iOS: SwiftLint
- Commit the linter/formatter config to the repo.

### 3.2 Architecture Requirements

Mobile apps require explicit architecture decisions. "Just putting everything in the screen file" is not acceptable for portfolio or production repositories. Document the chosen pattern in the README.

Accepted patterns (choose one and apply it consistently):
- **Flutter:** BLoC, Riverpod, Provider, GetX (with discipline), Clean Architecture
- **React Native:** Redux Toolkit, Zustand, React Query + Context, Jotai
- **Native Android:** MVVM + ViewModel + LiveData / StateFlow + Repository pattern
- **Native iOS:** MVVM, MVC (with clear separation), TCA (The Composable Architecture)

### 3.3 What Must Be Removed Before Pushing

> **Remove all of the following before any push to main:**
> - Hardcoded secrets, API keys, tokens, client IDs, or Firebase config values in code
> - Commented-out dead code *(in-progress work on feature branches is acceptable)*
> - `print()` / `debugPrint()` / `console.log()` statements not serving a documented purpose
> - TODO comments that have been resolved
> - Unused imports, variables, assets, or dependencies
> - Test/placeholder assets (lorem ipsum images, dummy icons)

---

## 4. Branching Strategy

A professional mobile repository requires a defined branching model. Never commit directly to `main` for any non-trivial change.

### 4.1 Recommended Branch Model

| Branch | Purpose | Who Merges |
|--------|---------|------------|
| `main` | Production-ready code only. App Store / Play Store ready. | Via PR from `develop` or `release` |
| `develop` | Active integration branch for features. Stable but not necessarily released. | Via PR from feature branches |
| `feature/name` | Individual feature or screen. Branched from `develop`, merged back via PR. | Developer, reviewed by peer |
| `fix/name` | Bug fixes. Branched from `develop` or `main` depending on urgency. | Developer, reviewed by peer |
| `release/x.x.x` | Stabilization, version bumps, and final testing before merging to `main`. | Release engineer |

### 4.2 Pull Request Standards

- Every merge to `main` or `develop` must go through a Pull Request (PR).
- PRs must include a clear description of what changed and why, and which screens or flows are affected.
- Attach screenshots or screen recordings of the changed UI in the PR description.
- Link PRs to the relevant issue or ticket.
- Require at least one reviewer approval before merging on team projects.

---

## 5. Commit Message Standards

Use the **Conventional Commits** format. Every commit message must be meaningful, specific, and written in the imperative mood. Vague messages like "update", "fix", "done", or "final" are unacceptable.

### 5.1 Commit Message Format

```
<type>(<scope>): <short description>
```

- **type:** `feat` | `fix` | `refactor` | `docs` | `test` | `chore` | `style` | `perf` | `ci`
- **scope:** optional — the screen, module, or area affected (e.g. `auth`, `home`, `notifications`, `navigation`)
- **description:** imperative, lowercase, max ~72 characters, no period at the end

### 5.2 Mobile-Specific Commit Examples

```
feat(auth): implement biometric login with local_auth
fix(home): resolve scroll jank on product list view
refactor(api): extract dio interceptors into separate service
chore(android): update gradle and kotlin plugin versions
style(onboarding): align illustrations per updated design spec
perf(images): add cached_network_image to reduce redundant fetches
docs(readme): add Android emulator setup instructions
test(auth): add widget tests for login form validation
ci(github): add Flutter build workflow for Android and iOS
```

---

## 6. Testing and CI/CD Requirements

Relying solely on manual testing on a single device is unreliable and unprofessional. Automated testing and CI are expected on any serious mobile project.

### 6.1 Testing Standards

| Test Type | Scope | Required? |
|-----------|-------|-----------|
| Unit tests | Business logic, utility functions, repository layer | Required |
| Widget tests (Flutter) / Component tests (RN) | Individual UI components | Strongly recommended |
| Integration tests | Full user flows end-to-end | Required for portfolio projects |
| Manual device testing | Android + iOS, multiple screen sizes | Required before any release |

- Aim for meaningful coverage (70%+ on core business logic), not just high numbers.
- Fix all analyzer warnings. Zero-warning builds are the goal:
  - Flutter: `flutter analyze` with zero issues
  - React Native: ESLint with zero errors
  - Android: no Lint errors in `app/`
  - iOS: no SwiftLint errors
- Verify the project builds and runs from a clean clone on both Android and iOS before pushing (for cross-platform projects).

### 6.2 GitHub Actions (CI/CD)

Every non-trivial mobile repository should have at least a basic CI pipeline via GitHub Actions.

**Flutter example workflow triggers:**
- On `pull_request` to `main`/`develop`: run `flutter analyze`, `flutter test`, and `flutter build apk --release`.
- On `push` to `main`: run full test suite; optionally trigger Fastlane or Codemagic for store deployment.

**React Native example workflow triggers:**
- On `pull_request`: run ESLint, Jest tests, and a Metro bundler validation build.
- On `push` to `main`: run full test suite; optionally trigger Expo EAS Build.

Consider adding:
- Dependency security checks (Dependabot for npm / pub.dev packages)
- Firebase App Distribution for internal test builds
- Automated APK/IPA artifact uploads on CI runs

---

## 7. Sensitive Files and Security

Mobile apps carry unique security risks that web apps do not. Apply zero tolerance.

> **Zero Tolerance: These violations must never occur in any push.**
> - Committing `google-services.json` or `GoogleService-Info.plist` with real project credentials
> - Committing `.keystore` or `.jks` Android signing files
> - Committing `.p8`, `.p12`, or iOS provisioning profiles
> - Hardcoded API keys, Firebase keys, or client secrets in Dart/Swift/Kotlin/JS source files
> - Pushing `.env` files containing real credentials (only `.env.example` is acceptable)
> - Misconfigured `.gitignore` that allows any of the above into version history

### 7.1 Security Checklist

- `.gitignore` covers: `.env`, `*.jks`, `*.keystore`, `google-services.json`, `GoogleService-Info.plist`, `local.properties`, `Pods/`, `build/`, `*.log`
- `.env.example` exists with placeholder values and comments for every required variable
- API keys are loaded at runtime from environment variables or a secrets manager, not embedded in code
- Firebase configs use environment-specific project IDs (dev / prod separation)
- Deep link scheme does not expose sensitive routing patterns
- Dependencies checked for known vulnerabilities (`flutter pub outdated`, `npm audit`)

---

## 8. Deployment and Distribution

### 8.1 Expectations by Project Type

| Project Type | Deployment Expectation | Recommended Platform |
|-------------|----------------------|----------------------|
| Flutter app (portfolio) | Build APK/AAB and upload; Play Store preferred | Google Play (internal testing track) |
| React Native / Expo app | EAS Build + Expo preview link at minimum | Expo EAS, Play Store, TestFlight |
| Native Android app | Signed APK/AAB in GitHub Releases at minimum | Google Play |
| Native iOS app | TestFlight link or signed IPA at minimum | Apple TestFlight |
| Backend-connected mobile app | Deploy backend; provide working API base URL | Render, Railway, Fly.io |
| Open source SDK / package | Publish to pub.dev or npm | pub.dev, npmjs.com |

> **Always verify your demo build link, APK link, or store listing is live and accessible before linking in your README. A broken demo link is worse than no link.**

### 8.2 Minimum Release Artifact for Portfolio Projects

If you cannot publish to a store, provide at minimum:
- A signed debug or release APK attached to a GitHub Release
- OR a working Expo Go / TestFlight link
- AND working screenshots or a screen recording in the README

A repository with no way to experience the app is significantly weaker than one with a downloadable build.

---

## 9. Documentation Standards

- Add inline comments for non-obvious logic — not for obvious operations.
- Document all state management flows: where state lives, how it flows, what triggers rebuilds.
- Include API integration documentation: base URLs, endpoint summary, authentication method, error handling strategy.
- Document environment setup in detail — exact SDK versions, Xcode version, Java version, NDK version if applicable.
- Add architecture diagrams for complex apps using draw.io, Mermaid, or Excalidraw.
- Document all environment variables in `.env.example` with descriptions and example values.
- Maintain a `CHANGELOG.md` for projects that are versioned or publicly released.

---

## 10. Versioning and Releases

### 10.1 Semantic Versioning (SemVer) for Mobile

Mobile apps carry two version identifiers. Both must be managed correctly:

| Identifier | What It Is | When to Increment |
|-----------|------------|-------------------|
| Version name (e.g. `1.2.3`) | Human-readable SemVer | MAJOR: breaking change; MINOR: new feature; PATCH: bug fix |
| Build number / version code (e.g. `47`) | Store-required integer | Increment on every store submission — never reuse |

- Flutter: manage in `pubspec.yaml` as `version: 1.2.3+47`
- React Native / Expo: manage in `app.json` (`version` + `android.versionCode` + `ios.buildNumber`)
- Native Android: manage in `build.gradle` (`versionName` + `versionCode`)
- Native iOS: manage in `Info.plist` (`CFBundleShortVersionString` + `CFBundleVersion`)

- Tag releases in Git: `git tag -a v1.2.3 -m "Release 1.2.3"`
- Create GitHub Releases with release notes derived from `CHANGELOG.md`
- Attach signed APK/IPA to the GitHub Release

---

## 11. Repository Presentation

Your GitHub profile is a professional portfolio. Apply the same care to how it looks as you would to a resume.

- Use clear, professional repository names in kebab-case (e.g., `smart-timetable-app`, not `FlutterProject_FINAL2`).
- Write a concise, informative repository description that mentions the platform and core purpose (e.g., `Flutter + FastAPI app for AI-powered university timetable management`).
- Add relevant topic tags (e.g., `flutter`, `dart`, `firebase`, `mobile`, `android`, `ios`, `react-native`) to improve discoverability.
- Pin only your best and most complete mobile repositories on your profile — preferably ones with working demos or store links.
- Prefer quality over quantity: one deployed, polished mobile app is stronger than five incomplete projects.

---

## 12. Final Verification Checklist

Complete every item before pushing to `main` or publishing a repository. Do not skip items because they seem minor.

### Repository & Files

- [ ] `README.md` is complete with all required sections
- [ ] `LICENSE` file is present (for public/open-source repos)
- [ ] `.gitignore` is correctly configured for the target platform(s)
- [ ] `.env.example` is present and documents all required variables
- [ ] No secrets, tokens, signing keys, Firebase configs, or real credentials anywhere in the repo
- [ ] Folder structure is clean and follows the chosen architecture pattern

### Code Quality

- [ ] No commented-out dead code in the final branch
- [ ] No debug `print()` / `console.log()` statements left in production code
- [ ] Formatter run with zero errors (`dart format .` / Prettier / ktlint / SwiftLint)
- [ ] Static analyzer passes with zero issues (`flutter analyze` / ESLint / Lint / SwiftLint)
- [ ] No unused imports, assets, or dependencies
- [ ] Architecture pattern applied consistently across the codebase

### Testing & Build

- [ ] All unit and widget/component tests pass locally
- [ ] App builds and runs from a clean clone on Android (and iOS if cross-platform)
- [ ] Key user flows manually verified on a physical device or realistic emulator
- [ ] CI/CD pipeline passes (if configured)
- [ ] Signing config works for release build (debug builds only are not acceptable for portfolio projects)

### Commits & Branching

- [ ] Commit history uses Conventional Commits format
- [ ] No vague commit messages (`update`, `fix`, `done`, `final`)
- [ ] Changes merged via Pull Request (for team projects)

### Deployment & Documentation

- [ ] Live demo link, store link, or downloadable APK is accessible and working
- [ ] Screenshots or screen recording added to README (required for all UI apps)
- [ ] API and environment setup documentation is present and accurate
- [ ] Architecture diagram included (for complex apps)
- [ ] `CHANGELOG.md` updated (for versioned projects)
- [ ] Version name and build number are correctly set in the platform config files

### Repository Presentation

- [ ] Repository name is professional, descriptive, and in kebab-case
- [ ] Repository description mentions the platform and core purpose
- [ ] Relevant topic tags added on GitHub

---

> **The Standard Is Simple**
> Every repository you publish is a statement about your engineering judgment. If you would not show it to a senior mobile engineer in a job interview, it is not ready to push.

---

*Confidential — Internal Engineering Standards*
