# 16 — Docker Swarm: Rolling Update e Rollback Automático

Demonstra como o Swarm protege o cluster durante um **rolling update**: se a nova versão de uma imagem falha no healthcheck, o Swarm interrompe o update e **reverte automaticamente** para a versão anterior — sem intervenção manual.

A imagem `flaskapp` é a mesma construída no [módulo 06](../06-build-python-healthcheck/), publicada no Docker Hub em duas tags: `healthy` e `unhealthy`.

## O que este módulo demonstra

- **Rolling update** controlado: `parallelism`, `order` e `failure_action`
- Swarm **bloqueando** um deploy de imagem com healthcheck falho
- **Rollback automático** ao estado anterior quando o update falha
- Update bem-sucedido de 2 em 2 réplicas com `start-first` (zero downtime)

## Conceitos de `update_config`

| Parâmetro | Valor | Efeito |
|-----------|-------|--------|
| `parallelism` | `2` | Atualiza **2 réplicas por vez** |
| `failure_action` | `rollback` | Se qualquer task falhar o healthcheck, **reverte tudo** |
| `order` | `start-first` | Sobe a nova task **antes** de derrubar a antiga — zero downtime |

### Como o Swarm decide se uma task "passou"

```text
1. Swarm sobe a nova task (start-first)
2. Aguarda o container entrar em estado "healthy" (via HEALTHCHECK da imagem)
3. ✅ Saudável → remove a task antiga e avança para o próximo par
4. ❌ Não saudável → interrompe o update, executa rollback automático
```

## Pré-requisitos

- Cluster Docker Swarm ativo (ao menos 1 manager)
- `DOCKER_HOST` apontando para o manager, ou comandos executados dentro do manager
- A imagem `mateusmuller2/flaskapp` deve estar disponível no Docker Hub (já publicada)

> Para subir um Swarm de um nó só: `docker swarm init`

## Passo a passo do laboratório

### Passo 1 — Deploy inicial com imagem saudável

No [docker-compose.yaml](docker-compose.yaml), a linha ativa é:

```yaml
image: mateusmuller2/flaskapp:healthy
```

```bash
export DOCKER_HOST=192.168.56.11:2375   # ajustar se necessário

docker stack deploy -c docker-compose.yaml app-stack

docker stack services app-stack
# REPLICAS deve chegar a 10/10

docker stack ps app-stack
# todas as tasks devem estar em "Running"
```

Validar que a aplicação responde:

```bash
curl http://192.168.56.11:5000/health
# {"status": "healthy"}
```

---

### Passo 2 — Tentar atualizar para a versão não saudável

Edite o [docker-compose.yaml](docker-compose.yaml) e troque a imagem ativa:

```yaml
# image: mateusmuller2/flaskapp:healthy   ← comentar
image: mateusmuller2/flaskapp:unhealthy   # ← descomentar
```

```bash
docker stack deploy -c docker-compose.yaml app-stack
```

Acompanhe o update em tempo real:

```bash
docker service ps app-stack_flaskapp --no-trunc
```

**O que acontece:**

```text
1. Swarm sobe 2 novas tasks com :unhealthy
2. Healthcheck falha → tasks entram em estado "failed"
3. failure_action: rollback → Swarm reverte para :healthy automaticamente
4. Todas as 10 réplicas voltam a rodar com :healthy
```

```bash
docker service inspect --pretty app-stack_flaskapp | grep -A5 "UpdateStatus"
# State: rollback_completed
# Message: rollback completed
```

---

### Passo 3 — Atualizar para nginx (imagem saudável, rolling update completo)

Edite o [docker-compose.yaml](docker-compose.yaml):

```yaml
# image: mateusmuller2/flaskapp:unhealthy   ← comentar
image: nginx                                # ← descomentar
```

```bash
docker stack deploy -c docker-compose.yaml app-stack
```

Acompanhe o rolling update de 2 em 2:

```bash
watch docker service ps app-stack_flaskapp
```

**O que acontece:**

```text
1. Swarm sobe 2 tasks nginx (start-first — zero downtime)
2. Healthcheck passa → as 2 tasks flaskapp antigas são removidas
3. Repete para o próximo par... até 10/10 nginx rodando
```

```bash
curl http://192.168.56.11:5000
# página padrão do nginx
```

## Comandos úteis

```bash
# acompanhar estado das tasks
docker service ps app-stack_flaskapp

# ver histórico de updates/rollbacks
docker service inspect --pretty app-stack_flaskapp

# forçar rollback manualmente (se necessário)
docker service rollback app-stack_flaskapp

# logs do serviço
docker service logs -f app-stack_flaskapp
```

## Limpeza

```bash
docker stack rm app-stack

# sair do Swarm (se criado só para este lab)
docker swarm leave --force
```

## Referências

- [Módulo 06 — Flask + healthcheck](../06-build-python-healthcheck/) — origem da imagem `flaskapp`
- [Docker Swarm — rolling updates](https://docs.docker.com/engine/swarm/swarm-tutorial/rolling-update/)
- [Docker `update_config` — referência](https://docs.docker.com/reference/compose-file/deploy/#update_config)
