# KhataFlow – Product Requirements Document
**Version:** 1.0  
**Author:** Najeeb Ullah  
**Studio:** Codrix.dev  
**Last Updated:** June 2026  
**Platform:** Flutter (Android-first)  
**Target Release:** September 2026

---

## 1. Overview

KhataFlow is an offline-first mobile application for personal debt and credit management. It targets individuals, freelancers, families, and small businesses who need a reliable way to track money they lend, borrow, receive, and repay — without depending on paper notebooks, WhatsApp messages, or memory.

---

## 2. Problem Statement

Millions of people in Pakistan and similar markets manage informal lending and borrowing using:

- Paper notebooks (lost, damaged, no backup)
- WhatsApp messages (unstructured, no totals)
- Memory (unreliable, causes disputes)

**Core pain points:**

- Forgotten transactions and missed repayments
- No reminders or due date tracking
- No proof or statements when disputes arise
- No backup when records are lost

---

## 3. Goals

### Primary Goal (Summer 2026)
Ship a production-grade Flutter application demonstrating:
- Offline-first architecture (Isar + Firestore sync)
- Cloud integration and authentication
- Local and push notifications
- PDF generation and sharing
- Scalable Riverpod state management

### Secondary Goal (Post-Launch)
Evolve into a trusted personal finance tool for informal debt management in Pakistan and similar markets.

---

## 4. Target Users

| User Type | Primary Need |
|-----------|-------------|
| Individuals | Track money lent to friends and relatives |
| Freelancers | Manage client advances and partial payments |
| Families | Maintain household informal financial records |
| Small Businesses | Track receivables and payables informally |

---

## 5. Core Data Model

### Person
Represents an individual the user transacts with.

| Field | Type | Notes |
|-------|------|-------|
| id | String (UUID) | Isar auto or manual |
| name | String | Required |
| phone | String? | Optional |
| notes | String? | Optional |
| createdAt | DateTime | Auto |
| isDeleted | bool | Soft delete |

---

### Khata
A financial account under a Person. One Person can have multiple Khatas.

| Field | Type | Notes |
|-------|------|-------|
| id | String | |
| personId | String | FK to Person |
| title | String | e.g. "Personal Loan" |
| notes | String? | |
| createdAt | DateTime | |
| isDeleted | bool | |

---

### Transaction
A financial event under a Khata.

| Field | Type | Notes |
|-------|------|-------|
| id | String | |
| khataId | String | FK to Khata |
| type | Enum | gave / received / borrowed / paid / adjustment |
| amount | double | Always positive |
| notes | String? | |
| dueDate | DateTime? | Optional |
| reminderDate | DateTime? | Optional |
| photoUrl | String? | Optional |
| createdAt | DateTime | |
| isDeleted | bool | |

---

### Transaction Types

| Type | Direction | Meaning |
|------|-----------|---------|
| `gave` | Outgoing | User lent money |
| `received` | Incoming | User received repayment |
| `borrowed` | Incoming | User borrowed money |
| `paid` | Outgoing | User repaid borrowed money |
| `adjustment` | Either | Manual correction |

---

## 6. Architecture

```
UI Layer (Flutter Screens)
        ↓
State Layer (Riverpod Providers)
        ↓
Repository Layer (abstracts local vs remote)
        ↓
┌────────────────┬─────────────────┐
│  Isar (Local)  │ Firestore (Cloud)│
└────────────────┴─────────────────┘
```

- **Isar** is the source of truth at all times
- **Firestore** syncs in background when internet is available
- **Conflict resolution:** Last-write-wins based on `updatedAt` timestamp
- **State management:** Riverpod (providers, notifiers, async state)

---

## 7. Development Phases

---

## Phase 1 — Foundation (Weeks 1–2)

**Goal:** Local data layer working completely. No UI polish. No Firebase.

### Tasks
- [ ] Project setup: Flutter, Riverpod, Isar, folder structure, routing (GoRouter)
- [ ] Define Isar schemas: Person, Khata, Transaction
- [ ] Implement repositories: PersonRepository, KhataRepository, TransactionRepository
- [ ] Riverpod providers for each entity
- [ ] Basic CRUD operations tested manually

### Deliverable
Full local CRUD for all three entities. A person can be created, listed, edited, and deleted. Same for Khata and Transaction.

---

## Phase 2 — Core Screens (Weeks 3–4)

**Goal:** All primary screens functional with real data.

---

### Screen 1 — Splash / Onboarding

**Purpose:** App intro and first-time setup.

**Elements:**
- App logo and name
- Short value proposition (one line)
- "Get Started" CTA
- Skip option after first launch

**State:** Shown only on first install. After that, routes directly to Dashboard.

