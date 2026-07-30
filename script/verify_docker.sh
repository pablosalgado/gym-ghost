#!/usr/bin/env bash
set -euo pipefail

project_name="gym-ghost-smoke"
export HOST_PORT="${HOST_PORT:-3001}"
export APP_HOSTS="${APP_HOSTS:-smoke.gym-ghost.test}"
export SECRET_KEY_BASE="${SECRET_KEY_BASE:-ci-smoke-test-secret}"
export ATTR_ENCRYPTED_KEY="${ATTR_ENCRYPTED_KEY:-ci-smoke-test-encryption-key-32!}"

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

for _ in $(seq 1 30); do
  if curl --fail --silent --header "Host: ${APP_HOSTS}" \
      "http://127.0.0.1:${HOST_PORT}/up" >/dev/null; then
    docker compose --project-name "$project_name" exec --no-TTY web sh -c '
      process_uid=$(awk "/^Uid:/ { print \$2 }" /proc/1/status)
      test "$process_uid" = "$(id -u app)"
    '
    exit 0
  fi

  sleep 1
done

echo "Docker smoke test did not become healthy within 30 seconds." >&2
exit 1
