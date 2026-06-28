#!/usr/bin/env bash
# Sobe o Portainer CE para gerenciamento visual do Docker local.
#
# Uso:
#   ./portainer.sh          → sobe o Portainer (idempotente)
#   ./portainer.sh stop     → para e remove o container
#   ./portainer.sh logs     → exibe os logs
#
# Acesso: https://localhost:9443

set -euo pipefail

CONTAINER_NAME="portainer"
VOLUME_NAME="portainer_data"

start() {
  # Criar volume se não existir
  docker volume inspect "${VOLUME_NAME}" > /dev/null 2>&1 \
    || docker volume create "${VOLUME_NAME}"

  # Remover container parado (se houver) antes de recriar
  if docker inspect "${CONTAINER_NAME}" > /dev/null 2>&1; then
    if [ "$(docker inspect -f '{{.State.Running}}' "${CONTAINER_NAME}")" = "true" ]; then
      echo "Portainer já está rodando → https://localhost:9443"
      return 0
    fi
    docker rm "${CONTAINER_NAME}"
  fi

  docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${VOLUME_NAME}:/data" \
    portainer/portainer-ce:latest

  echo "✅ Portainer iniciado → https://localhost:9443"
}

stop() {
  docker stop "${CONTAINER_NAME}" && docker rm "${CONTAINER_NAME}"
  echo "Portainer removido. Volume '${VOLUME_NAME}' mantido (dados preservados)."
}

logs() {
  docker logs -f "${CONTAINER_NAME}"
}

case "${1:-start}" in
  start) start ;;
  stop)  stop  ;;
  logs)  logs  ;;
  *)
    echo "Uso: $0 [start|stop|logs]"
    exit 1
    ;;
esac
