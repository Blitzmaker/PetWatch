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

## Foods
- GET `/foods/by-barcode/:barcode` (nur öffentlich freigegebene oder eigene lokale Foods)
- GET `/foods/search?q=:query` (Suche in Barcode und Name; maximal 6 Treffer für UI-Hinweis)
- POST `/foods`

## Meals
- GET `/dogs/:dogId/meals`
- POST `/dogs/:dogId/meals`
- GET `/meals/:id`
- DELETE `/meals/:id`

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
