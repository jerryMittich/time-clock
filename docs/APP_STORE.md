# Timaro im App Store veröffentlichen

Texte und Angaben für App Store Connect zum Kopieren, dazu eine Checkliste.
Platzhalter in eckigen Klammern (`[…]`) müssen noch ersetzt werden.

## Checkliste

- [ ] TestFlight-Setup aus [TESTFLIGHT.md](TESTFLIGHT.md) erledigt, ein Build ist in App Store Connect angekommen
- [ ] App Group `group.com.timaro.timeclock` unter *Identifiers → App Groups* registriert und den App-IDs `com.timaro.timeclock` und `com.timaro.timeclock.widget` zugewiesen (falls der Build oder das Widget daran scheitert)
- [ ] Platzhalter (Name, Anschrift, E-Mail) in `docs/privacy.md` und `docs/support.md` ersetzt
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
| Copyright | `2026 [Vorname Nachname]` |
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
• Start, Pause, Weiter, Feierabend – mit Live-Timer
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

Pflicht: iPhone 6,9″ (1320 × 2868 px, z. B. iPhone 17 Pro Max), 3–10 Bilder. Kleinere Größen erzeugt Apple daraus.
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

Bei *Anmeldung erforderlich* den Haken entfernen. Unter *Notizen*:

```
Timaro is a time clock for employees. It has no account, no server and no network backend; all data is stored on the device with SwiftData.

Why "Always" location access:
The core feature is automatic clock-in/clock-out. The user creates a workplace on a map (with a radius of 100–1000 m). Timaro registers it as a region with CLLocationManager region monitoring (geofencing). When the user enters the region, a shift starts; when they leave, it ends. This must work while the app is in the background or not running, which requires "Always" authorization and the "location" background mode. Timaro does not track continuous location, does not store a location history and does not transmit location data. Without "Always" access the app still works with manual punches.

How to test:
1. Open the Workplaces tab and add a workplace. Use "Use current location" or search for an address, and keep the "Clock in/out automatically" toggle on.
2. Allow location access "While Using", then "Always" when iOS asks.
3. Leaving or entering the region creates or ends a shift (visible in the Clock and Timesheet tabs). In the simulator, use Features → Location to move in and out of the region.
4. Manual punches: Clock tab → Start / Break / Resume / Finish.
5. Widgets: add the Timaro widget on the Home Screen or Lock Screen; its buttons start and end shifts.

A short screen recording of the automatic clock-in is attached.
```

> Die Bildschirmaufnahme (30–60 s) kannst du am iPhone mit der Bildschirmaufnahme im Kontrollzentrum machen und unter *Anhang* hochladen.
