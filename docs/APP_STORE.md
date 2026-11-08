# Timaro im App Store veröffentlichen

**Veröffentlicht:** https://apps.apple.com/app/id6827921143 (Apple-ID 6827921143) · Website: https://ivelo.app/timaro/

Texte und Angaben für App Store Connect zum Kopieren, dazu eine Checkliste.

## Checkliste

- [ ] TestFlight-Setup aus [TESTFLIGHT.md](TESTFLIGHT.md) erledigt, ein Build ist in App Store Connect angekommen
- [ ] App Group `group.com.timaro.timeclock` unter *Identifiers → App Groups* registriert und den App-IDs `com.timaro.timeclock` und `com.timaro.timeclock.widget` zugewiesen (falls der Build oder das Widget daran scheitert)
- [ ] GitHub Pages eingeschaltet: *Settings → Pages → Deploy from a branch → `main` / `/docs`* (bei privaten Repos nur mit GitHub Pro; sonst Repo öffentlich machen oder die Seiten woanders hosten)
- [ ] Seiten erreichbar: `https://jerrymittich.github.io/time-clock/privacy.html` und `…/support.html`
- [ ] *Business* → Vertrag „Kostenlose Apps“ akzeptiert (bei Bezahl-App: Bank- und Steuerdaten)
- [ ] EU-Händlerstatus (Digital Services Act) angegeben
- [ ] Store-Texte, Screenshots, Datenschutz-Angaben, Altersfreigabe ausgefüllt (siehe unten)
- [ ] Build der Version zugewiesen, Review-Notizen und Bildschirmaufnahme hinterlegt → *Zur Prüfung einreichen*

## App-Informationen

| Feld | Wert |
|---|---|
| Name (max. 30) | `Timaro – Stempeluhr` |
| Untertitel DE (max. 30) | `Arbeitszeit automatisch` |
| Subtitle EN (max. 30) | `Automatic work time tracker` |
| Primäre Kategorie | Produktivität |
| Sekundäre Kategorie | Business |
| Datenschutzrichtlinie-URL | `https://jerrymittich.github.io/time-clock/privacy.html` |
| Support-URL | `https://jerrymittich.github.io/time-clock/support.html` |
| Marketing-URL (optional) | `https://jerrymittich.github.io/time-clock/` |
| Copyright | `2026 Jerome Mittich` |
| Preis | Kostenlos (oder Preisstufe nach Wahl) |

### Werbetext DE (max. 170, jederzeit änderbar)

```
Kommen, gehen, fertig: Timaro stempelt dich automatisch ein und aus. Mit Zeitkonto, Urlaub und Widgets. Ohne Konto, ohne Server, alle Daten bleiben auf deinem iPhone.
```

### Keywords DE (max. 100 Zeichen, Komma ohne Leerzeichen; Name/Untertitel nicht wiederholen)

```
Zeiterfassung,Überstunden,Stundenzettel,Stundenkonto,Urlaub,Schicht,Geofence,Pause,Arbeitsstunden
```

### Beschreibung DE

```
Timaro ist die Stempeluhr, die von selbst mitdenkt: Kommst du an deinem Arbeitsplatz an, stempelt Timaro dich ein. Gehst du, stempelt Timaro dich aus. Du musst an nichts denken.

AUTOMATISCH EIN- UND AUSSTEMPELN
• Lege deine Arbeitsorte auf der Karte an (Radius 100–1000 m)
• Funktioniert im Hintergrund und auch nach einem Neustart
• Kurz weg in der Mittagspause? Kommst du rechtzeitig zurück, läuft dieselbe Schicht weiter

MANUELL STEMPELN MIT PAUSEN
• Start, Pause, Weiter, Beenden – mit Live-Timer
• Rundung auf 5, 10, 15 oder 30 Minuten

ZEITKONTO & URLAUB
• Tägliche Sollzeit, Überstunden und Minusstunden auf einen Blick
• Urlaubsanspruch pro Jahr, ganze und halbe Tage, Zeiträume ohne Wochenenden

STUNDENZETTEL
• Monatsübersicht mit Wochendiagramm und Zusammenfassung
• Schichten bearbeiten, nachtragen und mit Notizen versehen
• Verdienst nach Stundensatz pro Arbeitsort
• CSV-Export und Import von Tagessummen aus anderen Apps

WIDGETS
• Home- und Sperrbildschirm mit Live-Timer, Tagesfortschritt, Zeitkonto und Resturlaub
• Stempeln direkt im Widget

PRIVAT
Kein Konto, kein Server, keine Werbung, kein Tracking. Alle Daten bleiben auf deinem iPhone.

Hinweis: Für das automatische Stempeln benötigt Timaro den Standortzugriff „Immer“. Der Standort wird nur genutzt, um das Ankommen und Verlassen deiner Arbeitsorte zu erkennen, und nicht gespeichert oder weitergegeben.
```

