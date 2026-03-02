# Admin-Backend (Webapp) – Vollintegriertes Zielbild

Dieses Dokument beschreibt die vollständig integrierte Admin-Lösung für PetWatch auf dem Ubuntu-HomeServer.

## Enthaltene Funktionsbereiche

- **Usermanagement**
  - User bearbeiten
  - Passwörter zurücksetzen
  - User sperren/entsperren
  - User soft-löschen
- **Hunde-Verwaltung**
  - Übersicht aller Hunde inkl. Zuordnung zum User
  - Datensatzpflege
- **Nahrungsmittel-Datenbank mit EAN und Nährwerten**
  - EAN-Pflege
  - Nährwertfelder
  - Status-Workflow für Freigaben
- **CMS-System für Beiträge**
  - Beiträge, Kategorien, Veröffentlichungsstatus
  - Nutzung als News-Quelle für Mobile-App
- **Community**
  - Themenbereiche
  - Threads
  - Kommentare/Posts
  - Moderierbarkeit im Adminbetrieb

## Gesamtarchitektur

Die Integration besteht aus drei Ebenen, die gemeinsam laufen:

1. **Bestehende NestJS API + PostgreSQL**
   - Erweiterte Datenmodelle für Rollen, Food-Review, CMS und Community.
   - Neue Admin-Endpunkte unter `/admin/*`.
2. **Directus (Web-Backoffice)**
   - Sofort nutzbare Admin-Weboberfläche zur Datenpflege.
3. **Directus + Flarum (Open-Source für CMS und Forum)**
   - Directus für redaktionelle Inhalte (Collection `cms_posts` etc.).
   - Flarum für Communitybetrieb.

Damit ist alles gleichzeitig integrierbar und in einem gemeinsamen Docker-Verbund lauffähig.

## Rollenmodell

- `ADMIN` – Vollzugriff
- `FOOD_REVIEWER` – Freigabe/Ablehnung von Nahrungsmitteln
- `CURATOR` – CMS-Verwaltung
- `MODERATOR` – Community-Moderation + Übersicht
- `USER` – Standardrolle

## Food-Review-Workflow (EAN/Nährwerte)

Statuswerte:

- `DRAFT_LOCAL`: Nur für Ersteller sichtbar
- `PENDING_REVIEW`: Zur Prüfung eingereicht
- `APPROVED_PUBLIC`: Für alle verfügbar
- `REJECTED`: Abgelehnt mit Kommentar

Ablauf:

1. Nutzer erstellt Nahrungsmittel lokal (`DRAFT_LOCAL`).
2. Datensatz wird eingereicht (`PENDING_REVIEW`).
3. Admin/Food-Reviewer prüft EAN und Nährwerte.
4. Freigabe (`APPROVED_PUBLIC`) oder Ablehnung (`REJECTED`) inkl. Kommentar.

## Sicherheitsprinzipien

- Rollenbasierte Zugriffskontrolle auf API- und Adminfunktionen.
- Gesperrte oder gelöschte User können sich nicht einloggen.
- Produktivbetrieb über HTTPS-Reverse-Proxy empfohlen.
- Regelmäßige Datenbank-Backups für PostgreSQL und MariaDB.
