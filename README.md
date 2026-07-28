# Minecraft Server

Servidor Minecraft hospedado gratuitamente 24/7 usando **GitHub Codespaces**, **Crafty Controller** e **Playit.gg**.

## Como usar

### 1. Abrir o Codespace

No GitHub, clique em **Code** > **Codespaces** > **Create codespace on main**.

### 2. Instalar o Crafty Controller

No terminal do Codespace, execute:

```bash
bash setup.sh
```

### 3. Iniciar o Crafty

```bash
/workspaces/Minecraft/Minecraft/run_crafty.sh
```

### 4. Acessar o painel

1. Abra a aba **Portas** no VS Code
2. Clique no link da porta **8443**
3. Na tela de login, clique em **Forgot Password**
4. Veja o usuario e senha no terminal onde o Crafty esta rodando
5. Altere a senha apos o primeiro login

### 5. Playit.gg (acesso publico)

Em outro terminal:

```bash
docker run --rm -it --net=host \
  -e SECRET_KEY="SUA_SECRET_KEY" \
  ghcr.io/playit-cloud/playit-agent:0.17
```

A SECRET_KEY voce obtem em: https://playit.gg

### 6. Sempre que reiniciar

```bash
# Terminal 1 - Crafty
/workspaces/Minecraft/Minecraft/run_crafty.sh

# Terminal 2 - Playit.gg
docker run --rm -it --net=host -e SECRET_KEY="..." ghcr.io/playit-cloud/playit-agent:0.17
```

Depois inicie o servidor Minecraft pelo painel do Crafty.

## Estrutura

```
.minecraft/         - Servidor Minecraft (ignorado pelo git)
.devcontainer/      - Configuracao do Codespace
setup.sh            - Script de instalacao automatica
```

## Aviso

O Codespace desliga apos 30 min de inatividade. O servidor so fica online enquanto o Codespace estiver rodando.
