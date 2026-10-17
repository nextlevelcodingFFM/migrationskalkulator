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
- **Farbschema:** weißer Hintergrund mit Dunkelblau, Teal, Oliv, Grün, Weinrot und Grautönen.

## Nutzung

`index.html` im Browser öffnen. Es ist keine Installation und kein Server nötig.

**Speicherung:** Die Webseite auf GitHub Pages speichert die Kommunen in einer Supabase-Datenbank (Rechenzentrum Frankfurt). Zugriff haben nur freigeschaltete Personen nach Anmeldung per E-Mail-Link; die Daten bleiben erhalten, auch wenn der Browser-Cache gelöscht wird. Ist keine Datenbank eingetragen oder nicht erreichbar, speichert die Seite nur im jeweiligen Browser (localStorage). In der Claude-Version des Kalkulators liegen die Kommunen in einer eigenen, davon getrennten Datenbank. Die Seite erkennt die Betriebsart automatisch und zeigt sie auf der Startseite an.

Ein Link der Form `index.html#k-<id>` öffnet direkt die Kalkulation einer Kommune.

Über GitHub Pages (Settings → Pages → Branch `main`) lässt sich der Kalkulator auch als Webseite bereitstellen. Bei einem privaten Repository hängt das vom GitHub-Tarif ab.

## Datenbank (Supabase) einrichten

Die öffentliche Webseite kann eine eigene Supabase-Datenbank nutzen. Dann sind die Kommunen dauerhaft und gemeinsam gespeichert, und nur freigeschaltete Personen haben nach Anmeldung per E-Mail-Link Zugriff.

1. In Supabase ein Projekt anlegen (Region Frankfurt, `eu-central-1`).
2. Im Dashboard unter **SQL Editor** den Inhalt von `supabase/migrations/20261017000000_kommunen.sql` ausführen.
3. Personen freischalten, je Adresse: `insert into public.zugelassene_nutzer (email) values ('name@kommune.de');` Diese Adressen nicht ins Repository schreiben.
4. Unter **Authentication → URL Configuration** als Site URL und Redirect URL die Adresse der Webseite eintragen, z. B. `https://nextlevelcodingffm.github.io/migrationskalkulator/`.
5. In `index.html` die Werte `SUPABASE_URL` (Project URL) und `SUPABASE_ANON_KEY` (anon public key) eintragen. Beide dürfen öffentlich sein. Den `service_role`-Key niemals eintragen.

Ohne diese Werte speichert die Webseite nur im Browser.

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
