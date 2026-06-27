# KhataFlow Release Notes - v1.0.0 (Production)

We are pleased to announce the production release of **KhataFlow v1.0.0**—a highly secure, offline-first personal ledger and expense bookkeeping manager for Android.

---

## Key Features in this Release
1. **Secure Biometric & Salted PIN Locks**:
   - Dynamic device-specific salting for SHA-256 local verification hashes.
   - Android Keystore integration via encrypted shared preferences.
2. **Offline-First Storage Architecture**:
   - Highly performant Isar Database with query indexing optimized for >50,000 transactions.
   - Full encryption-at-rest key management framework.
3. **Professional Statement Reports**:
   - PDF Statements generator complete with branding layout, running balance logs, and transaction status indicator cards.
4. **Local Reminders & Trash Recovery**:
   - Automated notification triggers for scheduled debt reviews.
   - Built-in trash bin for safety soft-deletes of transactions or entire contacts directory.
