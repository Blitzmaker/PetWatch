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
