#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

: "${HA_PORT:?}"

BASE="http://localhost:${HA_PORT}"
CLIENT_ID="${BASE}/"
REDIRECT_URI="${BASE}/?auth_callback=1"

ONBOARD_NAME="E2E Admin"
ONBOARD_USERNAME="admin"
ONBOARD_PASSWORD="admin"

wait_for_onboarding_api() {
    local timeout="$1" waited=0
    while [ "${waited}" -lt "${timeout}" ]; do
        if curl -sf "${BASE}/api/onboarding" >/dev/null 2>&1; then
            return 0
        fi
        sleep 3
        waited=$((waited + 3))
    done
    return 1
}

echo "Waiting for Home Assistant onboarding API..."
if ! wait_for_onboarding_api 180; then
    echo "Home Assistant did not come up in time; skipping onboarding bootstrap." >&2
    exit 1
fi

STATUS=$(curl -sf "${BASE}/api/onboarding")
if [ "$(echo "${STATUS}" | jq -r '[.[] | .done] | all')" = "true" ]; then
    echo "Onboarding already complete, nothing to do."
    exit 0
fi

echo "Creating admin user..."
USER_RESP=$(curl -sf -X POST "${BASE}/api/onboarding/users" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg name "${ONBOARD_NAME}" --arg username "${ONBOARD_USERNAME}" \
             --arg password "${ONBOARD_PASSWORD}" --arg client_id "${CLIENT_ID}" \
             '{name: $name, username: $username, password: $password, client_id: $client_id, language: "en"}')")
AUTH_CODE=$(echo "${USER_RESP}" | jq -r '.auth_code')

echo "Exchanging auth code for an access token..."
TOKEN_RESP=$(curl -sf -X POST "${BASE}/auth/token" \
    --data-urlencode "grant_type=authorization_code" \
    --data-urlencode "code=${AUTH_CODE}" \
    --data-urlencode "client_id=${CLIENT_ID}")
ACCESS_TOKEN=$(echo "${TOKEN_RESP}" | jq -r '.access_token')

AUTH_HEADER="Authorization: Bearer ${ACCESS_TOKEN}"

echo "Finishing core_config step..."
curl -sf -X POST "${BASE}/api/onboarding/core_config" -H "${AUTH_HEADER}" >/dev/null

echo "Finishing analytics step..."
curl -sf -X POST "${BASE}/api/onboarding/analytics" -H "${AUTH_HEADER}" >/dev/null

echo "Finishing integration step..."
curl -sf -X POST "${BASE}/api/onboarding/integration" \
    -H "${AUTH_HEADER}" -H "Content-Type: application/json" \
    -d "$(jq -n --arg client_id "${CLIENT_ID}" --arg redirect_uri "${REDIRECT_URI}" \
             '{client_id: $client_id, redirect_uri: $redirect_uri}')" >/dev/null

echo "Onboarding complete. Admin login: ${ONBOARD_USERNAME} / ${ONBOARD_PASSWORD}"
