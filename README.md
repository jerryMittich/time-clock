# Timaro — automatic time clock for iOS

Timaro is a SwiftUI time clock that clocks you in when you arrive at a workplace and clocks you out when you leave, using iOS geofencing. You can also punch in and out by hand, edit shifts, track hours, overtime and earnings, and export a CSV timesheet. It is localized in English, German and Italian.

**[Download on the App Store](https://apps.apple.com/app/id6827921143)** · [ivelo.app/timaro](https://ivelo.app/timaro/)

## Features

- **Automatic clock-in/out**: each workplace is a geofence (100–1000 m). It works in the background and after a reboot, because iOS relaunches the app when you cross a region boundary.
- **Shift resume**: if you come back within N minutes of leaving (lunch break or GPS jitter), the same shift continues instead of a new one starting.
- **Manual punch with breaks**: Start in the morning, Break / Resume at lunch, Finish in the evening, with a live timer that stops during breaks.
- **Time account**: a daily target (8 h by default). Time above it is credited to the account and shorter days are covered from it. Days without shifts are not counted, and a starting balance can be set.
- **Vacation and absences**: a yearly allowance, full and half days, date ranges that skip weekends, and an overview of days taken, planned and left. Other absences (sick leave, paternity leave, …) use reasons you set up in Settings; they lower that day's target like vacation but don't count against the allowance. Several days can be selected and deleted at once.
- **Timesheet**: swipe between months; each month shows a weekly bar chart against the daily target (vacation in yellow, other absences in purple), a month summary, and the shifts grouped by day, with breaks, notes and full editing. You can also add shifts by hand.
- **Tags**: tags you set up in Settings (e.g. home office) can be added to shifts; they appear in the timesheet, the CSV export and the statistics.
- **Statistics**: totals, overtime, work days, average per work day, breaks, earnings and days off for a week, month, year, all time or a custom range, optionally per workplace or tag; hours per day/week/month, average per weekday and hours per workplace and per tag as charts, plus a list per period.
- **Earnings**: an hourly rate for each workplace.
- **Punch rounding**: none, 5, 10, 15 or 30 minutes.
- **CSV export** through the share sheet, and **CSV import** of daily totals (`Datum;Stunden;Sollstunden;Überstunden;Pause;Abwesenheitstyp`) from other time-clock apps; absence days are skipped and days that already have shifts are left alone.
- **Notifications** on automatic punches.
- **Widgets**: Home Screen (small, medium) and Lock Screen (circular, rectangular, inline) with a live timer, start time and breaks, today's progress, time account and vacation left. Interactive Start / Break / Resume / Finish buttons (App Intents that run in the app's process). The app shares a status snapshot with the widget through the App Group `group.com.timaro.timeclock`.
- **Design**: Liquid Glass surfaces on iOS 26 (material fallback on iOS 17–18) with a light-blue accent.
- **Private**: data stays on the device (SwiftData). There is no account and no server.

## Project layout

```
project.yml                 XcodeGen spec (generates Timaro.xcodeproj)
Timaro/App                  App entry point and AppDelegate
Timaro/Models               SwiftData models (Workplace, WorkSession) and settings
Timaro/Services             ClockService (punch rules), LocationMonitor (geofences),
                            notifications, CSV export, formatters
Timaro/Views                SwiftUI screens
Timaro/Resources            Asset catalog and permission prompt strings
TimaroWidget                WidgetKit extension
Shared                      Code and German/Italian strings used by app and widget
TimaroTests                 Unit tests for the time account, breaks and vacation
```

## Build

Requirements: Xcode 15 or later and iOS 17 or later.

```sh
brew install xcodegen
xcodegen generate
open Timaro.xcodeproj
```

Set your signing team in the Timaro target. Change the bundle ID `com.timaro.timeclock` in `project.yml` if you need to. CI (`.github/workflows/build.yml`) builds the app and runs the unit tests in the simulator on every push.

## Uploading to App Store Connect

1. Create the app in App Store Connect with the same bundle ID.
2. In Xcode, choose Product → Archive, then Distribute App → App Store Connect.
3. App Review notes: the app uses **Always** location only to detect when you arrive at or leave a workplace you configured yourself. Explain this in the review notes, and include a short screen recording if review asks for one.
4. Privacy: the privacy manifest is `Shared/PrivacyInfo.xcprivacy` (bundled into app and widget). No data leaves the device, so the App Store privacy label is "Data Not Collected".

Store texts, review notes and a release checklist (in German): [docs/APP_STORE.md](docs/APP_STORE.md). The privacy policy and support pages in `docs/` are meant for GitHub Pages.

## TestFlight without a Mac

`.github/workflows/testflight.yml` archives, cloud-signs and uploads the app to TestFlight on every push to `main`, using an App Store Connect API key. Setup steps (in German): [docs/TESTFLIGHT.md](docs/TESTFLIGHT.md).
