#!/usr/bin/env bash
# 13-docker-swarm-dns — comandos do laboratório
# Ver README.md para arquitetura BIND + nginx no Swarm.
#
# Módulo autocontido — inclui Vagrantfile e bootstrap do cluster Swarm.

set -euo pipefail

MANAGER_IP="192.168.56.11"
WORKER_TOKEN="<SUBSTITUIR_COM_TOKEN_DO_MANAGER>"  # docker swarm join-token worker -q
NODE_IPS=("192.168.56.11" "192.168.56.12" "192.168.56.13")
OVERLAY_NETWORK="dns-overlay"
NGINX_SERVICE="nginx-service"
BIND_IMAGE="bind9:demo"
BIND_CONTAINER="bind-dns"
DOMAIN="portal.minhaempresa.com.br"

# =============================================================================
# 0. Vagrant e bootstrap do cluster (máquina host + VMs)
# =============================================================================

vagrant_up() {
  vagrant up
}

vagrant_ssh_manager() { vagrant ssh swarm-1; }
vagrant_ssh_worker1() { vagrant ssh swarm-2; }
vagrant_ssh_worker2() { vagrant ssh swarm-3; }

manager_init_swarm() {
  docker swarm init --advertise-addr "${MANAGER_IP}"
  docker node ls
}

# Editar /lib/systemd/system/docker.service antes:
#   ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
manager_expose_docker_api() {
  sudo systemctl daemon-reload
  sudo systemctl restart docker
  ss -lnp | grep 2375
  docker node ls
}

manager_show_join_token() {
  docker swarm join-token worker
}

worker_join_swarm() {
  docker swarm join --token "${WORKER_TOKEN}" "${MANAGER_IP}:2377"
}

client_use_remote_docker() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker node ls
}

# =============================================================================
# 1. BIND — build e execução (máquina host)
# =============================================================================

host_build_bind_image() {
  docker build -t "${BIND_IMAGE}" bind/
}

host_run_bind_container() {
  docker run -d --name "${BIND_CONTAINER}" \
    -p 53:53/udp -p 53:53/tcp \
    "${BIND_IMAGE}"
}

host_start_bind() {
  docker exec -d "${BIND_CONTAINER}" /etc/init.d/bind9 start
  docker ps --filter "name=${BIND_CONTAINER}"
}

host_bind_shell() {
  docker exec -it "${BIND_CONTAINER}" /bin/sh
}

# =============================================================================
# 2. Cliente — configurar DNS e testar resolução (máquina host)
# =============================================================================

# Editar /etc/resolv.conf e apontar para o BIND:
#   nameserver 127.0.0.1          # com -p 53:53
#   nameserver <IP_DO_CONTAINER>  # sem publish de porta
host_configure_resolv() {
  docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "${BIND_CONTAINER}"
  sudo vi /etc/resolv.conf
}

host_test_dns() {
  host "${DOMAIN}"
  nc -v "${DOMAIN}" 80
  curl "${DOMAIN}"
}

# =============================================================================
# 3. Swarm — nginx com routing mesh (cliente remoto)
# =============================================================================

client_use_remote_docker() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker node ls
}

client_create_overlay_network() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker network create -d overlay --attachable "${OVERLAY_NETWORK}" 2>/dev/null || true
  docker network ls
}

client_create_nginx_service() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service create \
    --replicas 3 \
    --network "${OVERLAY_NETWORK}" \
    --name "${NGINX_SERVICE}" \
    --publish 80:80 \
    nginx:latest

  docker service ls
  docker service ps "${NGINX_SERVICE}"
}

client_scale_nginx() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker service scale "${NGINX_SERVICE}"=5
  docker service ps "${NGINX_SERVICE}"
}

# =============================================================================
# 4. Testes end-to-end
# =============================================================================

host_test_end_to_end() {
  host "${DOMAIN}"
  curl "${DOMAIN}"

  for ip in "${NODE_IPS[@]}"; do
    curl "${ip}:80"
  done
}

client_logs() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker service logs -f "${NGINX_SERVICE}"
}

# =============================================================================
# 5. Limpeza
# =============================================================================

client_cleanup_swarm() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker service rm "${NGINX_SERVICE}" 2>/dev/null || true
}

host_cleanup_bind() {
  docker stop "${BIND_CONTAINER}" 2>/dev/null || true
  docker rm "${BIND_CONTAINER}" 2>/dev/null || true
}

# =============================================================================
# Fluxo completo sugerido
# =============================================================================
# 0. vagrant_up
# 1. manager_init_swarm               → no swarm-1
# 2. manager_expose_docker_api        → no swarm-1 (editar docker.service antes)
# 3. worker_join_swarm                → no swarm-2 e swarm-3
# 4. client_use_remote_docker
# 5. host_build_bind_image && host_run_bind_container && host_start_bind
# 6. host_configure_resolv
# 7. host_test_dns                    # antes do nginx — resolve, conexão pode falhar
# 8. client_create_overlay_network
# 9. client_create_nginx_service
# 10. host_test_end_to_end
