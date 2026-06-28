#!/usr/bin/env bash
# 17-docker-security-capabilities — Docker Content Trust (DCT)
#
# DCT usa o framework TUF (The Update Framework) para assinar imagens no push
# e verificar a assinatura no pull/run. Garante integridade da supply chain:
# a imagem executada é exatamente a que o publisher assinou.

set -euo pipefail

REGISTRY_USER="<SEU_USUARIO_DOCKERHUB>"   # substituir
IMAGE_NAME="${REGISTRY_USER}/myapp"
IMAGE_TAG="1.0.0"

# =============================================================================
# 1. Habilitar DCT na sessão atual
# =============================================================================

enable_dct() {
  export DOCKER_CONTENT_TRUST=1
  echo "DCT habilitado (DOCKER_CONTENT_TRUST=1)"
}

disable_dct() {
  export DOCKER_CONTENT_TRUST=0
  echo "DCT desabilitado"
}

# =============================================================================
# 2. Gerar chaves de assinatura
#
# Duas chaves são criadas:
#   - root key    : chave mestre — guardar offline (USB, cofre)
#   - targets key : chave do repositório — usada para assinar tags
# =============================================================================

generate_keys() {
  # Gera a chave de delegação para o seu usuário
  docker trust key generate "${REGISTRY_USER}"
  # Arquivo gerado: ~/.docker/trust/private/<fingerprint>.key
}

# =============================================================================
# 3. Adicionar assinante a um repositório
# =============================================================================

add_signer() {
  # Usa a chave pública gerada no passo anterior
  docker trust signer add \
    --key "${REGISTRY_USER}.pub" \
    "${REGISTRY_USER}" \
    "${IMAGE_NAME}"
}

# =============================================================================
# 4. Build, push e assinatura
#
# Com DOCKER_CONTENT_TRUST=1, o "docker push" assina automaticamente a imagem.
# Na primeira vez, solicitará criação da root key e targets key.
# =============================================================================

build_and_push_signed() {
  enable_dct

  docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

  # Push assina a imagem no Notary server do Docker Hub
  docker push "${IMAGE_NAME}:${IMAGE_TAG}"
}

# =============================================================================
# 5. Verificar assinaturas de uma imagem
# =============================================================================

inspect_trust() {
  docker trust inspect --pretty "${IMAGE_NAME}:${IMAGE_TAG}"
}

inspect_trust_nginx() {
  # nginx é assinado oficialmente pelo Docker
  docker trust inspect --pretty nginx:latest
}

# =============================================================================
# 6. Pull com verificação de assinatura
# =============================================================================

pull_verified() {
  enable_dct
  docker pull "${IMAGE_NAME}:${IMAGE_TAG}"
  # Falha com erro se a imagem não estiver assinada ou a assinatura for inválida
}

# =============================================================================
# 7. Testar bloqueio de imagem não assinada
# =============================================================================

test_unsigned_blocked() {
  enable_dct
  # ubuntu:latest não tem assinatura oficial no Docker Hub Notary
  # Este comando deve falhar com: "No valid trust data"
  docker pull ubuntu:latest || echo "✅ Pull bloqueado — imagem não assinada"
}

# =============================================================================
# 8. Revogar uma tag assinada
# =============================================================================

revoke_tag() {
  docker trust revoke "${IMAGE_NAME}:${IMAGE_TAG}"
  echo "Tag ${IMAGE_TAG} revogada — não pode mais ser puxada com DCT ativo"
}

# =============================================================================
# Referência: variáveis de ambiente relacionadas ao DCT
#
#   DOCKER_CONTENT_TRUST=1          habilita verificação em pull/push/run/build
#   DOCKER_CONTENT_TRUST_SERVER=URL servidor Notary alternativo (ex: Harbor)
# =============================================================================
