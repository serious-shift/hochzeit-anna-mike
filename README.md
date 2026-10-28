# Hochzeit Webseite: Backend-Setup fuer GitHub Pages mit Supabase

## Architektur
Diese Seite bleibt statisch auf GitHub Pages (nur HTML/CSS/JS). Das RSVP-Formular sendet Daten direkt aus dem Browser an Supabase (Postgres) ueber die Supabase JS Library.

Wichtige Punkte:
- Kein eigener Server notwendig.
- Schreibzugriff erfolgt nur per INSERT auf eine einzelne Tabelle.
- Zugriff wird durch Row Level Security (RLS) und gezielte Policies eingeschraenkt.

## 1) Supabase Projekt anlegen
1. Auf supabase.com ein neues Projekt erstellen.
2. In Project Settings -> API folgende Werte notieren:
- Project URL
- anon/public key
3. Niemals den service_role key im Frontend verwenden.

## 2) Datenbank-Schema und Policies ausfuehren
1. Im Supabase Dashboard SQL Editor oeffnen.
2. Den Inhalt aus supabase/schema.sql komplett ausfuehren.
3. Pruefen, dass Tabelle public.rsvp_responses vorhanden ist.

Die SQL richtet ein:
- Tabelle fuer RSVP-Daten
- Validierungs-Checks (z. B. Name, E-Mail, Plus-One-Konsistenz)
- Indizes auf created_at und lower(email)
- RLS aktiviert
- INSERT-Policy fuer Rolle anon
- SELECT-Policy fuer Rolle authenticated
- Anon SELECT bleibt verboten
- Authenticated UPDATE/DELETE bleiben verboten

## 3) Frontend-Konfiguration hinterlegen
Die Seiten lesen Konfiguration aus window.SUPABASE_CONFIG. Ohne Konfiguration bleiben Platzhalter aktiv und die Seite zeigt einen Fehler.

Empfohlene Einbindung in index.html und admin.html (vor dem Hauptskript):

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

## 4) Admin Dashboard (minimal auth variant)
Die Datei admin.html ist eine oeffentliche URL, aber die Datenansicht ist nur nach Login sichtbar.

### Was admin.html macht
- Login mit Supabase Auth (E-Mail und Passwort) via signInWithPassword
- Session-Check beim Laden via auth.getSession
- Live-Reaktion auf Login und Logout via auth.onAuthStateChange
- Laden der RSVPs nur fuer eingeloggte Nutzer
- KPI-Karten (total, attending, declined)
- Suche nach Name/E-Mail, Statusfilter (all, attending, declined)
- Tabellenansicht mit CSV-Export der aktuell gefilterten Zeilen

### Supabase Auth Setup
1. Im Supabase Dashboard Authentication -> Providers den Email Provider aktivieren.
2. In Authentication -> Settings oeffentliche Registrierungen deaktivieren (disable public signups).
3. Einen Admin Benutzer manuell anlegen (Authentication -> Users -> Invite/Create user).

### SQL Anforderung fuer Dashboard
Damit admin.html lesen kann, muss in supabase/schema.sql die SELECT Policy fuer authenticated aktiv sein:
- Policy Name: rsvp_responses_authenticated_select
- for select to authenticated using (true)

Gleichzeitig bleibt:
- anon nur INSERT
- anon SELECT verboten
- authenticated UPDATE/DELETE verboten

### Test-Checkliste fuer Admin Dashboard
1. admin.html laden ohne Login: Tabelle ist nicht sichtbar.
2. Mit falschen Credentials einloggen: klare Fehlermeldung.
3. Mit Admin User einloggen: Tabelle und KPIs werden geladen.
4. Suche und Statusfilter pruefen: Zeilen und KPIs reagieren client-side.
5. CSV Export pruefen: enthaelt nur die aktuell gefilterten Zeilen.
6. Logout pruefen: Dashboard wird wieder verborgen.

### Security Boundaries
- Frontend nutzt nur den anon key.
- Kein service_role key im Frontend.
- Lesen ist an Supabase Session und Rolle authenticated gebunden.
- Diese Variante ist minimal und client-side. Fuer strengere Trennung spaeter optional API/Edge Function davor setzen.

## 5) Deploy auf GitHub Pages
1. Aenderungen committen und nach GitHub pushen.
2. GitHub Pages fuer das Repository aktivieren.
3. Sicherstellen, dass die Konfiguration (window.SUPABASE_CONFIG) in der produktiven Seite enthalten ist.
4. Live testen.

## 6) RSVP Test-Checkliste
- Formular laesst sich absenden (Zusagen und Absagen).
- Erfolgsmeldung/Modal erscheint wie gewohnt.
- Datensatz erscheint in Supabase Tabelle public.rsvp_responses.
- Plus-One-Validierung funktioniert.
- Mehrsprachigkeit und bestehende UI-Interaktionen bleiben unveraendert.

## Hauefige Fehler und Loesungen
- RLS denied / permission denied / row-level security:
  Policy fehlt oder ist falsch. schema.sql erneut ausfuehren und Policy pruefen.
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
