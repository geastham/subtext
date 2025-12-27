# Subtext - Phase 1: Foundation & Data Layer

## Overview

Phase 1 implementation of Subtext, an AI-powered conversation coaching app for iOS.

## Features

✅ SwiftData models (ConversationThread, Message, CoachingSession)
✅ Secure local storage with AES-256-GCM encryption
✅ Main navigation structure with TabView
✅ Settings screen with privacy controls
✅ Data deletion functionality

## Project Structure

```
Subtext/
├── SubtextApp.swift              # App entry point
├── Models/
│   ├── ConversationThread.swift  # Main conversation container
│   ├── Message.swift             # Individual messages
│   └── CoachingSession.swift     # AI coaching sessions
├── Services/
│   ├── DataStore.swift           # SwiftData manager
│   └── SecurityService.swift     # Encryption service
└── Views/
    ├── MainTabView.swift         # Tab navigation
    ├── ConversationListView.swift # Conversation list
    └── SettingsView.swift        # Settings & privacy
```

## Requirements

- iOS 17.0+
- Swift 5.9+
- Xcode 15.0+

## Phase 1 Status

✅ Complete - Ready for Phase 2

## Next Steps

Phase 2 will add:
- Text import from multiple sources
- Message parsing and speaker identification
- Full conversation detail view
- Search and filter capabilities

For complete documentation, see `/docs/mvp/01-phase-1-foundation.md`
