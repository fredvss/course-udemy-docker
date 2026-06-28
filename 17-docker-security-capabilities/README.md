# 17 — Docker Security: Capabilities, Seccomp, Secrets e Content Trust

Módulo dedicado à camada de segurança do ecossistema Docker. Cobre quatro mecanismos complementares que reduzem a superfície de ataque de containers em produção.

## O que este módulo demonstra

- **Linux Capabilities** — reduzir privilégios de root sem remover o usuário
- **Seccomp** — filtrar syscalls permitidas por container
- **Docker Secrets** — injetar segredos em serviços Swarm sem expô-los em variáveis de ambiente
- **Docker Content Trust (DCT)** — garantir que apenas imagens assinadas sejam executadas

## Estrutura

```text
17-docker-security-capabilities/
├── seccomp/
│   ├── default.json          # perfil seccomp padrão do Docker (referência)
│   └── custom-restricted.json # perfil customizado: bloqueia syscalls de rede e ptrace
├── secrets/
│   ├── docker-compose.yaml   # stack com secrets gerenciados pelo Swarm
│   └── app/
│       └── Dockerfile        # imagem que lê o secret via arquivo em /run/secrets/
└── content-trust/
    └── commands.bash         # habilitar DCT, assinar e verificar imagens
```

---

## 1. Linux Capabilities

O kernel Linux divide os privilégios de `root` em ~40 **capabilities** independentes. Por padrão, o Docker concede um subconjunto seguro — e é possível adicionar ou remover capabilities por container.

### Capabilities padrão concedidas pelo Docker

```text
CHOWN, DAC_OVERRIDE, FSETID, FOWNER, MKNOD, NET_RAW,
SETGID, SETUID, SETFCAP, SETPCAP, NET_BIND_SERVICE,
SYS_CHROOT, KILL, AUDIT_WRITE
```

### Remover todas e adicionar só o necessário (princípio do menor privilégio)

```bash
# Container que só precisa ligar na porta 80 (NET_BIND_SERVICE)
docker run --rm \
  --cap-drop ALL \
  --cap-add NET_BIND_SERVICE \
  nginx:alpine

# Ver capabilities ativas dentro do container
docker run --rm alpine sh -c "apk add -q libcap && capsh --print"
```

### Comparação

| Flag | Efeito |
|------|--------|
| `--cap-drop ALL` | Remove todas as capabilities |
| `--cap-add <CAP>` | Adiciona capability específica |
| `--privileged` | Concede **todas** as capabilities + acesso a devices — evitar em produção |

> **Regra prática:** use `--cap-drop ALL` + `--cap-add` somente o necessário. Nunca use `--privileged` em produção.

---

## 2. Seccomp (Secure Computing Mode)

Seccomp filtra as **syscalls** que um container pode fazer ao kernel. Mesmo que um atacante comprometa o processo dentro do container, ele não consegue executar syscalls bloqueadas.

### Perfis disponíveis neste módulo

| Arquivo | Descrição |
|---------|-----------|
| [seccomp/default.json](seccomp/default.json) | Perfil padrão do Docker (~300 syscalls permitidas) |
| [seccomp/custom-restricted.json](seccomp/custom-restricted.json) | Perfil restrito: bloqueia `ptrace`, criação de sockets raw e namespaces |

### Usar um perfil customizado

```bash
# Aplicar o perfil restrito
docker run --rm \
  --security-opt seccomp=seccomp/custom-restricted.json \
  alpine sh

# Desabilitar seccomp completamente (não recomendado em produção)
docker run --rm \
  --security-opt seccomp=unconfined \
  alpine sh
```

### Testar que o bloqueio funciona

```bash
# ptrace bloqueado pelo perfil customizado
docker run --rm \
  --security-opt seccomp=seccomp/custom-restricted.json \
  alpine sh -c "strace ls 2>&1 || echo 'ptrace bloqueado pelo seccomp'"
```

### Estrutura de um perfil seccomp

```json
{
  "defaultAction": "SCMP_ACT_ERRNO",   // bloqueia tudo por padrão
  "syscalls": [
    {
      "names": ["read", "write", "exit"],
      "action": "SCMP_ACT_ALLOW"       // permite explicitamente
    }
  ]
}
```

