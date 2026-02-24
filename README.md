# DogWatch Monorepo

DogWatch ist eine Mobile App zum Tracking von Hundegewicht, Futter und Mahlzeiten.

## Struktur

- `apps/mobile` – Flutter App
- `services/api` – NestJS API + Prisma
- `infra/docker-compose.yml` – lokale PostgreSQL
- `docs/api.md` – API Überblick

## Lokaler Start

```bash
docker compose -f infra/docker-compose.yml up -d
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
