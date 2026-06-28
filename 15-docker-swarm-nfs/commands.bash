#!/usr/bin/env bash
# 15-docker-swarm-nfs — comandos do laboratório
# Ver README.md para arquitetura WordPress HA + NFS no Swarm.
#
# Diferença em relação aos módulos 11–13: os serviços são definidos no
# docker-compose.yaml e implantados com "docker stack deploy" — não há
# "docker service create" manual nem "docker network create".

set -euo pipefail

MANAGER_IP="192.168.56.11"
NFS_IP="192.168.56.20"
WORKER_TOKEN="<SUBSTITUIR_COM_TOKEN_DO_MANAGER>"  # docker swarm join-token worker -q
STACK_NAME="wp-stack"
COMPOSE_FILE="wordpress/docker-compose.yaml"

# =============================================================================
# 0. Vagrant — subir infraestrutura (máquina host)
# =============================================================================

nfs_up() {
  cd nfs && vagrant up && cd ..
}

swarm_up() {
  cd swarm && vagrant up && cd ..
}

vagrant_ssh_manager() { cd swarm && vagrant ssh swarm-1; }
vagrant_ssh_worker1()  { cd swarm && vagrant ssh swarm-2; }
vagrant_ssh_worker2()  { cd swarm && vagrant ssh swarm-3; }

# =============================================================================
# 1. Bootstrap do cluster Swarm (executar dentro das VMs)
# =============================================================================

# Rodar dentro de swarm-1:
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
}

manager_show_join_token() {
  docker swarm join-token worker
}

# Rodar dentro de swarm-2 e swarm-3:
worker_join_swarm() {
  docker swarm join --token "${WORKER_TOKEN}" "${MANAGER_IP}:2377"
}

# Rodar na máquina host para gerenciar o cluster remotamente:
client_use_remote_docker() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker node ls
}

# =============================================================================
# 2. Placement constraint — label no nó do banco (específico deste módulo)
#
# O docker-compose.yaml define:
#   deploy.placement.constraints: ["node.labels.db==true"]
# Sem esse label, a task do MySQL não será alocada em nenhum nó.
# =============================================================================

# Descobrir o ID do nó desejado (ex: node-3) e aplicar o label:
label_db_node() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker node ls
  # Substituir <NODE-ID> pelo ID real exibido acima:
  docker node update --label-add db=true <NODE-ID>
  docker node inspect <NODE-ID> --pretty | grep -A5 Labels
}

# =============================================================================
# 3. Teste do volume NFS (opcional — valida montagem antes do deploy)
# =============================================================================

test_nfs_volume() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker volume create \
    --driver local \
    --opt type=nfs4 \
    --opt o=addr="${NFS_IP}",rw,nolock \
    --opt device=:/srv/wordpress \
    wordpress-test

  docker run --rm -v wordpress-test:/var/www/html wordpress:latest \
    ls /var/www/html

  docker volume rm wordpress-test
}

# =============================================================================
# 4. Deploy do stack — substitui todos os "docker service create" manuais
# =============================================================================

stack_deploy() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker stack deploy -c "${COMPOSE_FILE}" "${STACK_NAME}"
}

stack_status() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker stack ls
  docker stack services "${STACK_NAME}"
  docker stack ps "${STACK_NAME}"
}

# =============================================================================
# 5. Comandos úteis
# =============================================================================

stack_logs_frontend() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker service logs -f "${STACK_NAME}_frontend"
}

stack_logs_db() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker service logs -f "${STACK_NAME}_db"
}

stack_scale_frontend() {
  # Uso: stack_scale_frontend 3
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker service scale "${STACK_NAME}_frontend=${1:-5}"
}

# =============================================================================
# 6. Limpeza
# =============================================================================

stack_remove() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker stack rm "${STACK_NAME}"
}

volumes_remove() {
  export DOCKER_HOST="${MANAGER_IP}:2375"
  docker volume rm "${STACK_NAME}_wordpress_data" "${STACK_NAME}_db_data"
}

vagrant_destroy() {
  cd swarm && vagrant destroy -f && cd ..
  cd nfs   && vagrant destroy -f && cd ..
}
