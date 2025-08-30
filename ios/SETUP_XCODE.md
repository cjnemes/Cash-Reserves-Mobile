# Cash Reserves Mobile – Xcode Setup (No Coding Needed)

Follow these steps once to get the iOS app running in Xcode:

1) Create the app project
- Open Xcode → File → New → Project…
- iOS → App → Next
- Product Name: CashReservesApp
- Interface: SwiftUI, Language: Swift
- Save anywhere (you can save inside this repo if you prefer)

2) Add the engine package
- In Xcode, select your project in the sidebar, then the project target
- Go to the “Package Dependencies” tab → “+”
- Click “Add Local…” and choose this folder: ios/ReserveEngine
- Ensure the package product “ReserveEngine” is added to your app target under “Frameworks, Libraries, and Embedded Content”

3) Add the app Swift files
- In Finder, open this repo folder and locate ios/CashReservesApp
- Drag the entire CashReservesApp folder into Xcode under your app target (check “Copy items if needed”)
- If Xcode asks for group/folder options, choose “Create groups”

4) Set the app entry
- Ensure “CashReservesApp.swift” is present (it defines @main)
- If a default ContentView.swift was created, you can delete it (optional)

5) Build & run
- Select an iPhone simulator (e.g., iPhone 15)
- Press Run (⌘R)

App Icon
- I included an App Icon asset set at `ios/CashReservesApp/Assets.xcassets/AppIcon.appiconset`.
- To avoid the default placeholder, drop a 1024×1024 PNG named `AppIcon-1024.png` into that folder in Finder, then drag it into Xcode’s AppIcon grid.
- Xcode (iOS 16+) accepts a single 1024×1024 image and will derive the rest.

6) Import your existing JSON (optional)
- Go to Settings tab → Import Plan JSON → pick your desktop reserve_manager.json

That’s it. I can adjust anything you want in the UI. This is a mobile-first layout with tabs for Dashboard, Tiers, Planner, History, Settings.

Troubleshooting
- If the package doesn’t link: clean build folder (Shift+⌘K) and rebuild.
- If previews fail: just run the simulator; previews are optional.
- If import/export dialogs don’t appear on simulator: make sure you’re on iOS 16+ simulator image.
