#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${1:-infra/.env}"
COMPOSE_BASE="infra/docker-compose.yml"
COMPOSE_ADMIN="infra/docker-compose.admin.yml"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Env-Datei nicht gefunden: $ENV_FILE" >&2
  exit 1
fi

# FLARUM_SITE_URL aus der Env-Datei laden
FLARUM_SITE_URL="$(awk -F= '/^FLARUM_SITE_URL=/{print substr($0,index($0,$2)); exit}' "$ENV_FILE")"

if [[ -z "${FLARUM_SITE_URL}" ]]; then
  echo "FLARUM_SITE_URL ist nicht gesetzt in $ENV_FILE" >&2
  exit 1
fi

echo "Setze Flarum-URL auf: $FLARUM_SITE_URL"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_BASE" -f "$COMPOSE_ADMIN" exec -T flarum php flarum config:set url "$FLARUM_SITE_URL"

echo "Leere Flarum-Cache"
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_BASE" -f "$COMPOSE_ADMIN" exec -T flarum php flarum cache:clear

echo "Fertig. Falls nötig Browser-Hard-Refresh (Ctrl+F5) ausführen."
