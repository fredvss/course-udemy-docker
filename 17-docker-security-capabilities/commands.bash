#!/usr/bin/env bash
# 17-docker-security-capabilities — comandos do laboratório
#
# Cada seção é independente. Execute função por função para observar o
# comportamento e entender o que cada mecanismo de segurança faz.
#
# Pré-requisito: Docker instalado e rodando localmente.
# Para as seções de Secrets (4+): Swarm ativo (docker swarm init).

set -euo pipefail

# =============================================================================
# 1. LINUX CAPABILITIES
#
# O Docker concede um subconjunto seguro de capabilities por padrão.
# Use --cap-drop / --cap-add para ajustar ao mínimo necessário.
# =============================================================================

# Ver quais capabilities um container tem por padrão
caps_ver_padrao() {
  docker run --rm alpine sh -c \
    "apk add -q libcap && capsh --print | grep Current"
}

# Remover TODAS as capabilities e adicionar só o que a app precisa
# Exemplo: servidor web que só precisa ligar na porta 80
caps_minimo_nginx() {
  docker run --rm -d \
    --cap-drop ALL \
    --cap-add NET_BIND_SERVICE \
    --cap-add CHOWN \
    --cap-add SETUID \
    --cap-add SETGID \
    -p 8080:80 \
    --name nginx-restricted \
    nginx:alpine

  echo "Nginx rodando com capabilities mínimas — acesse http://localhost:8080"
  docker stop nginx-restricted
}

# Tentar operação que exige capability removida → deve falhar
caps_testar_bloqueio() {
  echo "--- Com CAP_NET_RAW (padrão): ping funciona ---"
  docker run --rm alpine ping -c1 8.8.8.8 && echo "✅ ping OK"

  echo ""
  echo "--- Sem CAP_NET_RAW: ping deve falhar ---"
  docker run --rm --cap-drop NET_RAW alpine ping -c1 8.8.8.8 \
    || echo "✅ ping bloqueado (NET_RAW removida)"
}

# Nunca usar --privileged em produção — concede TUDO
caps_privileged_demo() {
  echo "⚠️  --privileged concede acesso total ao host — apenas para debug local"
  docker run --rm --privileged alpine sh -c \
    "apk add -q libcap && capsh --print | grep Current"
}

# =============================================================================
# 2. SECCOMP — filtrar syscalls permitidas
#
# Por padrão o Docker aplica um perfil que bloqueia ~44 syscalls perigosas.
# Você pode aplicar um perfil mais restrito ou desabilitar (não recomendado).
# =============================================================================

# Confirmar que o perfil padrão está ativo (deve mostrar "seccomp")
seccomp_confirmar_ativo() {
  docker run --rm alpine grep Seccomp /proc/1/status
  # Seccomp: 2  →  2 = SECCOMP_MODE_FILTER (perfil ativo)
  # Seccomp: 0  →  desabilitado
}

# Testar bloqueio do perfil padrão: unshare é bloqueado por padrão
seccomp_testar_padrao() {
  echo "--- unshare bloqueado pelo perfil padrão do Docker ---"
  docker run --rm alpine unshare --user sh \
    || echo "✅ unshare bloqueado pelo seccomp padrão"
}

# Aplicar o perfil customizado deste módulo (bloqueia ptrace, mount, bpf...)
seccomp_perfil_customizado() {
  docker run --rm \
    --security-opt seccomp=seccomp/custom-restricted.json \
    alpine sh -c "echo 'Container iniciado com perfil restrito'"
}

# Testar que ptrace é bloqueado pelo perfil customizado
seccomp_testar_ptrace_bloqueado() {
  echo "--- ptrace bloqueado pelo custom-restricted.json ---"
  docker run --rm \
    --security-opt seccomp=seccomp/custom-restricted.json \
    alpine sh -c "apk add -q strace && strace ls 2>&1 | head -3" \
    || echo "✅ ptrace bloqueado pelo seccomp customizado"
}

# Rodar sem nenhum perfil seccomp (apenas para fins de comparação — não usar em prod)
seccomp_desabilitado_demo() {
  echo "⚠️  Sem perfil seccomp — unshare agora funciona dentro do container"
  docker run --rm \
    --security-opt seccomp=unconfined \
    alpine sh -c "unshare --user sh -c 'whoami'"
}

# Combinar: sem capabilities desnecessárias + perfil seccomp customizado
seccomp_combinado_com_caps() {
  docker run --rm \
    --cap-drop ALL \
    --cap-add NET_BIND_SERVICE \
    --security-opt seccomp=seccomp/custom-restricted.json \
    alpine echo "✅ Container com capabilities mínimas + seccomp restrito"
}

# =============================================================================
# 3. DOCKER SECRETS
#
# Secrets são injetados como arquivos em /run/secrets/<nome> — nunca como
# variáveis de ambiente (visíveis em docker inspect e /proc/<pid>/environ).
# Requer Swarm ativo: docker swarm init
# =============================================================================

# Iniciar Swarm de nó único (se ainda não estiver ativo)
secrets_init_swarm() {
  docker swarm init 2>/dev/null || echo "Swarm já está ativo"
}

