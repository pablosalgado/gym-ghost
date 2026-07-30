#!/usr/bin/env bash
set -euo pipefail

project_name="gym-ghost-e2e"
export HOST_PORT="${HOST_PORT:-3001}"
export APP_HOSTS="${APP_HOSTS:-e2e.gym-ghost.test,localhost}"
export SECRET_KEY_BASE="${SECRET_KEY_BASE:-e2e-smoke-test-secret-hash-32char!!}"
export ATTR_ENCRYPTED_KEY="${ATTR_ENCRYPTED_KEY:-e2e-smoke-encryption-key-32bytes}"
export SMOKE_USER_EMAIL="${SMOKE_USER_EMAIL:-smoke-test@gymghost.test}"
export SMOKE_USER_PASSWORD="${SMOKE_USER_PASSWORD:-SmokeTest123!}"

# Partner API dummies for smoke/CI (compose requires them; sync avoided by seeds)
export PARTNER_API_BASE_URL="${PARTNER_API_BASE_URL:-http://partner.test}"
export PARTNER_BRANCHES_API_BASE_URL="${PARTNER_BRANCHES_API_BASE_URL:-http://partner.test}"
export PARTNER_BRANCHES_BRAND="${PARTNER_BRANCHES_BRAND:-TestBrand}"
export PARTNER_AUTH_TOKEN="${PARTNER_AUTH_TOKEN:-dummy-auth-token}"
export PARTNER_AUTH_ORIGIN="${PARTNER_AUTH_ORIGIN:-https://partner.example.com}"
export PARTNER_AUTH_REFERER="${PARTNER_AUTH_REFERER:-https://partner.example.com}"
export PARTNER_ACTIVITIES_TOKEN="${PARTNER_ACTIVITIES_TOKEN:-dummy-activities-token}"

cleanup() {
  status=$?

  if [ "$status" -ne 0 ]; then
    docker compose --project-name "$project_name" logs --no-color || true
  fi

  docker compose --project-name "$project_name" down --volumes || true
  exit "$status"
}
trap cleanup EXIT

docker compose --project-name "$project_name" up --build --detach

# Wait for the container to become healthy
for _ in $(seq 1 45); do
  if curl --fail --silent --header "Host: ${APP_HOSTS}" \
      "http://127.0.0.1:${HOST_PORT}/up" >/dev/null; then
    break
  fi

  sleep 1
done

# Final health check — fail if still not up
curl --fail --silent --header "Host: ${APP_HOSTS}" \
    "http://127.0.0.1:${HOST_PORT}/up" >/dev/null

# Run the Playwright e2e test
(
  cd frontend
  PLAYWRIGHT_BASE_URL="http://localhost:${HOST_PORT}" \
    SMOKE_USER_EMAIL="${SMOKE_USER_EMAIL}" \
    SMOKE_USER_PASSWORD="${SMOKE_USER_PASSWORD}" \
    npm run test:e2e
)
