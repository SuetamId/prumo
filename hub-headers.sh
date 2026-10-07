#!/usr/bin/env bash
# hub-headers.sh — imprime o header de autenticação do Hub de memória para o Claude Code
# (campo `headersHelper` do servidor MCP). Configurado pelo `prumo-workspace --hub`.
#
# A chave mora em ~/.config/prumo/hub-key, legível só pelo dono — nunca na configuração
# do cliente, nunca em argv (que vaza para a lista de processos e para o transcript).
set -euo pipefail
key="$(tr -d '\n\r ' < "${XDG_CONFIG_HOME:-$HOME/.config}/prumo/hub-key")"
printf '{"Authorization":"Bearer %s"}\n' "$key"
