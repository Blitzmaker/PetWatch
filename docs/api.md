# DogWatch API

Base URL: `http://localhost:3000`

Authenticated endpoints require `Authorization: Bearer <accessToken>`.

## Auth
- POST `/auth/register`
- POST `/auth/login`
- POST `/auth/refresh`
- POST `/auth/logout`

## Dogs
- GET `/dogs`
- POST `/dogs`
- GET `/dogs/:id`
- PATCH `/dogs/:id`

## Weights
- GET `/dogs/:dogId/weights`
- POST `/dogs/:dogId/weights`
- DELETE `/weights/:id`

## Activities
- GET `/activities/search?q=:query` (durchsuchbare Activity-Stammdaten, gepflegt durch Administration in Directus)
- GET `/dogs/:dogId/activities`
- POST `/dogs/:dogId/activities`
- DELETE `/activities/:id`

## Foods
- GET `/foods/by-barcode/:barcode` (nur öffentlich freigegebene oder eigene lokale Foods)
- GET `/foods/search?q=:query` (Suche in Barcode und Name; maximal 6 Treffer für UI-Hinweis)
- POST `/foods`

## Meals
- GET `/dogs/:dogId/meals`
- POST `/dogs/:dogId/meals`
- POST `/dogs/:dogId/meals/from-recipe`
- GET `/meals/:id`
- DELETE `/meals/:id`

## Recipes
- GET `/recipes`
- POST `/recipes`
- GET `/recipes/:id`
- PATCH `/recipes/:id`
- DELETE `/recipes/:id`

## Admin
- GET `/admin/users`
- PATCH `/admin/users/:id`
- DELETE `/admin/users/:id`
- GET `/admin/dogs`
- GET `/admin/foods`
- PATCH `/admin/foods/:id/review`
- GET `/admin/cms/categories`
- POST `/admin/cms/categories`
- GET `/admin/cms/posts`
- POST `/admin/cms/posts`
- GET `/admin/community/topics`
- POST `/admin/community/topics`
- GET `/admin/community/threads`
- POST `/admin/community/threads`
- GET `/admin/community/threads/:threadId/posts`
- POST `/admin/community/posts`


### Food payload
`POST /foods` erwartet jetzt folgende Nährwertfelder:
- `kcalPer100g` (`integer`)
- `proteinPercent` (`number`, optional, 0-100)
- `fatPercent` (`number`, optional, 0-100)
- `crudeAshPercent` (`number`, optional, 0-100)
- `crudeFiberPercent` (`number`, optional, 0-100)

### Activity payload
`POST /dogs/:dogId/activities` erwartet folgende Felder:
- `activityId` (`string`)
- `durationMinutes` (`integer`, > 0)
- `performedAt` (`ISO datetime`)

Die verbrannten kcal werden serverseitig berechnet mit `kcalPerMinute × durationMinutes × (GewichtKg / 10)^0.7`. Als Gewicht wird das zuletzt erfasste Hundegewicht verwendet, ansonsten das Zielgewicht oder 10 kg als Fallback.
