# Development Guide

Prereqs
- Xcode 15+, iOS 16+ simulator

Setup
- Follow ios/SETUP_XCODE.md to add the local Swift package and app sources.

Coding Style
- Swift 5, SwiftUI, Combine
- Prefer immutable data + pure functions in the engine
- Round money to 2 decimals at boundaries (UI/outputs)

Branching (optional)
- main: stable
- feat/*: features
- fix/*: bugfixes

Testing
- Add a Unit Test target; load JSON fixtures; compare algorithm outputs.
 - For Core Data, you can instantiate a test-only in-memory PersistenceController.

Releases
- Bump version in About section; archive via Xcode Organizer.

Data Migration
- On first launch after this update, the app automatically migrates existing `history.json` to Core Data (`CDTransaction`), then removes the JSON file.
