#!/bin/bash
set -e

CRAFTY_URL="${CRAFTY_URL:-http://localhost:8000}"
CRAFTY_USER="${CRAFTY_USER:-admin}"
CRAFTY_PASS="123456789"
PLAYIT_KEY="b6c8301e81335a3cb9df4a1df0b61baf5e0f42de421c4d8845b458f236e795c6"
SERVER_NAME="${SERVER_NAME:-Minecraft 1.20.1}"
SERVER_PORT=25565
MEM_MIN=1
MEM_MAX=2
CATEGORY="Mc_java_servers"
SERVER_TYPE="Paper"
SERVER_VERSION="1.20.1"
CRAFTY_DIR="${CRAFTY_DIR:-/opt/crafty}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

red() { echo -e "\033[31m$*\033[0m"; }
green() { echo -e "\033[32m$*\033[0m"; }
yellow() { echo -e "\033[33m$*\033[0m"; }

green "=== Inicializador Automatico do Servidor Minecraft ==="

ensure_crafty_running() {
  if curl -sf "$CRAFTY_URL/api/v2/crafty/check" > /dev/null 2>&1; then
    green "  Crafty ja esta rodando!"
    return 0
  fi
  yellow "  Iniciando Crafty..."
  if [ -f "$CRAFTY_DIR/run_crafty.sh" ]; then
    cd "$CRAFTY_DIR"
    nohup bash run_crafty.sh > /tmp/crafty.log 2>&1 &
    cd "$REPO_DIR"
  elif [ -f "$CRAFTY_DIR/main.py" ]; then
    cd "$CRAFTY_DIR"
    nohup python3 main.py > /tmp/crafty.log 2>&1 &
    cd "$REPO_DIR"
  elif command -v crafty &> /dev/null; then
    nohup crafty start > /tmp/crafty.log 2>&1 &
  else
    red "  ERRO: Crafty nao encontrado em $CRAFTY_DIR"
    return 1
  fi
  green "  Crafty iniciado em background (PID: $!)"
  yellow "  Log: tail -f /tmp/crafty.log"
}

wait_for_crafty() {
  yellow "  Aguardando Crafty ficar pronto..."
  for i in $(seq 1 90); do
    if curl -sf "$CRAFTY_URL/api/v2/crafty/check" > /dev/null 2>&1; then
      green "  Crafty pronto (${i}s)!"
      return 0
    fi
    sleep 2
  done
  red "  ERRO: Crafty nao respondeu apos 180s"
  red "  Ultimas linhas do log:"
  tail -30 /tmp/crafty.log 2>/dev/null || true
  return 1
}

api_login() {
  yellow "  Autenticando..."
  LOGIN_RESP=$(curl -sf -X POST "$CRAFTY_URL/api/v2/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"$CRAFTY_USER\", \"password\": \"$CRAFTY_PASS\"}")
  TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['token'])" 2>/dev/null)
  if [ -z "$TOKEN" ]; then
    red "  ERRO: Falha no login. Resposta: $LOGIN_RESP"
    red "  Se for primeira execucao, use 'Forgot Password' na UI: $CRAFTY_URL"
    return 1
  fi
  echo "$TOKEN"
}

create_server() {
  local TOKEN=$1
  CREATE_RESP=$(curl -sf -X POST "$CRAFTY_URL/api/v2/servers" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{
      \"name\": \"$SERVER_NAME\",
      \"monitoring_type\": \"minecraft_java\",
      \"create_type\": \"minecraft_java\",
      \"minecraft_java_monitoring_data\": {
        \"host\": \"127.0.0.1\",
        \"port\": $SERVER_PORT
      },
      \"minecraft_java_create_data\": {
        \"create_type\": \"download_jar\",
        \"download_jar_create_data\": {
          \"type\": \"$SERVER_TYPE\",
          \"version\": \"$SERVER_VERSION\",
          \"mem_min\": $MEM_MIN,
          \"mem_max\": $MEM_MAX,
          \"server_properties_port\": $SERVER_PORT,
          \"category\": \"$CATEGORY\",
          \"agree_to_eula\": true
        }
      }
    }" 2>/dev/null) || {
    red "  ERRO: Falha ao criar servidor."
    yellow "  Tentando obter lista de servidores existentes..."
    local EXISTING
    EXISTING=$(curl -sf -X GET "$CRAFTY_URL/api/v2/servers" \
      -H "Authorization: Bearer $TOKEN" 2>/dev/null) || true
    echo "$EXISTING"
    return 1
  }
  local SID
  SID=$(echo "$CREATE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['new_server_id'])" 2>/dev/null) || true
  if [ -z "$SID" ]; then
    red "  ERRO: Resposta inesperada: $CREATE_RESP"
    return 1
  fi
  echo "$SID"
}

