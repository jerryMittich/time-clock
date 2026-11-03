# Timaro Support

[English version below](#english)

Fragen, Probleme oder Ideen? Schreib an **[support@ivelo.app](mailto:support@ivelo.app)** oder eröffne ein [Issue auf GitHub](https://github.com/jerryMittich/time-clock/issues).

Hilfreich sind dabei: iPhone-Modell, iOS-Version, Timaro-Version (Einstellungen → Version) und eine kurze Beschreibung, was passiert ist.

## Häufige Fragen

**Das automatische Ein- und Ausstempeln funktioniert nicht.**
- Einstellungen → Timaro → Standort: **Immer** und **Genauer Standort** müssen aktiv sein.
- Beim Arbeitsort muss „Automatisch ein-/ausstempeln“ eingeschaltet sein.
- Wähle einen Radius von mindestens 150 m. Kleinere Radien erkennt iOS unzuverlässig.
- iOS meldet das Betreten oder Verlassen manchmal erst mit einigen Minuten Verzögerung. Das ist normal.
- Wenn der Stromsparmodus aktiv ist, können Meldungen später kommen.

**Ich gehe mittags kurz weg. Beginnt dann eine neue Schicht?**
Nein, wenn du innerhalb der eingestellten Zeit zurückkommst (Einstellungen → „Schicht fortsetzen, wenn zurück innerhalb von“), läuft dieselbe Schicht weiter.

**Wie sichere ich meine Daten?**
Deine Daten liegen nur auf dem iPhone und werden mit deinem iCloud- oder Computer-Backup gesichert. Zusätzlich kannst du jederzeit einen CSV-Export erstellen.

**Wie importiere ich Daten aus einer anderen Stempeluhr-App?**
Einstellungen → Zeiten importieren (CSV). Erwartet werden Tagessummen im Format `Datum;Stunden;Sollstunden;Überstunden;Pause;Abwesenheitstyp`. Abwesenheitstage werden übersprungen, Tage mit vorhandenen Schichten bleiben unverändert.

**Das Widget zeigt einen alten Stand.**
Öffne Timaro einmal kurz. iOS aktualisiert Widgets nach eigenem Zeitplan.

**Wie lösche ich alle Daten?**
Wenn du die App löschst, werden alle Daten entfernt.

Datenschutz: [Datenschutzerklärung](privacy.html)

---

<a id="english"></a>
# Timaro Support

Questions, problems or ideas? Email **[support@ivelo.app](mailto:support@ivelo.app)** or open an [issue on GitHub](https://github.com/jerryMittich/time-clock/issues).

Please include your iPhone model, iOS version, Timaro version (Settings → Version) and a short description of what happened.

## FAQ

**Automatic clock-in/out doesn't work.**
- Settings → Timaro → Location: turn on **Always** and **Precise Location**.
- Make sure "Clock in/out automatically" is on for the workplace.
- Use a radius of at least 150 m. iOS detects smaller radii unreliably.
- iOS sometimes reports arriving or leaving a few minutes late. This is normal.
- Low Power Mode can delay these events.

**I step out at lunch. Does a new shift start?**
No. If you come back within the configured time (Settings → "Resume shift if back within"), the same shift continues.

**How do I back up my data?**
Your data stays on your iPhone and is included in your iCloud or computer backup. You can also create a CSV export at any time.

**How do I import data from another time-clock app?**
Settings → Import times (CSV). Timaro expects daily totals in the format `Datum;Stunden;Sollstunden;Überstunden;Pause;Abwesenheitstyp`. Absence days are skipped, and days that already have shifts are left alone.

**The widget shows old data.**
Open Timaro briefly. iOS refreshes widgets on its own schedule.

**How do I delete all my data?**
Deleting the app removes all its data.

Privacy: [Privacy policy](privacy.html#english)
