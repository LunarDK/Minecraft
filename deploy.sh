#!/bin/bash
set -e

REPO_NAME=$(basename $(pwd))
CRAFTY_DIR="/workspaces/$REPO_NAME/Minecraft"
SERVER_NAME="${1:-paper}"
SERVER_DIR="$CRAFTY_DIR/servers/$SERVER_NAME"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=================================="
echo " Deploying Minecraft Server Data"
echo "=================================="
echo ""
echo "Server name: $SERVER_NAME"
echo "Server dir:  $SERVER_DIR"
echo ""

if [ ! -d "$SERVER_DIR" ]; then
  echo "ERROR: Server directory does not exist!"
  echo ""
  echo "Create the server in Crafty first:"
  echo "1. Open Crafty web UI (port 8443)"
  echo "2. Create a new server named '$SERVER_NAME'"
  echo "3. Use Paper 1.20.1 as the server type"
  echo "4. Run this script again"
  exit 1
fi

echo "[1/5] Extracting worlds..."
for w in world world_nether world_the_end; do
  zip="$SCRIPT_DIR/server/worlds/$w.zip"
  if [ -f "$zip" ]; then
    rm -rf "$SERVER_DIR/$w"
    echo "  Extracting $w..."
    unzip -q "$zip" -d "$SERVER_DIR/"
  else
    echo "  Skipping $w (no zip found)"
  fi
done

echo ""
echo "[2/5] Copying plugins..."
mkdir -p "$SERVER_DIR/plugins"
cp -r "$SCRIPT_DIR/server/plugins/"*.jar "$SERVER_DIR/plugins/" 2>/dev/null || true
count=$(ls -1 "$SERVER_DIR/plugins/"*.jar 2>/dev/null | wc -l)
echo "  $count plugin JARs copied"

echo ""
echo "[3/5] Copying plugin configs..."
cp -r "$SCRIPT_DIR/server/plugins-config/"* "$SERVER_DIR/plugins/" 2>/dev/null || true
echo "  Plugin configs copied"

echo ""
echo "[4/5] Copying server.properties..."
cp "$SCRIPT_DIR/server/server.properties" "$SERVER_DIR/" 2>/dev/null || true
echo "  server.properties copied"

echo ""
echo "[5/5] Setting ownership..."
sudo chown -R $(whoami):$(whoami) "$SERVER_DIR" 2>/dev/null || true

echo ""
echo "=================================="
echo " Deployment Complete!"
echo "=================================="
echo ""
echo "Start the server in Crafty:"
echo "  http://localhost:8443"
echo ""
echo "Or restart if already running."