### Promotional text EN

```
Arrive, leave, done: Timaro clocks you in and out automatically. With time account, vacation planning and widgets. No account, no server, all data stays on your iPhone.
```

### Keywords EN

```
time clock,timesheet,overtime,hours,shift,punch,geofence,vacation,work log,attendance,break
```

### Description EN

```
Timaro is the time clock that thinks for you: arrive at work and Timaro clocks you in. Leave and Timaro clocks you out. Nothing to remember.

AUTOMATIC CLOCK-IN AND CLOCK-OUT
• Add your workplaces on the map (radius 100–1000 m)
• Works in the background and after a restart
• Stepped out for lunch? Come back in time and the same shift continues

MANUAL PUNCHES WITH BREAKS
• Start, Break, Resume, Finish – with a live timer
• Round punches to 5, 10, 15 or 30 minutes

TIME ACCOUNT & VACATION
• Daily target, overtime and undertime at a glance
• Yearly vacation allowance, full and half days, date ranges that skip weekends

TIMESHEET
• Monthly view with weekly chart and summary
• Edit and add shifts, with notes
• Earnings from an hourly rate per workplace
• CSV export, and import of daily totals from other apps

WIDGETS
• Home Screen and Lock Screen with live timer, today's progress, time account and vacation left
• Punch right from the widget

PRIVATE
No account, no server, no ads, no tracking. All data stays on your iPhone.

Note: Automatic punches need "Always" location access. Your location is only used to detect arriving at and leaving your workplaces. It is never stored or shared.
```

## Screenshots

Pflicht: „iPhone mit Dynamic Island (mittleres Display)“ (1206 × 2622 px, iPhone 17), 3–10 Bilder ohne Transparenz. Andere Größen erzeugt Apple daraus.
Der Workflow *Screenshots* (Actions → Screenshots → Run workflow) nimmt sie als JPEG auf, Ergebnis im Branch `screenshots`.
Vorschlag für die Reihenfolge:

1. Stempeluhr mit laufender Schicht (Live-Timer)
2. Arbeitsort auf der Karte mit Radius
3. Stundenzettel mit Wochendiagramm
4. Zeitkonto und Urlaub
5. Widgets auf Home- und Sperrbildschirm

Tipp: Mit Beispieldaten aufnehmen, keine echten Adressen zeigen.

## Datenschutz-Angaben (App-Datenschutz)

Timaro überträgt keine Daten an den Entwickler oder Dritte. Laut Apple gelten Daten, die nur auf dem Gerät verarbeitet werden, nicht als „erhoben“. Deshalb:

- *Erheben Sie oder Ihre Drittanbieter Daten von dieser App?* → **Nein, wir erheben keine Daten von dieser App.**

Das passt zum Privacy Manifest (`Shared/PrivacyInfo.xcprivacy`, keine erhobenen Datentypen, kein Tracking).

## Altersfreigabe

Bei allen Fragen „Keine“ bzw. „Nein“ angeben (keine Gewalt, kein Glücksspiel, kein uneingeschränkter Webzugang, keine nutzergenerierten Inhalte für andere) → **4+**.

## Exportbestimmungen

