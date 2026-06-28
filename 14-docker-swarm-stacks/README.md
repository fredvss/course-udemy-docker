# 14 — Docker Swarm: Stacks (Ghost + MySQL)

Extensão do laboratório Swarm ([módulo 11](../11-docker-swarm/)): um **stack** implanta dois serviços interligados — o blog **Ghost** e o banco de dados **MySQL** — com redes overlay isoladas, volumes persistentes e política de reinicialização.

Evolução natural do [módulo 09](../09-docker-compose/) (Docker Compose local): o mesmo conceito de arquivo declarativo, agora gerenciado pelo Swarm com `docker stack deploy`.

## O que este módulo demonstra

- Declaração de um stack multi-serviço com `docker-compose.yaml`
- Diferenças entre `docker compose` (local) e `docker stack deploy` (Swarm)
- Redes **overlay** para comunicação entre serviços em nós distintos
- Volumes nomeados persistentes gerenciados pelo Swarm
- Política de reinicialização com `deploy.restart_policy`
- Isolamento de rede: `ghost` acessa `db` apenas pela rede interna

## Arquitetura

### Visão geral

```text
  cliente (navegador / curl)
  ┌────────────────────────────────────────────────────────────┐
  │                                                            │
  │           http://<IP-do-nó>:8080                          │
  │                                                            │
  └─────────────────────┬──────────────────────────────────────┘
                        │
                        ▼
  Docker Swarm Cluster
  ┌────────────────────────────────────────────────────────────┐
  │                                                            │
  │   ┌─────────────────────────────┐                         │
  │   │  ghost (porta 8080:2368)    │ ── ghost-network        │
  │   │  ghost:5-alpine             │    (acesso externo)     │
  │   │  réplicas: 1                │                         │
  │   └──────────────┬──────────────┘                         │
  │                  │  ghost-mysql-network                   │
  │                  │  (rede interna)                        │
  │   ┌──────────────▼──────────────┐                         │
  │   │  db (sem porta publicada)   │                         │
  │   │  mysql:8.0                  │                         │
  │   │  réplicas: 1                │                         │
  │   └─────────────────────────────┘                         │
  │                                                            │
  └────────────────────────────────────────────────────────────┘
```

### Como o tráfego flui

```text
1. Cliente acessa <IP-do-nó>:8080
2. Routing mesh do Swarm encaminha para a task do ghost
3. Ghost se conecta ao db via rede overlay ghost-mysql-network
4. MySQL responde — Ghost serve a página ao cliente
```

### Redes e volumes

| Recurso | Nome | Finalidade |
|---------|------|-----------|
| Rede | `ghost-network` | Expõe o Ghost ao mundo externo (overlay) |
| Rede | `ghost-mysql-network` | Canal privado Ghost ↔ MySQL (overlay) |
| Volume | `ghost-data` | Conteúdo do blog (temas, imagens, posts) |
| Volume | `ghost-mysql-data` | Dados do banco MySQL |

### Stack vs Compose

| Aspecto | `docker compose` (módulo 09) | `docker stack deploy` (módulo 14) |
|---------|------------------------------|-----------------------------------|
| Ambiente | Máquina local | Cluster Swarm |
| `depends_on` | Suportado | **Ignorado** |
| `restart` | Suportado | **Ignorado** (usar `deploy.restart_policy`) |
| Redes | `bridge` (padrão) | `overlay` (obrigatório para multi-nó) |
| Escala | `--scale` | `deploy.replicas` |
| Rolling update | Não | Sim (`deploy.update_config`) |

## Pré-requisitos

- Cluster Docker Swarm ativo (ao menos 1 manager)
- Docker instalado no manager
- Guia de setup: [docs/guias/swarm-cluster-setup.md](../docs/guias/swarm-cluster-setup.md)

> Este módulo inclui um `Vagrantfile` que sobe 3 VMs (manager `192.168.56.11` + 2 workers). Consulte o [guia de setup do cluster](../docs/guias/swarm-cluster-setup.md) para os passos detalhados.

## Passo a passo do laboratório

### 1. Subir as VMs e inicializar o Swarm

```bash
cd 14-docker-swarm-stacks
vagrant up

# No manager (swarm-1)
vagrant ssh swarm-1
docker swarm init --advertise-addr 192.168.56.11

# Obter token e adicionar workers (swarm-2 e swarm-3)
docker swarm join-token worker
# Em cada worker: docker swarm join --token <TOKEN> 192.168.56.11:2377
```

### 2. Fazer o deploy do stack

```bash
# Na máquina host, apontando para o manager
export DOCKER_HOST=192.168.56.11:2375

docker stack deploy -c docker-compose.yaml ghost-stack
```

### 3. Verificar o estado do stack

```bash
docker stack ls
# NAME          SERVICES
# ghost-stack   2

docker stack services ghost-stack
# ID   NAME               MODE         REPLICAS   IMAGE
# ...  ghost-stack_ghost  replicated   1/1        ghost:5-alpine
# ...  ghost-stack_db     replicated   1/1        mysql:8.0

docker stack ps ghost-stack
```

> O serviço `ghost` pode reiniciar algumas vezes enquanto o MySQL ainda está iniciando — isso é esperado. O `restart_policy` garante que ele volte automaticamente.

### 4. Acessar o Ghost

```bash
# Abra no navegador:
http://192.168.56.11:8080

# Ou via curl:
curl -I http://192.168.56.11:8080
```

> Graças ao **routing mesh** do Swarm, qualquer nó do cluster responde na porta 8080 — `192.168.56.12` e `192.168.56.13` também funcionam.

Painel de administração: `http://192.168.56.11:8080/ghost`

### 5. Inspecionar logs

```bash
docker service logs -f ghost-stack_ghost
docker service logs -f ghost-stack_db
```

## Comandos úteis

```bash
# listar tasks e seus nós
docker stack ps ghost-stack

# escalar o ghost (ex.: 2 réplicas)
docker service scale ghost-stack_ghost=2

# inspecionar um serviço
docker service inspect --pretty ghost-stack_ghost

# ver volumes criados
docker volume ls | grep ghost
```

## Limpeza

```bash
export DOCKER_HOST=192.168.56.11:2375

# remover o stack (serviços, redes)
docker stack rm ghost-stack

# remover volumes (dados persistentes — irreversível)
docker volume rm ghost-data ghost-mysql-data

# desligar ou destruir as VMs
vagrant halt
vagrant destroy -f
```

## Referências

- [Subir o cluster Swarm](../docs/guias/swarm-cluster-setup.md) — guia compartilhado (módulos 11, 12 e 13)
- [Docker Stacks — documentação oficial](https://docs.docker.com/engine/swarm/stack-deploy/)
- [Ghost — imagem oficial](https://hub.docker.com/_/ghost)
- [Módulo 09 — Docker Compose local](../09-docker-compose/) — origem do conceito de arquivo declarativo
- [Módulo 11 — Docker Swarm básico](../11-docker-swarm/) — fundamentos do cluster
