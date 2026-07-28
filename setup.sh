#!/bin/bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CRAFTY_DIR="${CRAFTY_DIR:-/opt/crafty}"
ADMIN_USER="${ADMIN_USER:-admin}"
ADMIN_PASS="123456789"

red() { echo -e "\033[31m$*\033[0m"; }
green() { echo -e "\033[32m$*\033[0m"; }
yellow() { echo -e "\033[33m$*\033[0m"; }

green "=== Instalador do Crafty Controller ==="

if [ -f "$CRAFTY_DIR/main.py" ]; then
  green "Crafty ja esta instalado em $CRAFTY_DIR"
  exit 0
fi

yellow "Instalando dependencias..."
sudo apt-get update -qq
sudo apt-get install -y -qq python3 python3-pip python3-venv git curl unzip gzip

yellow "Clonando Crafty 4..."
sudo git clone --depth 1 https://gitlab.com/crafty-controller/crafty-4.git "$CRAFTY_DIR"
sudo chown -R $(whoami):$(whoami) "$CRAFTY_DIR"

cd "$CRAFTY_DIR"
yellow "Criando ambiente Python..."
python3 -m venv venv
source venv/bin/activate
pip install -q --upgrade pip
pip install -q -r requirements.txt

yellow "Criando config com credenciais admin pre-definidas..."
mkdir -p "$CRAFTY_DIR/app/config"
cat > "$CRAFTY_DIR/app/config/config.json" << 'CONFEOF'
{
  "app_root": "/crafty",
  "port": 8000,
  "https_port": 8443
}
CONFEOF

cat > "$CRAFTY_DIR/app/config/default-creds.txt" << CREDSEOF
admin,123456789
CREDSEOF

cat > "$CRAFTY_DIR/run_crafty.sh" << 'RUNEOF'
#!/bin/bash
cd /opt/crafty
source venv/bin/activate
exec python3 main.py
RUNEOF
chmod +x "$CRAFTY_DIR/run_crafty.sh"

green "Instalacao concluida em $CRAFTY_DIR"
green "Usuario: admin / Senha: 123456789"
