# Contributing to KhataFlow

Thank you for your interest in contributing to KhataFlow! We welcome pull requests, bug reports, and suggestions.

## Development Setup

1. Fork the repository and clone it locally.
2. Install the Flutter SDK (compatible with version specified in [README.md](README.md)).
3. Run `flutter pub get` to sync packages.
4. Run `dart run build_runner build --delete-conflicting-outputs` to generate the Isar and Riverpod schemas.

## Commit Guidelines

We use clean, descriptive commit messages. Please prefix your commits with standard types:
- `feat:` for new features.
- `fix:` for bug fixes.
- `docs:` for documentation updates.
- `style:` for code formatting changes.
- `test:` for test additions or updates.

## Pull Request Process

1. Create a branch from `main` (e.g. `feat/my-new-feature` or `fix/some-bug`).
2. Implement your changes, keeping coding styles consistent.
3. Verify that the app formats correctly using `dart format .`.
4. Ensure all unit and widget tests pass with `flutter test`.
5. Run `flutter analyze` to verify that there are zero warnings or static issues.
6. Open your pull request against the `main` branch.
