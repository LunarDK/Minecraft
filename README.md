# Minecraft Server

Servidor Minecraft Paper 1.20.1 gratuito 24/7 usando **GitHub Codespaces**, **Crafty Controller** e **Playit.gg**.

## Como usar

### 1. Abrir o Codespace

No GitHub, clique em **Code** > **Codespaces** > **Create codespace on main**.

### 2. Instalar o Crafty Controller

```bash
bash setup.sh
```

### 3. Iniciar o Crafty

```bash
/workspaces/Minecraft/Minecraft/run_crafty.sh
```

### 4. Configurar o servidor no Crafty

1. Acesse http://localhost:8443
2. Clique em **Forgot Password**, veja o usuario/senha no terminal
3. Crie um servidor: **Paper 1.20.1**, nome: `paper`
4. **Pare o servidor** apos a criacao

### 5. Implantar mundo e plugins

```bash
bash deploy.sh
```

Isso copia worlds, plugins e configuracoes para o servidor.

### 6. Iniciar o servidor

Inicie pelo painel do Crafty.

### 7. Playit.gg (acesso publico)

```bash
docker run --rm -it --net=host \
  -e SECRET_KEY="SUA_SECRET_KEY" \
  ghcr.io/playit-cloud/playit-agent:0.17
```

### Sempre que reiniciar

```bash
# Terminal 1 - Crafty
/workspaces/Minecraft/Minecraft/run_crafty.sh

# Terminal 2 - Playit.gg
docker run --rm -it --net=host -e SECRET_KEY="..." ghcr.io/playit-cloud/playit-agent:0.17
```

Depois inicie o servidor pelo Crafty.

## Estrutura

```
server/
  worlds/          - Backups dos mundos (world, nether, end)
  plugins/         - JARs dos plugins
  plugins-config/  - Configuracoes dos plugins (do Aternos)
  server.properties

setup.sh           - Instalacao do Crafty
deploy.sh          - Implantacao de dados no servidor Crafty
```

## Plugins inclusos

EssentialsX, WorldEdit, WorldGuard, Slimefun, SkinsRestorer, GSit,
ViaVersion, Vault, Chunky, SilkSpawners, Harbor, TPA (WarSkyGod),
vzBackpack, BubbleVillagers, Veinminer, DeathCoords

## Notas

- O Codespace desliga apos 30 min de inatividade
- Servidor online apenas enquanto o Codespace estiver rodando
- Java 21 necessario para vzBackpack (ja configurado no devcontainer)
