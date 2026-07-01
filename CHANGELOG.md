# Changelog

All notable changes to this project will be documented in this file.

## [1.2.0] - 2026-06-27
### Added
- Integrated cached search query history inside the Global Search screen.
- Configured dynamic "Export History" tracking for generated PDF statements.
- Centralized custom snackbar layout `AppSnackbar` and confirmation prompts `AppConfirmationDialog`.
- Implemented `AppHaptics` trigger integrations for saves, deletes, and security changes.
- Embedded local database size metrics, backup timestamps, and open-source licenses page inside settings.

### Fixed
- Fixed navigation routes when tapping search result transactions to land on correct ledger entries.
- Avoided widget culling on small test viewports by wrapping settings scroll view in a Column.
- Cleaned unused imports and fixed static analyzer warnings.

---

## [1.1.1] - 2026-06-25
### Added
- Implemented shimmer skeleton placeholders during card load times.
- Integrated `google_fonts` (Inter) for standard body copy text.

---

## [1.1.0] - 2026-06-20
### Added
- Integrated monthly Cash Flow ratio trends widget via `fl_chart`.
- Added swipe gestures for transaction entries (swipe left to delete, swipe right to edit).
- Configured local biometric lock options and timeout triggers.

---

## [1.0.0] - 2026-06-10
### Added
- Initial release featuring local 4-digit PIN authentication.
- Offline-first storage schemas utilizing the high-performance Isar database.
- Dynamic PDF reports compilation and local Android notification schedules.