---

### Screen 2 — Authentication

**Purpose:** Google Sign-In for cloud sync and backup.

**Elements:**
- App branding
- "Sign in with Google" button
- "Continue offline" option (skip auth, limited features)

**Behavior:**
- Auth is optional at launch
- Users who skip cannot access cloud sync or cross-device access
- Banner shown on Dashboard reminding them to sign in

---

### Screen 3 — Dashboard

**Purpose:** Overview of financial position and quick access to all features.

**Elements:**

| Section | Details |
|---------|---------|
| Summary Cards | Total Receivable, Total Payable, Net Position |
| Alert Row | Overdue Amount, Due Today |
| Recent Transactions | Last 5–10 entries with person name, amount, type |
| FAB | Quick Add Transaction |
| Bottom Nav | Dashboard, People, Reports, Settings |

**Balance Logic:**
- Net Position = Total Receivable − Total Payable
- Positive = user is owed money (green)
- Negative = user owes money (red)

---

### Screen 4 — People List

**Purpose:** Browse all persons the user has financial relationships with.

**Elements:**
- Search bar
- Person cards: name, phone, net balance with them
- Balance badge: green (they owe you), red (you owe them), grey (settled)
- FAB: Add New Person

**Sorting:** By name, by balance (highest receivable first), by last activity.

---

### Screen 5 — Add / Edit Person

**Purpose:** Create or update a person record.

**Fields:**
- Name (required)
- Phone number (optional, with phone picker)
- Notes (optional)

**Behavior:**
- Save creates Person in Isar
- Phone field opens contacts picker (with permission)
- Validation: Name cannot be empty

---

### Screen 6 — Person Detail

**Purpose:** View all Khatas under a person and total balance with them.

**Elements:**
- Person header: name, phone, total net balance
- Khata list: each card shows title, balance, last activity date
- FAB: Add New Khata
- Options: Edit person, Delete person (soft delete)

---

### Screen 7 — Add / Edit Khata

**Purpose:** Create or update a Khata under a person.

**Fields:**
- Title (required) — e.g. "Personal Loan", "Shop Credit"
- Notes (optional)

---

### Screen 8 — Khata Detail

**Purpose:** Full transaction history for a single Khata.

**Elements:**
- Khata header: title, opening balance, current balance
- Transaction list (chronological, newest first)
- Each transaction card: type icon, amount, date, notes preview
- FAB: Add Transaction (Quick Mode)
- Filter bar: All / Gave / Received / Borrowed / Paid

**Balance Display:**
- Running balance shown per transaction (like a bank statement)
- Auto-reversal shown if repayment exceeds outstanding

---

### Screen 9 — Quick Add Transaction

**Purpose:** Add a transaction in under 5 seconds.

**Fields (minimal):**
- Person (autocomplete search)
- Khata (auto-selected if only one, dropdown if multiple)
- Amount
- Transaction Type (4 large tap buttons: Gave / Received / Borrowed / Paid)

**Behavior:**
- Saves immediately on confirm
- Optional: "Add Details" button expands to Advanced Mode

---

### Screen 10 — Advanced Transaction Form

**Purpose:** Add full transaction details.

**Additional Fields:**
- Notes
- Due Date (date picker)
- Reminder Date (date picker)
- Photo Attachment (camera or gallery)

---

## Phase 3 — Firebase Layer (Weeks 5–6)

**Goal:** Cloud sync, authentication, and cross-device access.

### Tasks
- [ ] Firebase project setup (Auth, Firestore, Storage)
- [ ] Google Sign-In integration
- [ ] Firestore data structure mirroring Isar schema
- [ ] SyncService: push local changes to Firestore on connectivity
- [ ] SyncService: pull remote changes on login / app open
- [ ] Conflict resolution: compare `updatedAt`, keep latest
- [ ] Firebase Storage for photo attachments
- [ ] Connectivity monitoring (connectivity_plus)

### Firestore Structure

```
users/{uid}/
  persons/{personId}
  khatas/{khataId}
  transactions/{transactionId}
```

### Conflict Strategy
- Every record has `updatedAt` (DateTime)
- On sync: if local `updatedAt` > remote → push local
- If remote `updatedAt` > local → pull remote
- Deleted records: keep `isDeleted: true`, never hard delete from Firestore

---

## Phase 4 — Notifications (Week 7)

**Goal:** Working local and push notifications.

### Screen 11 — Notifications / Reminders

**Purpose:** View all upcoming and overdue alerts.

**Notification Types:**

