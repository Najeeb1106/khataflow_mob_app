# Architecture Overview

KhataFlow follows a **feature-first** package structure separated into clean structural layers to ensure high testability, modularity, and clean separation of concerns.

```
                   ┌───────────────────────┐
                   │       GoRouter        │
                   └───────────┬───────────┘
                               ▼
                   ┌───────────────────────┐
                   │    Presentation Layer │  ◀── (Widgets / Screens)
                   └───────────┬───────────┘
                               ▼
                   ┌───────────────────────┐
                   │    Riverpod Providers │  ◀── (State Controllers)
                   └───────────┬───────────┘
                               ▼
                   ┌───────────────────────┐
                   │   Repository Pattern  │  ◀── (Abstract Interfaces)
                   └───────────┬───────────┘
                               ▼
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
┌───────────────────────┐             ┌───────────────────────┐
│     Isar Database     │             │ Secure Key Value Store│
└───────────────────────┘             └───────────────────────┘
```

## Layers

### 1. Presentation Layer
Defines the user interface of the application. It is composed of screens and localized widgets using the Material 3 design system. It uses `ConsumerStatefulWidget` or `ConsumerWidget` to read or watch Riverpod providers.

### 2. State Management Layer (Riverpod)
Manages the reactive states of the system. State notifications are triggered by repository responses and UI interactions. It encapsulates state transformations, pagination, and user input validation before updating UI states.

### 3. Repository Layer
Abstracts datasource logic. It acts as the mediator between database entities, local files, and external systems (like sharing APIs). It enables offline-first caching policies, automatic garbage collection, and data security checks.

### 4. Data Services Layer
Handles physical interactions with hardware, filesystem, and local databases:
- **Isar Database**: High performance local object storage.
- **Flutter Secure Storage**: Hardware-backed credential and PIN encryption storage.
- **Local Notification Manager**: Scheduling automated reminders and daily alert tasks.
