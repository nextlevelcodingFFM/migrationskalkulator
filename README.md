# Migrationskalkulator Fachverfahren

Webbasierter Kalkulator zur Vorbereitung der Migration von Fachverfahren (On-Premises, andere Cloud, Client-Server) auf eine einheitliche Cloud-Plattform.

## Funktionen

- **Kommunen:** Startseite mit beliebig vielen Kommunen. Jede Kommune hat eine eigene Kalkulation mit eigenen Fachverfahren, Einwohnerzahl und Annahmen. Die Übersicht zeigt je Kommune Kosten pro Bürger, Netto-Ersparnis, laufende Ersparnis und Migrationskosten.
- **Schwierigkeitsfaktor (SF 1,0–5,0):** gewichteter Mittelwert aus zehn Kriterien, jeweils mit 1 bis 5 bewertet, mit Erläuterung zu jedem Kriterium.
- **Einstufung und Aufschlag:** gering (× 1,0), mittel (× 1,5), hoch (× 2,5), sehr hoch (× 4,0) auf den Basis-Migrationsaufwand.
- **TCO heute und in der Cloud:** Aufbau aus einzelnen Kostenblöcken (Hardware, Rechenzentrum, Lizenzen, Personal, Client, Netz bzw. Rechenleistung, Speicher, Backup, Plattformumlage).
- **Kosten pro Bürger:** heute und nach Migration, Netto-Ersparnis nach Abzug der verteilten Migrationskosten, Amortisationsdauer.
- **Empfehlung:** Migrationsreihenfolge oder Prüfung von SaaS, Weiterbetrieb oder Ablösung.
- **Export:** Tabelle als CSV in die Zwischenablage kopieren und in Excel einfügen.

## Nutzung

`index.html` im Browser öffnen. Es ist keine Installation und kein Server nötig. Eingaben werden je Kommune getrennt lokal im Browser gespeichert (localStorage). Andere Geräte und Personen sehen sie nicht. Ein Link der Form `index.html#k-<id>` öffnet direkt die Kalkulation einer Kommune.

Über GitHub Pages (Settings → Pages → Branch `main`) lässt sich der Kalkulator auch als Webseite bereitstellen. Bei einem privaten Repository hängt das vom GitHub-Tarif ab.

## Formeln

```
SF       = Σ (Gewicht_i × Bewertung_i)
M        = Migration Basis × Aufschlag(SF)
K Ist    = TCO Ist / Bürger
K Cloud  = TCO Cloud / Bürger
E netto  = (TCO Ist − TCO Cloud − M / n) / Bürger
T Amort  = M / (TCO Ist − TCO Cloud)
```

## Hinweis

Die vorbelegten Verfahren, Kosten, Gewichte und Aufschläge sind fiktive Richtwerte. Sie sind durch eigene Daten zu ersetzen und nach den ersten Pilotmigrationen zu kalibrieren.
