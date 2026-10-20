# Hinweise für den Claude-Agenten

Antworte und kommentiere auf Deutsch.

## Projekt
Migrationskalkulator Fachverfahren: eine einzelne Datei `index.html` (HTML, CSS, JavaScript ohne Build-Schritt),
veröffentlicht über GitHub Pages. Daten liegen in Supabase (Region Frankfurt), Schema unter `supabase/migrations/`.

- Routing über Hash: `#start` (Startseite mit allen Kommunen), `#k-<id>` (Rechner einer Kommune).
- Speichermodi in `MODE`: `db` (Supabase), `local`, `auth`, `load`. Schreiben läuft über `queueWrite` / `flushWrite` / `save`.
- Kommune: `state = {B, n, rows, ts, note}`. Fachverfahren (Zeile): `{name, form, b, mb, n, inc, note, s[10], ti{…}, tc{…}, ist, cloud}`.
- Berechnung: Gewichte `[.30,.12,.12,.08,.06,.07,.08,.10,.04,.03]`, Aufschläge `[1,1.5,2.5,4]`;
  `M = mb·AUFS`, `net = d − M/n`, Amortisation `T = M/d`. Nur Verfahren mit `inc !== false` zählen in die Summen.
- Bestehendes Design (Farbe `#03676A`, Info-Dreiecke mit Erklärungen, Kacheln) beibehalten.

## Regeln (verbindlich)
- Niemals E-Mail-Adressen, Zugangslinks/Link-Tokens, API-Schlüssel oder den Supabase-`service_role`-Schlüssel ins Repository schreiben.
- Schemaänderungen nur als neue Migrationsdatei in `supabase/migrations/` (Zeitstempel-Präfix), nie bestehende Migrationen ändern.
  RLS muss auf allen Tabellen aktiv bleiben.
- Änderungen immer als Pull Request, nicht direkt auf `main`. Im PR kurz beschreiben, was sich für Nutzer ändert.
- Nach Änderungen an `index.html` prüfen, dass die Seite ohne Konsolenfehler lädt und `README.md` noch stimmt.