# Criar secrets no Swarm
secrets_criar() {
  echo "senha_do_banco_2024"  | docker secret create db_password -
  echo "token_api_xyz_789"    | docker secret create api_token -

  docker secret ls
}

# Usar um secret em um serviço — lido via arquivo em /run/secrets/
secrets_usar_em_servico() {
  docker service create \
    --name leitor-secrets \
    --secret db_password \
    --secret api_token \
    alpine sh -c "
      echo '=== Conteúdo dos secrets ==='
      echo 'db_password:' \$(cat /run/secrets/db_password)
      echo 'api_token:'   \$(cat /run/secrets/api_token)
      sleep 60
    "

  sleep 3
  docker service logs leitor-secrets
  docker service rm leitor-secrets
}

# Demonstrar que secrets NÃO aparecem em docker inspect
secrets_nao_aparece_em_inspect() {
  docker service create \
    --name app-com-secret \
    --secret db_password \
    -e APP_ENV=production \
    alpine sleep 120

  echo ""
  echo "=== docker service inspect — senha NÃO aparece ==="
  docker service inspect app-com-secret --format '{{json .Spec.TaskTemplate.ContainerSpec.Env}}'

  echo ""
  echo "=== Variável de ambiente SEM secret — visível em inspect ❌ ==="
  docker service inspect app-com-secret --format '{{json .Spec.TaskTemplate.ContainerSpec.Env}}'

  docker service rm app-com-secret
}

# Alternativa local sem Swarm: bind mount de arquivo como secret
secrets_local_sem_swarm() {
  echo "senha-local-desenvolvimento" > /tmp/db_password_local.txt
  chmod 600 /tmp/db_password_local.txt

  docker run --rm \
    -v /tmp/db_password_local.txt:/run/secrets/db_password:ro \
    alpine sh -c "
      echo 'Secret lido do arquivo:'
      cat /run/secrets/db_password
    "

  rm /tmp/db_password_local.txt
}

# Deploy do stack completo com secrets (WordPress + MySQL)
secrets_stack_deploy() {
  secrets_init_swarm

  echo "wordpress_db_pass_2024" | docker secret create wp_db_password - 2>/dev/null || true
  echo "wordpress_root_2024"    | docker secret create wp_db_root_password - 2>/dev/null || true

  docker stack deploy -c secrets/docker-compose.yaml sec-stack

  echo "Stack deployado — acesse http://localhost:80"
  docker stack services sec-stack
}

# Limpeza dos secrets e stack
secrets_limpar() {
  docker stack rm sec-stack 2>/dev/null || true
  sleep 5
  docker secret rm db_password api_token wp_db_password wp_db_root_password 2>/dev/null || true
  docker swarm leave --force 2>/dev/null || true
}

# =============================================================================
# 4. DOCKER CONTENT TRUST (DCT)
#
# Garante que a imagem puxada/executada é exatamente a assinada pelo publisher.
# Ver comandos detalhados de assinatura em: content-trust/commands.bash
# =============================================================================

# Inspecionar assinatura de uma imagem oficial (nginx é assinado pelo Docker)
dct_inspecionar_nginx() {
  docker trust inspect --pretty nginx:latest
}

# Habilitar DCT e tentar puxar imagem não assinada → deve falhar
dct_testar_bloqueio() {
  echo "--- Tentando puxar imagem sem assinatura com DCT ativo ---"
  DOCKER_CONTENT_TRUST=1 docker pull ubuntu:latest \
    && echo "❌ Pull passou (imagem estava assinada)" \
    || echo "✅ Pull bloqueado — DCT exige assinatura válida"
}

# Puxar imagem assinada com DCT ativo → deve funcionar
dct_pull_assinada() {
  echo "--- Puxando nginx (imagem assinada oficialmente) ---"
  DOCKER_CONTENT_TRUST=1 docker pull nginx:latest \
    && echo "✅ Pull OK — assinatura válida"
}

# Ver informações de confiança de uma imagem
dct_ver_chaves() {
  docker trust inspect --pretty nginx:latest | head -40
}

# =============================================================================
# DEMONSTRAÇÃO COMPLETA — executa todos os testes na ordem
# =============================================================================

demo_completa() {
  echo "=========================================="
  echo " 1. CAPABILITIES"
  echo "=========================================="
  caps_testar_bloqueio

  echo ""
  echo "=========================================="
  echo " 2. SECCOMP"
  echo "=========================================="
  seccomp_confirmar_ativo
  seccomp_testar_padrao
  seccomp_testar_ptrace_bloqueado

  echo ""
  echo "=========================================="
  echo " 3. SECRETS (requer Swarm)"
  echo "=========================================="
  secrets_init_swarm
  secrets_criar
  secrets_local_sem_swarm

  echo ""
  echo "=========================================="
  echo " 4. CONTENT TRUST"
  echo "=========================================="
  dct_inspecionar_nginx
  dct_pull_assinada
  dct_testar_bloqueio

  echo ""
  echo "✅ Demonstração completa"
}
