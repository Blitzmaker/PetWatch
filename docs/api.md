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
- GET `/foods/by-barcode/:barcode`
- POST `/foods`

## Meals
- GET `/dogs/:dogId/meals`
- POST `/dogs/:dogId/meals`
- GET `/meals/:id`
- DELETE `/meals/:id`
