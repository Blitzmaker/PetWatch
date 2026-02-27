# PetWatch Monorepo

PetWatch ist eine Flutter-App zum Tracking von Hundegewicht, Futter und Mahlzeiten.

## Projektstruktur

- `apps/mobile` – Flutter Mobile App
- `services/api` – NestJS API + Prisma
- `infra/docker-compose.yml` – Docker-Setup für PostgreSQL + API
- `docs/api.md` – API Überblick

---

## Ziel-Setup: Android-App ↔ Homeserver (Ubuntu) ↔ PostgreSQL

Du kannst die komplette Backend-Seite (API + Datenbank) auf deinem Homeserver laufen lassen
und dann vom Android Handy über WLAN auf die API zugreifen.

### Netz-Plan

- Homeserver (Ubuntu): `192.168.178.105`
- API läuft in Docker auf Port `3000`
- PostgreSQL läuft in Docker auf Port `5432`
- Android App nutzt als API-URL: `http://192.168.178.105:3000`

> Wichtig: Handy und Homeserver müssen im selben Netzwerk sein (oder per VPN verbunden).

---

## 1) Installation auf dem Homeserver (Ubuntu + Docker)

### 1.1 Docker & Compose Plugin installieren

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

(Optional) Docker ohne `sudo`:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

### 1.2 Repository auf den Homeserver kopieren

```bash
git clone <DEIN_REPO_URL> PetWatch
cd PetWatch
```

### 1.3 Docker-Umgebungsvariablen setzen

```bash
cp infra/.env.example infra/.env
nano infra/.env
```

Passe mindestens diese Werte an:

- `POSTGRES_PASSWORD`
- `JWT_ACCESS_SECRET`
- `JWT_REFRESH_SECRET`

### 1.4 Container starten

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml up -d --build
```

Beim Start führt die API automatisch Prisma-Migrationen aus (`prisma migrate deploy`).

> Wichtig: `POSTGRES_USER` nur vor dem **allerersten** Start setzen. Wenn du ihn später änderst,
> bleiben alte Daten im Docker-Volume und PostgreSQL kennt den neuen User nicht automatisch.

### 1.5 Funktion prüfen

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml ps
docker compose --env-file infra/.env -f infra/docker-compose.yml logs -f api
```

Wenn alles läuft, sollte die API im LAN unter folgendem Endpunkt erreichbar sein:

- `http://192.168.178.105:3000`

### 1.6 Firewall-Freigabe (falls UFW aktiv)

```bash
sudo ufw allow 3000/tcp
sudo ufw allow 5432/tcp
```

> Für mehr Sicherheit kannst du Port `5432` später auf interne Docker-Nutzung begrenzen.

---

## 2) Flutter-App auf Android gegen den Homeserver bauen

Die App verwendet jetzt eine konfigurierbare API-URL per `--dart-define`.

### 2.1 Auf Entwicklungsrechner

```bash
cd apps/mobile
flutter pub get
```

### 2.2 Auf echtes Android-Gerät installieren

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.178.105:3000
```

Damit verbindet sich die App direkt mit deiner API auf dem Homeserver.

---

## 3) Lokale Entwicklung (weiterhin möglich)

Für lokale API-Entwicklung (ohne Homeserver) kannst du weiterhin klassisch arbeiten:

```bash
cp services/api/.env.example services/api/.env
cd services/api
npm install
npx prisma migrate dev
npm run start:dev
```

In diesem Fall kann die Flutter App wie bisher mit Emulator-Default laufen (`10.0.2.2`).

---

## 4) Betrieb / Updates auf dem Homeserver

Nach Code-Änderungen:

```bash
git pull
docker compose --env-file infra/.env -f infra/docker-compose.yml up -d --build
```

Logs prüfen:

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml logs -f
```

