#!/usr/bin/env bash
# 11-docker-swarm — comandos do laboratório
# Ver README.md para arquitetura e teoria.
# Módulo autocontido — inclui Vagrantfile e bootstrap do cluster Swarm.

set -euo pipefail

MANAGER_IP="192.168.56.11"
MANAGER_HOST="node-1"
WORKER_TOKEN="<SUBSTITUIR_COM_TOKEN_DO_MANAGER>"  # docker swarm join-token worker -q

# =============================================================================
# 0. Vagrant (máquina host)
# =============================================================================

vagrant_up() {
  vagrant up
}

vagrant_ssh_manager() { vagrant ssh swarm-1; }
vagrant_ssh_worker1() { vagrant ssh swarm-2; }
vagrant_ssh_worker2() { vagrant ssh swarm-3; }

# =============================================================================
# 1. Manager (node-1 / 192.168.56.11)
# =============================================================================

manager_init_swarm() {
  docker swarm init --advertise-addr "${MANAGER_IP}"
  docker node ls
}

manager_check_ports() {
  sudo ss -lnp | grep 2377   # cluster management
  ss -lnp | grep 2375        # API Docker TCP (após configurar)
}

# Expor socket Docker na porta 2375 (SEM TLS — apenas laboratório)
#
# 1. Localizar o unit file:
#      sudo find / -name docker.service -type f
#    → /lib/systemd/system/docker.service
#
# 2. Editar ExecStart, adicionando listener TCP:
#      ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
#
# 3. Recarregar e reiniciar:
manager_expose_docker_api() {
  sudo systemctl daemon-reload
  sudo systemctl restart docker
  ss -lnp | grep 2375
  docker node ls
}

manager_show_join_token() {
  docker swarm join-token worker
  # ou apenas o token:
  # docker swarm join-token worker -q
}

# =============================================================================
# 2. Workers (node-2 / node-3)
# =============================================================================

worker_join_swarm() {
  docker swarm join --token "${WORKER_TOKEN}" "${MANAGER_IP}:2377"
}

# =============================================================================
# 3. Cliente remoto (máquina host — fora do Swarm)
# =============================================================================

client_use_remote_docker() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker node ls
}

client_inspect_nodes() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker node ls
  docker node inspect node-2
  docker node ps node-2
}

# =============================================================================
# 4. Serviços Swarm (cliente remoto)
# =============================================================================

client_create_nginx_service() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service create -d \
    -p 8080:80 \
    --replicas 3 \
    --name nginx-service \
    nginx:latest

  docker service ls
  docker service ps nginx-service
}

client_inspect_service() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service inspect nginx-service
  docker network ls
  docker network inspect "$(docker network ls -q -f name=ingress)"
}

client_test_routing_mesh() {
  curl "${MANAGER_IP}:8080"    # node-1
  curl 192.168.56.12:8080      # node-2
  curl 192.168.56.13:8080      # node-3
}

client_scale_service() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service scale nginx-service=10
  docker service ps nginx-service

  docker service scale nginx-service=2
  docker service ps nginx-service

  docker service scale nginx-service=4
  docker service ps nginx-service
}

# =============================================================================
# 5. Logs e diagnóstico
# =============================================================================

worker_service_logs() {
  docker service logs -f nginx-service
}

worker_container_logs() {
  docker container logs -f <CONTAINER_ID>
}

# =============================================================================
# Histórico original (referência)
# =============================================================================
# manager:  docker swarm init, edit docker.service, restart, ss grep 2375
# worker1:  docker swarm join, docker service logs
# worker2:  docker swarm join
# client:   DOCKER_HOST=192.168.56.11:2375, service create/scale, curl nos 3 nós
