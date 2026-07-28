#!/bin/bash
set -e

# Re-deploy data to an existing Crafty server
# Usage: deploy.sh <server_id>
# If no server_id given, lists available servers

CRAFTY_URL="${CRAFTY_URL:-http://localhost:8000}"
CRAFTY_USER="${CRAFTY_USER:-admin}"
CRAFTY_PASS="123456789"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

red() { echo -e "\033[31m$*\033[0m"; }
green() { echo -e "\033[32m$*\033[0m"; }
yellow() { echo -e "\033[33m$*\033[0m"; }

if ! curl -sf "$CRAFTY_URL/api/v2/crafty/check" > /dev/null 2>&1; then
  red "Crafty nao esta rodando em $CRAFTY_URL"
  exit 1
fi

LOGIN_RESP=$(curl -sf -X POST "$CRAFTY_URL/api/v2/auth/login" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$CRAFTY_USER\", \"password\": \"$CRAFTY_PASS\"}")
TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])" 2>/dev/null)

if [ -z "$1" ]; then
  yellow "Servidores disponiveis:"
  curl -sf -X GET "$CRAFTY_URL/api/v2/servers" \
    -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
for s in json.load(sys.stdin).get('data', []):
    print(f\"  {s['server_id']} | {s['server_name']}\")
" 2>/dev/null
  echo ""
  read -p "Digite o Server ID: " SERVER_ID
else
  SERVER_ID="$1"
fi

SERVER_DIR="/crafty/servers/$SERVER_ID/server"
if [ ! -d "$SERVER_DIR" ]; then
  red "Diretorio $SERVER_DIR nao encontrado"
  exit 1
fi

green "Implantando dados em $SERVER_DIR..."

mkdir -p "$SERVER_DIR/plugins"
cp -r "$REPO_DIR/server/plugins/"*.jar "$SERVER_DIR/plugins/" 2>/dev/null || true
cp -r "$REPO_DIR/server/plugins-config/"* "$SERVER_DIR/plugins/" 2>/dev/null || true
cp "$REPO_DIR/server/server.properties" "$SERVER_DIR/" 2>/dev/null || true

for w in "$REPO_DIR/server/worlds/"*.zip; do
  [ -f "$w" ] && unzip -qo "$w" -d "$SERVER_DIR/" && green "  $(basename $w)"
done

echo "eula=true" > "$SERVER_DIR/eula.txt"
chmod +x "$SERVER_DIR/"*.jar 2>/dev/null || true

green "Deploy concluido! Reinicie o servidor no painel Crafty: $CRAFTY_URL"