Bereits erledigt: `ITSAppUsesNonExemptEncryption = NO` steht in `project.yml`, Apple fragt deshalb nicht mehr nach.

## Notizen für den App-Review (auf Englisch)

Bei *Anmeldung erforderlich* den Haken entfernen. Unter *Notizen* (deckt die Fragen ab, die App Review
bei der ersten Einreichung nach Guideline 2.1 „Information Needed“ gestellt hat):

```
1. SCREEN RECORDING
Attached: recorded on a physical iPhone running the latest iOS. It starts at the Home Screen with launching the app and shows the typical flow: onboarding, location permission, adding a workplace, the automatic clock-in, break/resume/finish, the timesheet, vacation, settings and the widget. The app has no account registration or login, no user-generated content shared with others, and no paid content or In-App Purchases.

2. PURPOSE AND TARGET AUDIENCE
Timaro is a personal time clock for employees and freelancers who want to keep track of their own working hours. It clocks the user in when they arrive at a workplace they set up themselves and out when they leave (iOS region monitoring), so they no longer have to remember to punch in and out. It also tracks breaks, overtime against a daily target (time account), vacation days and earnings, and exports a CSV timesheet. It is a general consumer app for individuals, not a tool for a specific company or organization.

3. HOW TO USE / TEST THE MAIN FEATURES
No login, account or sample files are needed.
- On first launch, tap "Get started" and allow location access (While Using, then Always) and notifications.
- Workplaces tab: tap +, tap "Use current location" (or search an address), keep "Clock in/out automatically" on, tap Save. Because the device is already inside the region, iOS reports it right away and a shift starts automatically ("Clocked in automatically" on the Clock tab).
- Clock tab: Break / Resume / Finish. Manual Start works without location access.
- Timesheet tab: monthly overview, weekly chart; tap a shift to edit it, + to add one, share icon to export CSV.
- Vacation tab: + to add full or half days.
- Settings: daily target, rounding, CSV export/import.
- Home Screen / Lock Screen widget "Timaro" with Start/Break/Finish buttons.
"Always" location is used only to detect arriving at and leaving workplaces the user created. Location is not stored as a history and never leaves the device.

4. EXTERNAL SERVICES
None of our own: no server, no backend, no analytics, no ads, no AI services, no payment processor, no authentication service. All data is stored on the device (SwiftData). The app only uses Apple frameworks: Core Location (region monitoring), MapKit (map display and address search, provided by Apple), WidgetKit/App Intents and local notifications.

5. REGIONAL DIFFERENCES
None. The app works the same in all regions. It is localized in English, German and Italian; currency and date formats follow the device settings.

6. REGULATED INDUSTRY / THIRD-PARTY MATERIAL
Not applicable. The app does not operate in a regulated industry and contains no protected third-party material.
```

### Bildschirmaufnahme

App Review verlangt eine Aufnahme auf einem **echten iPhone mit der neuesten iOS-Version**, die mit dem
Start der App beginnt. Hochladen unter *Informationen für die App-Prüfung → Anhang* (das Notizfeld nimmt nur Text).

1. Timaro löschen und über TestFlight neu installieren, damit das Onboarding erscheint. „Nicht stören“ einschalten.
2. Bildschirmaufnahme im Kontrollzentrum starten, auf dem Home-Bildschirm beginnen und Timaro antippen.
3. „Los geht's“, Standort „Beim Verwenden“ und dann „Immer“ erlauben, Mitteilungen erlauben.
4. Arbeitsorte → **+** → „Aktuellen Standort verwenden“ → Name → Sichern. Kurz warten: Timaro stempelt automatisch ein.
5. Stempeln: Pause, Weiter, Beenden.
6. Kurz durch Zeiten (Schicht antippen), Urlaub (Tag hinzufügen) und Einstellungen.
7. Zum Schluss das Widget auf dem Home-Bildschirm zeigen.

Etwa 1–2 Minuten. Danach im Resolution Center kurz antworten (z. B. *„Thank you. We added the requested
information to the App Review notes and attached a screen recording.“*) und erneut einreichen.