| Ação | Efeito |
|------|--------|
| `SCMP_ACT_ALLOW` | Permite a syscall |
| `SCMP_ACT_ERRNO` | Retorna erro (EPERM) |
| `SCMP_ACT_KILL` | Mata o processo imediatamente |
| `SCMP_ACT_LOG` | Permite mas registra no syslog |

---

## 3. Docker Secrets

Secrets são dados sensíveis (senhas, tokens, certificados) injetados como **arquivos** em `/run/secrets/<nome>` dentro do container — nunca como variáveis de ambiente, que ficam visíveis em `docker inspect`.

> Secrets são um recurso do **Docker Swarm**. Para uso local sem Swarm, veja a seção "Alternativa local" abaixo.

### Como funciona

```text
1. Secret criado no manager: criptografado no Raft log do Swarm
2. Distribuído via canal TLS mútuo apenas aos nós com tasks autorizadas
3. Montado em tmpfs em /run/secrets/<nome> — nunca escrito em disco
4. Removido automaticamente quando a task para
```

### Exemplo rápido

```bash
# Criar um secret
echo "minha-senha-super-secreta" | docker secret create db_password -

# Listar secrets
docker secret ls

# Usar em um serviço
docker service create \
  --name myapp \
  --secret db_password \
  alpine sh -c "cat /run/secrets/db_password"
```

### Stack com secrets: [secrets/docker-compose.yaml](secrets/docker-compose.yaml)

```bash
# Criar os secrets antes do deploy
echo "wordpress_db_pass" | docker secret create wp_db_password -
echo "wordpress_root_pass" | docker secret create wp_db_root_password -

docker stack deploy -c secrets/docker-compose.yaml sec-stack
```

### Alternativa local (sem Swarm) — secret via arquivo bind mount

```bash
echo "senha-local" > /tmp/db_password.txt
docker run --rm \
  -v /tmp/db_password.txt:/run/secrets/db_password:ro \
  alpine cat /run/secrets/db_password
```

### Por que não variáveis de ambiente?

```bash
# ❌ Exposto em docker inspect e em /proc/<pid>/environ
docker run -e DB_PASSWORD=secreta alpine env | grep DB_PASSWORD

# ✅ Não aparece em inspect, não está em variáveis de ambiente
docker run --secret db_password alpine cat /run/secrets/db_password
```

---

## 4. Docker Content Trust (DCT)

DCT usa assinaturas digitais (The Update Framework — TUF) para garantir que a imagem executada é exatamente a que foi publicada pelo autor — sem adulteração no registro.

### Habilitar DCT

```bash
export DOCKER_CONTENT_TRUST=1

# A partir daqui, docker pull/run/build/push verificam/exigem assinatura
docker pull nginx:latest   # falha se a imagem não estiver assinada
```

### Comandos detalhados: [content-trust/commands.bash](content-trust/commands.bash)

### Fluxo de assinatura

```text
Publisher:
  1. docker trust key generate <seu-nome>
  2. docker trust signer add --key pub.pem <seu-nome> <repo>
  3. docker push <repo>:<tag>   # com DOCKER_CONTENT_TRUST=1 → assina ao fazer push

Consumer:
  4. export DOCKER_CONTENT_TRUST=1
  5. docker pull <repo>:<tag>   # verifica a assinatura antes de baixar
```

### Inspecionar assinatura de uma imagem

```bash
docker trust inspect --pretty nginx:latest
```

---

## Comparação dos mecanismos

| Mecanismo | Camada protegida | Escopo |
|-----------|-----------------|--------|
| Capabilities | Privilégios do processo | Runtime |
| Seccomp | Syscalls ao kernel | Runtime |
| Secrets | Dados sensíveis em repouso/trânsito | Dados |
| Content Trust | Integridade da imagem | Supply chain |

> Use os quatro em conjunto — cada um protege uma camada diferente.

## Referências

- [Docker security — documentação oficial](https://docs.docker.com/engine/security/)
- [Linux capabilities — man 7 capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)
- [Seccomp security profiles](https://docs.docker.com/engine/security/seccomp/)
- [Docker Secrets](https://docs.docker.com/engine/swarm/secrets/)
- [Docker Content Trust](https://docs.docker.com/engine/security/trust/)
