#!/usr/bin/env bash
# Checks that every AntCloud API route these apps use still exists, and whether AntCloud has shipped a
# newer Windows client than the one the apps match. Uses fake data only: no account, no SMS, no cloud PC.
#
# A route AntCloud removed answers Express's "Cannot GET /api/…" 404; any other answer (401 wrong
# password, 400 validation, 403, 500 because no cloud PC is running) means the route is still there.
# Exits 1 and prints a Markdown report when something changed. Run by .github/workflows/antcloud-api-watch.yml.
set -uo pipefail

cd "$(dirname "$0")/.."
API=https://api.antcloud.co/api
# Config.appVersion 0.<AntCloud release>.<ours>: 0.16.x matches AntCloud's Windows client 0.016.
APP_VERSION=$(sed -nE 's/.*static let appVersion = "([0-9.]+)".*/\1/p' Sources/Shared/Config.swift)
MATCHED=$(echo "$APP_VERSION" | awk -F. '{ printf "%.3f", $2 / 1000 }')
FAKE_AUTH="Authorization: JWT not-a-real-token"

# method | path | JSON body | extra header | what the apps use it for
ROUTES=(
  "POST|login|{\"user\":\"api-check@example.com\",\"auth\":\"x\"}||Email sign-in"
  "POST|phoneNumber/otp|{}||Send phone code"
  "POST|phoneLogin|{\"mobile\":\"+910000000000\",\"verificationToken\":\"000000\"}||Phone sign-in"
  "POST|users/forgot-password|{}||Forgot password"
  "GET|users/refreshToken||refresh: JWT not-a-real-token|Stay signed in"
  "GET|myself||$FAKE_AUTH|Profile and plan"
  "GET|vm/getControllVmIp||$FAKE_AUTH|Cloud PC address"
  "GET|vm/checkVmConnectionStatus||$FAKE_AUTH|Moonlight connection status"
  "POST|vm/vmAuthentication|{\"code\":\"0000\"}|$FAKE_AUTH|Pairing PIN"
  "GET|realtime|||Server clock"
  "GET|windows/version|||Windows client version"
)

problems=()
rows=()
unanswered=0
for route in "${ROUTES[@]}"; do
  IFS='|' read -r method path body header what <<<"$route"
  args=(-s -o /tmp/antcloud-check-body -w '%{http_code}' -X "$method" "$API/$path" --max-time 20 -H 'Content-Type: application/json')
  [[ -n "$body" ]] && args+=(-d "$body")
  [[ -n "$header" ]] && args+=(-H "$header")
  # curl prints 000 itself when it can't connect, so no fallback (one used to make it 000000).
  code=$(curl "${args[@]}" 2>/dev/null)
  [[ "$code" =~ ^[0-9]{3}$ ]] || code=000
  if [[ "$code" == 404 ]] && grep -q "<pre>Cannot $method /api/" /tmp/antcloud-check-body; then
    rows+=("| \`$method $path\` | $what | ❌ gone (404) |")
    problems+=("\`$method $path\` ($what) no longer exists.")
  elif [[ "$code" == 000 ]]; then
    rows+=("| \`$method $path\` | $what | ⚠️ no answer |")
    unanswered=$((unanswered + 1))
  else
    rows+=("| \`$method $path\` | $what | ✅ $code |")
  fi
done
rm -f /tmp/antcloud-check-body

# Most routes silent means AntCloud is down or blocking this machine; either way the check proved nothing.
if ((unanswered * 2 > ${#ROUTES[@]})); then
  problems+=("$unanswered of ${#ROUTES[@]} routes didn't answer at all: AntCloud may be down, or blocking this machine.")
fi

latest=$(curl -s --max-time 20 "$API/windows/version" | sed -nE 's/.*"version":"?([0-9.]+).*/\1/p')
if [[ -n "$latest" && -n "$MATCHED" ]] && awk -v a="$latest" -v b="$MATCHED" 'BEGIN { exit !(a > b + 0.0001) }'; then
  problems+=("AntCloud's Windows client is now **$latest**; the apps match **$MATCHED**. Their 0.016 release renamed every API route, so check the new client (\`https://download.antcloud.co/Antcloudpc.msi\`) for changes.")
fi

echo "## AntCloud API check"
echo
echo "Windows client: latest **${latest:-unknown}**, apps match **${MATCHED:-unknown}**."
echo
echo "| Route | Used for | Result |"
echo "|---|---|---|"
printf '%s\n' "${rows[@]}"
echo
if ((${#problems[@]})); then
  echo "### Needs attention"
  printf -- '- %s\n' "${problems[@]}"
  echo
  echo "The full map of routes is in \`re/FINDINGS.md\` (local) and \`Sources/Shared/API/APIClient.swift\`."
  exit 1
fi
echo "All routes answer and the client version is unchanged."
