# Timaro — automatic time clock for iOS

Timaro is a SwiftUI time clock that clocks you in when you arrive at a workplace and clocks you out when you leave, using iOS geofencing. You can also punch in and out by hand, edit shifts, track hours, overtime and earnings, and export a CSV timesheet. It is localized in English and Italian.

## Features

- **Automatic clock-in/out**: each workplace is a geofence (100–1000 m). It works in the background and after a reboot, because iOS relaunches the app when you cross a region boundary.
- **Shift resume**: if you come back within N minutes of leaving (lunch break or GPS jitter), the same shift continues instead of a new one starting.
- **Manual punch**: a large Clock in / Clock out button with a live timer.
- **Timesheet**: shifts grouped by week, with breaks, notes and full editing. You can also add shifts by hand.
- **Earnings and targets**: an hourly rate for each workplace, a weekly target, and an overtime display.
- **Punch rounding**: none, 5, 10, 15 or 30 minutes.
- **CSV export** through the share sheet.
- **Notifications** on automatic punches.
- **Private**: data stays on the device (SwiftData). There is no account and no server.

## Project layout

```
project.yml                 XcodeGen spec (generates Timaro.xcodeproj)
Timaro/App                  App entry point and AppDelegate
Timaro/Models               SwiftData models (Workplace, WorkSession) and settings
Timaro/Services             ClockService (punch rules), LocationMonitor (geofences),
                            notifications, CSV export, formatters
Timaro/Views                SwiftUI screens
Timaro/Resources            Asset catalog and Italian strings
```

## Build

Requirements: Xcode 15 or later and iOS 17 or later.

```sh
brew install xcodegen
xcodegen generate
open Timaro.xcodeproj
```

Set your signing team in the Timaro target. Change the bundle ID `com.timaro.timeclock` in `project.yml` if you need to. CI (`.github/workflows/build.yml`) builds the app for the simulator on every push.

## Uploading to App Store Connect

1. Create the app in App Store Connect with the same bundle ID.
2. In Xcode, choose Product → Archive, then Distribute App → App Store Connect.
3. App Review notes: the app uses **Always** location only to detect when you arrive at or leave a workplace you configured yourself. Explain this in the review notes, and include a short screen recording if review asks for one.
4. Privacy nutrition label: Location (precise) is used for app functionality only. It is not linked to the user and not used for tracking.

## TestFlight without a Mac

`.github/workflows/testflight.yml` archives, cloud-signs and uploads the app to TestFlight on every push to `main`, using an App Store Connect API key. Setup steps (in German): [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md).
