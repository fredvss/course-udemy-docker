#!/usr/bin/env bash
# 12-docker-swarm-ha-proxy — comandos do laboratório
# Ver README.md para arquitetura, VIP vs DNSRR e HAProxy global.
#
# Pré-requisito: cluster Swarm do módulo 11 (DOCKER_HOST apontando para o manager).

set -euo pipefail

MANAGER_IP="192.168.56.11"
OVERLAY_NETWORK="ha-proxy"
NGINX_SERVICE="nginx-service"
HAPROXY_SERVICE="haproxy-service"
HAPROXY_IMAGE="haproxytech/haproxy-debian:2.0"

# =============================================================================
# 0. Cliente remoto — variável de ambiente
# =============================================================================

client_use_remote_docker() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker node ls
}

# =============================================================================
# 1. Rede overlay attachable
# =============================================================================

client_create_overlay_network() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker network create -d overlay --attachable "${OVERLAY_NETWORK}"
  docker network ls
}

client_remove_overlay_network() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service rm "${NGINX_SERVICE}" 2>/dev/null || true
  docker service rm "${HAPROXY_SERVICE}" 2>/dev/null || true
  docker network rm "${OVERLAY_NETWORK}"
}

# =============================================================================
# 2. Nginx — explorar VIP e DNSRR
# =============================================================================

# VIP (padrão): serviço recebe um IP virtual; o Swarm faz o balanceamento interno.
client_create_nginx_vip() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service create \
    --name "${NGINX_SERVICE}" \
    --replicas 3 \
    --endpoint-mode vip \
    --network "${OVERLAY_NETWORK}" \
    nginx:latest

  docker service ps "${NGINX_SERVICE}"
}

# Alternar para DNSRR: o nome do serviço resolve para os IPs de cada task.
client_switch_nginx_to_dnsrr() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service update --endpoint-mode dnsrr "${NGINX_SERVICE}"
  docker service ps "${NGINX_SERVICE}"
}

# Criar direto em DNSRR (fluxo final do lab).
client_create_nginx_dnsrr() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service create \
    --name "${NGINX_SERVICE}" \
    --replicas 3 \
    --endpoint-mode dnsrr \
    --network "${OVERLAY_NETWORK}" \
    nginx:latest

  docker service ps "${NGINX_SERVICE}"
}

client_inspect_endpoint_mode() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service inspect "${NGINX_SERVICE}" \
    --format 'Endpoint mode: {{.Endpoint.Spec.Mode}} | VIPs: {{json .Endpoint.VirtualIPs}}'

  # IPs das tasks em execução
  docker inspect "$(docker ps -q)" \
    --format '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'
}

client_scale_nginx() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service update --replicas 5 "${NGINX_SERVICE}"
  docker service ps "${NGINX_SERVICE}"

  docker service update --replicas 3 "${NGINX_SERVICE}"
  docker service ps "${NGINX_SERVICE}"
}

# =============================================================================
# 3. HAProxy — configuração nos nós (em cada node do Swarm)
# =============================================================================

# Copiar haproxy.cfg deste repositório para cada nó:
#   vagrant ssh swarm-1 -c 'sudo mkdir -p /etc/haproxy'
#   vagrant scp haproxy.cfg swarm-1:/tmp/haproxy.cfg
#   vagrant ssh swarm-1 -c 'sudo mv /tmp/haproxy.cfg /etc/haproxy/haproxy.cfg'
#
# Ou manualmente em cada nó:
node_setup_haproxy_config() {
  sudo mkdir -p /etc/haproxy
  sudo vi /etc/haproxy/haproxy.cfg
  ss -lnp | grep 80
}

# =============================================================================
# 4. HAProxy — validar config e criar serviço global (cliente remoto)
# =============================================================================

# Validar sintaxe do haproxy.cfg antes de subir o serviço.
client_validate_haproxy_config() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker run --rm \
    --network "${OVERLAY_NETWORK}" \
    --mount type=bind,src=/etc/haproxy,dst=/usr/local/etc/haproxy,ro=true \
    "${HAPROXY_IMAGE}" \
    haproxy -c -f /usr/local/etc/haproxy/haproxy.cfg
}

# Global: uma instância por nó; publish mode=host expõe :80 no host de cada nó.
client_create_haproxy_global() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service create \
    --mode global \
    --name "${HAPROXY_SERVICE}" \
    --network "${OVERLAY_NETWORK}" \
    --publish published=80,target=80,protocol=tcp,mode=host \
    --mount type=bind,src=/etc/haproxy,dst=/usr/local/etc/haproxy,ro=true \
    "${HAPROXY_IMAGE}"

  docker service ls
  docker service ps "${HAPROXY_SERVICE}"
}

client_remove_haproxy() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker service rm "${HAPROXY_SERVICE}"
}

# =============================================================================
# 5. Testes e diagnóstico
# =============================================================================

client_test_load_balancer() {
  curl "${MANAGER_IP}:80"       # node-1
  curl 192.168.56.12:80         # node-2
  curl 192.168.56.13:80         # node-3
}

# Container de debug na overlay — observar resolução DNS (VIP vs DNSRR).
client_debug_dns() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker run --network "${OVERLAY_NETWORK}" -it nicolaka/netshoot
  # dentro do container:
  #   nslookup tasks.nginx-service
  #   dig tasks.nginx-service
}

client_logs() {
  export DOCKER_HOST="${MANAGER_IP}:2375"

  docker service logs -f "${NGINX_SERVICE}"
  docker service logs "${HAPROXY_SERVICE}" --raw --tail 100
}

# =============================================================================
# Fluxo completo sugerido
# =============================================================================
# 1. client_use_remote_docker
# 2. client_create_overlay_network
# 3. client_create_nginx_vip          → inspecionar VIP
# 4. client_switch_nginx_to_dnsrr     → comparar comportamento DNS
#    (ou client_remove_overlay_network + recriar com client_create_nginx_dnsrr)
# 5. node_setup_haproxy_config        → em cada nó (swarm-1, swarm-2, swarm-3)
# 6. client_validate_haproxy_config
# 7. client_create_haproxy_global
# 8. client_test_load_balancer
# 9. client_debug_dns / client_scale_nginx
