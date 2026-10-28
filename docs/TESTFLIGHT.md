# Timaro über TestFlight aufs iPhone – ohne Mac

Der Workflow `.github/workflows/testflight.yml` baut die App bei jedem Push auf `main`
auf einem Mac in der GitHub-Cloud, signiert sie und lädt sie zu TestFlight hoch.
Manuell starten geht auch: GitHub → *Actions* → *TestFlight* → *Run workflow*.

Alles Folgende geht im Browser (auch am iPhone/iPad oder Windows-PC).

## 1. Apple Developer Program (einmalig, 99 €/Jahr)

Mitglied werden auf https://developer.apple.com/programs/enroll/ – am einfachsten mit der
**Apple-Developer-App** auf dem iPhone. Die Freischaltung dauert meist 1–2 Tage.

## 2. Bundle-ID registrieren

https://developer.apple.com/account/resources/identifiers/list → **+** → *App IDs* → *App*

- Description: `Timaro`
- Bundle ID (Explicit): `com.timaro.timeclock`
- Keine zusätzlichen Capabilities nötig → *Register*

> Falls die ID schon vergeben ist: eine eigene wählen (z. B. `com.jerrymittich.timaro`)
> und sie in `project.yml` bei `PRODUCT_BUNDLE_IDENTIFIER` eintragen.

## 3. App in App Store Connect anlegen

https://appstoreconnect.apple.com/apps → **+** → *Neue App*

- Plattform: iOS · Name: `Timaro` (muss im App Store eindeutig sein, sonst z. B. „Timaro Stempeluhr“)
- Primäre Sprache: Deutsch · Bundle-ID: die aus Schritt 2 · SKU: `timaro`

## 4. API-Schlüssel erstellen

App Store Connect → *Benutzer und Zugriff* → *Integrationen* → *App Store Connect API*
→ *Team-Schlüssel* → **+**

- Name: `GitHub TestFlight` · Zugriff: **Admin**
  (Admin ist nötig, damit Apple das Verteilungszertifikat automatisch in der Cloud anlegen kann.)
- Notiere **Schlüssel-ID** und oben die **Issuer-ID**.
- **API-Schlüssel laden** (`AuthKey_XXXX.p8`) – geht nur **einmal**, gut aufheben.

Die **Team-ID** steht unter https://developer.apple.com/account → *Mitgliedschaftsdetails*.

## 5. Secrets in GitHub eintragen

https://github.com/jerryMittich/time-clock/settings/secrets/actions → *New repository secret*

| Name | Inhalt |
|---|---|
| `ASC_KEY_ID` | Schlüssel-ID (z. B. `AB12CD34EF`) |
| `ASC_ISSUER_ID` | Issuer-ID (UUID) |
| `ASC_KEY_P8` | kompletter Inhalt der `.p8`-Datei inkl. `-----BEGIN PRIVATE KEY-----` / `-----END PRIVATE KEY-----` |
| `APPLE_TEAM_ID` | Team-ID (10 Zeichen) |

Die `.p8`-Datei lässt sich mit jedem Texteditor öffnen (am iPhone z. B. in der Dateien-App
per Teilen → in Notizen kopieren).

## 6. Build starten

GitHub → *Actions* → *TestFlight* → *Run workflow*. Nach ca. 5–10 Minuten ist der Upload
fertig; Apple verarbeitet den Build danach noch 10–30 Minuten.

## 7. Auf dem iPhone installieren

1. App Store Connect → Timaro → *TestFlight* → *Interne Tests* → Gruppe anlegen, dich
   selbst als Tester hinzufügen und den Build zuweisen.
2. Einladung per Mail annehmen, die **TestFlight**-App aus dem App Store laden und Timaro installieren.

Jeder weitere Push auf `main` erzeugt automatisch einen neuen Build (Build-Nummer = Lauf-Nummer
des Workflows). TestFlight-Builds laufen 90 Tage.

Solange die Secrets fehlen, überspringt der Workflow den Upload einfach (grüner Lauf mit Hinweis).