get_existing_server() {
  local TOKEN=$1
  local SERVERS
  SERVERS=$(curl -sf -X GET "$CRAFTY_URL/api/v2/servers" \
    -H "Authorization: Bearer $TOKEN" 2>/dev/null)
  echo "$SERVERS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
srv = data.get('data', [])
for s in srv:
    print(f\"{s.get('server_id','')}|{s.get('server_name','')}\")
" 2>/dev/null || true
}

deploy_data() {
  local SERVER_ID=$1
  local SERVER_DIR="/crafty/servers/$SERVER_ID/server"

  yellow "  Aguardando diretorio do servidor..."
  for i in $(seq 1 30); do
    if [ -d "$SERVER_DIR" ]; then break; fi
    if [ "$i" -eq 30 ]; then
      red "  ERRO: Diretorio $SERVER_DIR nao apareceu"
      return 1
    fi
    sleep 3
  done
  green "  Diretorio: $SERVER_DIR"

  yellow "  Copiando plugins..."
  mkdir -p "$SERVER_DIR/plugins"
  if [ -d "$REPO_DIR/server/plugins" ]; then
    cp -r "$REPO_DIR/server/plugins"/*.jar "$SERVER_DIR/plugins/" 2>/dev/null || true
    local COUNT=$(ls -1 "$SERVER_DIR/plugins/"*.jar 2>/dev/null | wc -l)
    green "    $COUNT plugins copiados"
  fi

  if [ -d "$REPO_DIR/server/plugins-config" ]; then
    green "  Copiando configs dos plugins..."
    cp -r "$REPO_DIR/server/plugins-config"/* "$SERVER_DIR/plugins/" 2>/dev/null || true
  fi

  yellow "  Extraindo mundos..."
  for world_zip in "$REPO_DIR/server/worlds"/*.zip; do
    if [ -f "$world_zip" ]; then
      unzip -qo "$world_zip" -d "$SERVER_DIR/" 2>/dev/null || true
      green "    $(basename "$world_zip")"
    fi
  done

  if [ -f "$REPO_DIR/server/server.properties" ]; then
    green "  Copiando server.properties..."
    cp "$REPO_DIR/server/server.properties" "$SERVER_DIR/"
  fi

  echo "eula=true" > "$SERVER_DIR/eula.txt"
  chmod +x "$SERVER_DIR"/*.jar 2>/dev/null || true
  green "  Deploy concluido!"
}

start_playit() {
  if [ -z "$PLAYIT_KEY" ]; then
    yellow "  PLAYIT_KEY nao definida, pulando Playit.gg"
    return
  fi
  local PDIR="${PLAYIT_DIR:-/tmp/playit}"
  mkdir -p "$PDIR"
  if [ ! -f "$PDIR/playit" ]; then
    yellow "  Baixando Playit.gg..."
    curl -sL "https://github.com/playit-cloud/playit-agent/releases/latest/download/playit-linux-x86_64" \
      -o "$PDIR/playit" || {
      yellow "  Aviso: nao foi possivel baixar Playit.gg"
      return
    }
    chmod +x "$PDIR/playit"
  fi
  if pgrep -f "playit.*$PLAYIT_KEY" > /dev/null 2>&1; then
    green "  Playit.gg ja esta rodando"
  else
    nohup "$PDIR/playit" --secret "$PLAYIT_KEY" > "$PDIR/playit.log" 2>&1 &
    green "  Playit.gg iniciado (PID: $!)"
    yellow "  Endereco: tail -f $PDIR/playit.log | grep -o 'https\\?://[^ ]*\\|Playit public address: [^ ]*'"
  fi
}

# ===== Main =====
yellow "[1] Garantindo que Crafty esteja rodando..."
ensure_crafty_running

yellow "[2] Aguardando API..."
wait_for_crafty

yellow "[3] Autenticando..."
TOKEN=$(api_login)

yellow "[4] Verificando servidores existentes..."
EXISTING=$(get_existing_server "$TOKEN")
SERVER_ID=$(echo "$EXISTING" | head -1 | cut -d'|' -f1)
SERVER_NAME_EXISTING=$(echo "$EXISTING" | head -1 | cut -d'|' -f2)

if [ -n "$SERVER_ID" ] && [ -n "$SERVER_NAME_EXISTING" ]; then
  green "  Servidor ja existe: '$SERVER_NAME_EXISTING' (ID: $SERVER_ID)"
else
  green "  Criando novo servidor..."
  SERVER_ID=$(create_server "$TOKEN")
  if [ -z "$SERVER_ID" ]; then
    red "  Nao foi possivel criar servidor. Implantando apenas dados..."
    green "  Done (deploy parcial)"
    start_playit
    exit 0
  fi
  green "  Servidor criado! ID: $SERVER_ID"
fi

yellow "[5] Implantando dados (plugins, mundos, configs)..."
deploy_data "$SERVER_ID"

yellow "[6] Configurando Playit.gg..."
start_playit

green ""
green "========================================"
green "  SERVICOS RODANDO"
green "========================================"
green "  Crafty UI:  http://localhost:8000"
green "  Servidor:   $SERVER_NAME (ID: $SERVER_ID)"
green ""
green "  Para ver o endereco publico:"
echo "    tail -f /tmp/playit/playit.log | grep -o 'https\\?://[^ ]*\\|Playit public address: [^ ]*'"
green ""
green "  Conecte-se via Playit.gg porta 25565!"
green "========================================"
