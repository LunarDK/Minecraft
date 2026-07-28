# Minecraft Server

Servidor Minecraft Paper 1.20.1 gratuito 24/7 usando **GitHub Codespaces**, **Crafty Controller** e **Playit.gg**.

Totalmente automatizado: abra o Codespace e o servidor ja estara pronto.

## Como usar

1. No GitHub, va em **Code** > **Codespaces** > **Create codespace on main**
2. Aguarde o setup automatico (2-5 min)
3. Acesse o Crafty em http://localhost:8000 (admin / 123456789)
4. Descubra o endereco publico:
   ```bash
   tail -f /tmp/playit/playit.log | grep -o 'https\?://[^ ]*\|Playit public address: [^ ]*'
   ```
5. Conecte-se com seu cliente Minecraft!

## O que acontece automaticamente

| Passo | Descricao |
|-------|-----------|
| setup.sh | Instala Crafty Controller (se necessario) |
| init-server.sh | Inicia Crafty, cria servidor Paper 1.20.1, plugins, mundos, playit.gg |
| postStartCommand | Re-inicia servico a cada restart do Codespace |

## Comandos uteis

```bash
bash deploy.sh <server_id>     # Re-implantar dados manualmente
tail -f /tmp/crafty.log         # Log do Crafty
tail -f /tmp/playit/playit.log  # Log do Playit.gg (endereco publico)
```

## Estrutura

```
server/
  worlds/          - Backups dos mundos (world, nether, end)
  plugins/         - JARs dos plugins (16 plugins)
  plugins-config/  - Configuracoes dos plugins (do Aternos)
  server.properties - Config do servidor (survival, hard, 20 players)

setup.sh           - Instalacao do Crafty (1x)
init-server.sh     - Automacao completa: cria server + deploy + playit
deploy.sh          - Re-deploy manual de dados
```

## Plugins

EssentialsX, WorldEdit, WorldGuard, Slimefun, SkinsRestorer, GSit, ViaVersion,
Vault, Chunky, SilkSpawners, Harbor, TPA (WarSkyGod), vzBackpack,
BubbleVillagers, Veinminer, DeathCoords

## Notas

- Codespace desliga apos 30 min de inatividade (gratuito)
- Servidor online apenas enquanto o Codespace estiver rodando
- Java 21 necessario para vzBackpack
