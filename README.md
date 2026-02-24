# DogWatch Monorepo

DogWatch ist eine Mobile App zum Tracking von Hundegewicht, Futter und Mahlzeiten.

## Wichtiger Hinweis zu `DATABASE_URL`

Der Fehler `Environment variable not found: DATABASE_URL` kommt, wenn Prisma keine `.env` im API-Projekt findet.

Du musst die Datei **hier** anlegen:

- `services/api/.env`

Am einfachsten:

```bash
cp services/api/.env.example services/api/.env
```

Beispielwert:

```env
DATABASE_URL="postgresql://postgres:postgres@localhost:5432/dogwatch"
```

Danach `prisma`-Befehle aus `services/api` ausführen:

```bash
cd services/api
npx prisma migrate dev
```

## Struktur

- `apps/mobile` – Flutter App
- `services/api` – NestJS API + Prisma
- `infra/docker-compose.yml` – lokale PostgreSQL
- `docs/api.md` – API Überblick

## Lokaler Start

```bash
docker compose -f infra/docker-compose.yml up -d
cp services/api/.env.example services/api/.env
cd services/api
npm install
npx prisma migrate dev
npm run start:dev
```

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Backend Hinweise

- JWT Access + Refresh (Rotation)
- Refresh Token gehasht gespeichert
- Ownership Checks liefern 404
- globale ValidationPipe aktiv