| Type | Trigger | Example |
|------|---------|---------|
| Due Today | On app open + scheduled | "Ali Khan owes Rs. 10,000. Due today." |
| Overdue | Daily 9 AM | "Ahmed Raza payment overdue by 7 days." |
| Custom Reminder | User-set date | User-defined note |
| Daily Summary | Daily 8 PM | "You are owed Rs. 45,000 total." |

### Implementation
- **Local notifications:** flutter_local_notifications
- **Push notifications:** Firebase Cloud Messaging (FCM)
- Permission request on first launch
- Notification settings in Settings screen

---

## Phase 5 — Statements & Sharing (Week 8)

**Goal:** PDF generation, WhatsApp sharing.

### Screen 12 — Statement Preview

**Purpose:** Generate and preview a professional PDF statement.

**Statement Contains:**
- App branding header
- Person details
- Khata title
- Date range filter
- Transaction table: date, type, amount, notes, running balance
- Opening balance
- Closing balance
- Outstanding balance (bold)
- Generated on timestamp

**Actions:**
- Download PDF
- Share via WhatsApp
- Share via other apps (share sheet)

### Implementation
- PDF package: `pdf` (dart)
- WhatsApp: `url_launcher` with WhatsApp deep link + file share
- File storage: `path_provider` for temp PDF files

---

## Phase 6 — Polish & Edge Cases (Week 9)

**Goal:** The difference between a student project and a production app.

### Tasks
- [ ] Empty states for all lists (no people, no khatas, no transactions)
- [ ] Error states (network failure, sync error)
- [ ] Loading states (skeleton loaders, not spinners everywhere)
- [ ] Form validation messages (clear, not generic)
- [ ] Offline banner (shown when no internet)
- [ ] Sync status indicator on Dashboard
- [ ] Trash / Soft Delete screen
- [ ] 30-day auto-purge for deleted records

### Screen 13 — Trash

**Purpose:** View and restore deleted records.

**Elements:**
- Tabs: Persons / Khatas / Transactions
- Each item shows deletion date
- Actions: Restore, Permanently Delete
- Auto-purge after 30 days (shown in UI)

---

### Screen 14 — Settings

**Purpose:** App configuration and account management.

**Sections:**

| Section | Options |
|---------|---------|
| Account | Profile photo, name, email, Sign Out |
| Notifications | Toggle each notification type, set daily summary time |
| Data | Export to Google Sheets, Clear All Data |
| App | Theme (light/dark), Currency symbol, App version |
| About | Privacy Policy, Terms, Contact |

---

## Phase 7 — Deployment & Documentation (Week 10)

**Goal:** Shipped, documented, demo-ready.

### Tasks
- [ ] Signed APK build
- [ ] Play Store listing (screenshots, description, privacy policy)
- [ ] README with architecture diagram, setup steps, feature list
- [ ] Architecture decision record (why Isar, why Riverpod, sync strategy)
- [ ] Demo video (screen recording, 2–3 minutes)
- [ ] Add to portfolio and Codrix.dev case study

---

## 8. Screen Summary

| # | Screen | Phase |
|---|--------|-------|
| 1 | Splash / Onboarding | 2 |
| 2 | Authentication | 3 |
| 3 | Dashboard | 2 |
| 4 | People List | 2 |
| 5 | Add / Edit Person | 2 |
| 6 | Person Detail | 2 |
| 7 | Add / Edit Khata | 2 |
| 8 | Khata Detail | 2 |
| 9 | Quick Add Transaction | 2 |
| 10 | Advanced Transaction Form | 2 |
| 11 | Notifications / Reminders | 4 |
| 12 | Statement Preview | 5 |
| 13 | Trash | 6 |
| 14 | Settings | 6 |

**Total Screens: 14**

---

## 9. Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter (Dart) |
| State Management | Riverpod |
| Local Database | Isar |
| Auth | Firebase Authentication (Google) |
| Cloud Database | Cloud Firestore |
| File Storage | Firebase Storage |
| Push Notifications | Firebase Cloud Messaging |
| Local Notifications | flutter_local_notifications |
| PDF Generation | pdf (dart package) |
| WhatsApp Sharing | url_launcher |
| Connectivity | connectivity_plus |
| Routing | GoRouter |

---

## 10. Out of Scope (v1)

- Google Sheets export (deferred — Google Sheets API is disproportionately complex for v1 value)
- Shared Khatas (multi-user)
- Excel export
- Voice notes
- AI insights
- Web application
- Inventory integration

---

## 11. Success Criteria

| Criteria | Target |
|----------|--------|
| Quick Add transaction | Under 5 seconds |
| Offline functionality | 100% core features work without internet |
| Sync reliability | No data loss on reconnection |
| PDF generation | Clean, readable, shareable statement |
| Crash rate | Zero known crashes on demo device |
| Shipped by | 1 September 2026 |