Stoppen:

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml down
```

## Troubleshooting

### Fehler: `FATAL: role "blitzmaker" does not exist`

Ursache: Der Postgres-Daten-Volume wurde schon früher mit einem anderen `POSTGRES_USER` initialisiert
(z. B. `postgres`). Wenn du später in `infra/.env` auf `blitzmaker` wechselst, wird der User im
bestehenden Volume **nicht nachträglich** angelegt.

#### Option A (einfach, Daten werden gelöscht)

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml down -v
docker compose --env-file infra/.env -f infra/docker-compose.yml up -d --build
```

Damit wird die Datenbank mit den aktuellen `.env`-Werten neu initialisiert.

#### Option B (Daten behalten, User manuell anlegen)

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml exec postgres psql -U postgres -d postgres
```

Dann in `psql` (Beispiel):

```sql
CREATE ROLE blitzmaker LOGIN PASSWORD 'DEIN_PASSWORT';
ALTER DATABASE dogwatch OWNER TO blitzmaker;
GRANT ALL PRIVILEGES ON DATABASE dogwatch TO blitzmaker;
\q
```

Danach API neu starten:

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml restart api
```

### Fehler: `@prisma/client did not initialize yet`

Ursache: Das API-Container-Image wurde mit einer älteren Dockerfile-Version gebaut, bei der der
generierte Prisma-Client nicht im Runtime-Layer gelandet ist. Dann startet Nest, aber Prisma kann
beim Import nicht initialisieren.

Beheben:

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml build --no-cache api
docker compose --env-file infra/.env -f infra/docker-compose.yml up -d
docker compose --env-file infra/.env -f infra/docker-compose.yml logs -f api
```

Wenn der Fehler weg ist, funktionieren Registrierung und Login in der Flutter-App wieder.

### Fehler: Prisma/OpenSSL im API-Container

Wenn im Log `Prisma failed to detect the libssl/openssl version` erscheint, nutze die aktuelle
Version mit neuem API-Image (dieses Repo nutzt jetzt `node:20-bookworm-slim` + OpenSSL):

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml build --no-cache api
docker compose --env-file infra/.env -f infra/docker-compose.yml up -d
```

---


## 5) Vollintegriertes Admin-Backend als zusätzlicher Docker-Stack

Für dein gewünschtes vollständiges Admin-Backend sind jetzt integriert:

- `infra/docker-compose.admin.yml` (Directus + Strapi + Flarum)
- `docs/admin-backend-konzept.md` (Gesamtkonzept)
- erweiterte API-/DB-Modelle für Usermanagement, Food-Review, CMS, Community

### 5.1 Konfigurationsdatei erweitern

Ergänze in `infra/.env` zusätzlich:

```env
DIRECTUS_KEY=change-me
DIRECTUS_SECRET=change-me
DIRECTUS_ADMIN_EMAIL=admin@petwatch.local
DIRECTUS_ADMIN_PASSWORD=change-me

STRAPI_DB_NAME=strapi
STRAPI_DB_USER=strapi
STRAPI_DB_PASSWORD=change-me
STRAPI_JWT_SECRET=change-me
STRAPI_ADMIN_JWT_SECRET=change-me
STRAPI_APP_KEYS=change-me-1,change-me-2,change-me-3,change-me-4
STRAPI_API_TOKEN_SALT=change-me
STRAPI_TRANSFER_TOKEN_SALT=change-me

FLARUM_DB_NAME=flarum
FLARUM_DB_USER=flarum
FLARUM_DB_PASSWORD=change-me
FLARUM_DB_ROOT_PASSWORD=change-me
FLARUM_SITE_URL=http://192.168.178.105:8080
FLARUM_TITLE=PetWatch Community
```

### 5.2 Alles gemeinsam starten

```bash
docker compose --env-file infra/.env -f infra/docker-compose.yml -f infra/docker-compose.admin.yml up -d --build
```

### 5.3 Admin-/CMS-/Community-Ports

- API: `3000`
- Directus: `8055`
- Strapi: `1337`
- Flarum: `8080`

> Empfehlung: Veröffentlichung nur hinter Reverse Proxy mit HTTPS + IP-Restriktion.
