#!/bin/bash
set -e

echo "=================================="
echo " Minecraft Server - Setup Script"
echo "=================================="
echo ""

REPO_NAME=$(basename $(pwd))
INSTALL_DIR="/workspaces/$REPO_NAME/Minecraft"

echo "[1/6] Atualizando pacotes..."
sudo apt update && sudo apt upgrade -y

echo ""
echo "[2/6] Instalando dependencias..."
pip3 install distro 2>/dev/null || sudo python3 -m pip install distro --break-system-packages

echo ""
echo "[3/6] Baixando instalador do Crafty Controller..."
if [ -d "crafty-installer-4.0" ]; then
  rm -rf crafty-installer-4.0
fi
git clone https://gitlab.com/crafty-controller/crafty-installer-4.0.git

echo ""
echo "[4/6] Executando instalador..."
echo ""
echo "ATENCAO: Durante a instalacao, responda:"
echo "  - Continuar no Ubuntu? -> Y"
echo "  - Instalar em /var/opt/...? -> N"
echo "  - Diretorio de instalacao: $INSTALL_DIR"
echo "  - Branch: master"
echo "  - Criar service file? -> N"
echo ""

cd crafty-installer-4.0
sudo ./install_crafty.sh

echo ""
echo "[5/6] Limpando..."
cd /workspaces/$REPO_NAME
rm -rf crafty-installer-4.0

echo ""
echo "[6/6] Instalacao concluida!"
echo ""
echo "=================================="
echo " PROXIMOS PASSOS:"
echo "=================================="
echo ""
echo "1. Inicie o Crafty:"
echo "   $INSTALL_DIR/run_crafty.sh"
echo ""
echo "2. Abra a aba PORTAS no VS Code"
echo "   e clique no link da porta 8443"
echo ""
echo "3. Login:"
echo "   - Clique em 'Forgot Password'"
echo "   - Veja usuario/senha no terminal"
echo ""
echo "4. Configure o Playit.gg em outro"
echo "   terminal com Docker:"
echo "   docker run --rm -it --net=host -e SECRET_KEY=\"...\" ghcr.io/playit-cloud/playit-agent:0.17"
echo ""
