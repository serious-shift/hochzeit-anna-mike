# Hochzeit Webseite: Backend-Setup fuer GitHub Pages mit Supabase

## Architektur
Diese Seite bleibt statisch auf GitHub Pages (nur HTML/CSS/JS). Das RSVP-Formular sendet Daten direkt aus dem Browser an Supabase (Postgres) ueber die Supabase JS Library.

Wichtige Punkte:
- Kein eigener Server notwendig.
- Schreibzugriff erfolgt nur per INSERT auf eine einzelne Tabelle.
- Zugriff wird durch Row Level Security (RLS) und eine gezielte Policy eingeschraenkt.

## 1) Supabase Projekt anlegen
1. Auf supabase.com ein neues Projekt erstellen.
2. In Project Settings -> API folgende Werte notieren:
- Project URL
- anon/public key
3. Niemals den service_role key im Frontend verwenden.

## 2) Datenbank-Schema und Policy ausfuehren
1. Im Supabase Dashboard SQL Editor oeffnen.
2. Den Inhalt aus supabase/schema.sql komplett ausfuehren.
3. Pruefen, dass Tabelle public.rsvp_responses vorhanden ist.

Die SQL richtet ein:
- Tabelle fuer RSVP-Daten
- Validierungs-Checks (z. B. Name, E-Mail, Plus-One-Konsistenz)
- Indizes auf created_at und lower(email)
- RLS aktiviert
- INSERT-Policy fuer Rolle anon
- SELECT/UPDATE/DELETE fuer anon und authenticated explizit entzogen

## 3) Frontend-Konfiguration hinterlegen
Die Seite liest Konfiguration aus window.SUPABASE_CONFIG. Ohne Konfiguration bleiben Platzhalter aktiv und das Formular zeigt einen Fehler.

Empfohlene Einbindung in index.html (vor dem Hauptskript):

<script>
  window.SUPABASE_CONFIG = {
    url: "https://YOUR_PROJECT_ID.supabase.co",
    anonKey: "YOUR_SUPABASE_ANON_KEY",
    table: "rsvp_responses"
  };
</script>

Alternativ kann supabase/config.example.js als Vorlage genutzt und in eine echte config.js kopiert werden.

Sicherheitsregel:
- Nur anon key im Frontend.
- service_role key niemals im Browser, niemals in GitHub Pages, niemals im Repository.

## 4) Deploy auf GitHub Pages
1. Aenderungen committen und nach GitHub pushen.
2. GitHub Pages fuer das Repository aktivieren.
3. Sicherstellen, dass die Konfiguration (window.SUPABASE_CONFIG) in der produktiven Seite enthalten ist.
4. Live testen.

## 5) Test-Checkliste
- Formular laesst sich absenden (Zusagen und Absagen).
- Erfolgsmeldung/Modal erscheint wie gewohnt.
- Datensatz erscheint in Supabase Tabelle public.rsvp_responses.
- Plus-One-Validierung funktioniert.
- Mehrsprachigkeit und bestehende UI-Interaktionen bleiben unveraendert.

## Hauefige Fehler und Loesungen
- RLS denied / permission denied / row-level security:
  INSERT-Policy fehlt oder ist falsch. schema.sql erneut ausfuehren und Policy pruefen.
- Invalid API key / unauthorized:
  Falscher anon key oder versehentlich service_role verwendet.
- Failed to fetch / Netzwerkfehler:
  Falsche Supabase URL oder Browser kann Endpoint nicht erreichen.
- relation does not exist / table not found:
  Tabellenname in Konfiguration passt nicht (table) oder SQL nicht ausgefuehrt.

## Optional spaeter: Spam-Hardening
Wenn das Formular oeffentlich viel Spam anzieht:
1. Direkten INSERT im Frontend durch eine Supabase Edge Function ersetzen.
2. Captcha (z. B. Cloudflare Turnstile oder hCaptcha) vor dem Speichern validieren.
3. In der Function Rate-Limits und zusaetzliche Eingabepruefung ergaenzen.
