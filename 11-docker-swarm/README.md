# 11 — Docker Swarm com Vagrant

Laboratório de **Docker Swarm** com três VMs Ubuntu 18.04 provisionadas via Vagrant: um nó **manager** e dois **workers**. O manager expõe a API do Docker na porta **2375** (sem TLS) para que um cliente remoto controle o cluster via `DOCKER_HOST`.

## O que este módulo demonstra

- Provisionamento de cluster com Vagrant + VirtualBox
- Inicialização do Swarm (`docker swarm init`)
- Join de workers com token
- Exposição do socket Docker via TCP (`2375`) — **apenas para laboratório**
- Gerenciamento remoto do cluster (`DOCKER_HOST`)
- Criação, inspeção e **scale** de serviços (`docker service`)

## Arquitetura

### Topologia da rede

```text
                    rede privada 192.168.56.0/24
┌──────────────────────────────────────────────────────────────────┐
│                                                                  │
│   ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐│
│   │    node-1       │   │    node-2       │   │    node-3       ││
│   │  swarm-1        │   │  swarm-2        │   │  swarm-3        ││
│   │ 192.168.56.11   │   │ 192.168.56.12   │   │ 192.168.56.13   ││
│   │                 │   │                 │   │                 ││
│   │  MANAGER        │◄──┤  WORKER         │   │  WORKER         ││
│   │  (Leader)       │   │                 │   │                 ││
│   └────────┬────────┘   └─────────────────┘   └─────────────────┘│
│            │                                                     │
│            │  :2377  cluster management (Raft, gossip)           │
│            │  :2375  Docker API TCP (lab — sem TLS)              │
│            │  :7946  overlay / node discovery (UDP/TCP)          │
│            │  :4789  VXLAN overlay data plane (UDP)              │
└────────────┼─────────────────────────────────────────────────────┘
             │
             │  DOCKER_HOST=192.168.56.11:2375
             ▼
      ┌──────────────┐
      │   Cliente    │  máquina host (fora do Swarm)
      │  docker CLI  │
      └──────────────┘
```

| VM | Hostname | IP | Papel |
|----|----------|-----|-------|
| `swarm-1` | `node-1` | `192.168.56.11` | Manager (leader) |
| `swarm-2` | `node-2` | `192.168.56.12` | Worker |
| `swarm-3` | `node-3` | `192.168.56.13` | Worker |

### Conceitos do Docker Swarm

**Swarm mode** transforma um conjunto de hosts Docker em um **cluster orquestrado**. Um ou mais nós atuam como **managers** (estado do cluster, agendamento de tarefas); os demais são **workers** (executam containers).

| Conceito | Descrição |
|----------|-----------|
| **Node** | Instância Docker participando do Swarm (manager ou worker) |
| **Service** | Definição declarativa de um app (imagem, réplicas, portas, redes) |
| **Task** | Unidade de trabalho: um container agendado em um nó |
| **Replica** | Cópia de um serviço; o scheduler distribui tasks entre os nós |
| **Overlay network** | Rede virtual que conecta containers em hosts diferentes |

### Portas do Swarm

| Porta | Protocolo | Uso |
|-------|-----------|-----|
| **2377** | TCP | Comunicação entre managers e join de nós (`docker swarm join`) |
| **2375** | TCP | API Docker remota **sem TLS** (configuração manual neste lab) |
| **7946** | TCP/UDP | Descoberta de nós e comunicação entre membros do cluster |
| **4789** | UDP | Tráfego de dados da rede overlay (VXLAN) |

> A porta **2376** é a API Docker com TLS. Em produção, use TLS ou SSH — nunca exponha `2375` na internet.

### Fluxo de uma requisição ao serviço

Quando você cria `nginx-service` com `-p 8080:80` e `--replicas 3`:

```text
Cliente (curl :8080)
        │
        ▼
┌───────────────────┐     routing mesh (ingress)
│  qualquer nó      │ ──► encaminha para uma task do serviço
│  :8080 publicado  │
└───────────────────┘
        │
        ├──► task nginx em node-1
        ├──► task nginx em node-2
        └──► task nginx em node-3
```

O **routing mesh** publica a porta em **todos os nós** do Swarm. Por isso `curl 192.168.56.11:8080`, `curl 192.168.56.12:8080` e `curl 192.168.56.13:8080` podem responder mesmo que a task não esteja naquele nó.

### Expor o socket na porta 2375 (teoria)

Por padrão, o Docker escuta apenas no **Unix socket** (`/var/run/docker.sock`). Para controlar o daemon remotamente via CLI, é preciso habilitar um listener **TCP**.

No `docker.service`, a linha `ExecStart` ganha um host adicional:

```ini
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
```

| Flag | Significado |
|------|-------------|
| `-H fd://` | Mantém o socket Unix local (uso na própria VM) |
| `-H tcp://0.0.0.0:2375` | Escuta em todas as interfaces na porta 2375 |

**Riscos:** qualquer host na rede que alcance essa porta tem controle total do Docker (equivalente a root no host). Use somente em rede isolada de laboratório.

No cliente, a variável `DOCKER_HOST` aponta a CLI para o daemon remoto:

```bash
export DOCKER_HOST=192.168.56.11:2375
docker node ls   # executa no manager, não localmente
```

Alternativa moderna: `docker context` (sem editar o `docker.service`).

## Pré-requisitos

- [Vagrant](https://www.vagrantup.com/) e [VirtualBox](https://www.virtualbox.org/)
- ~3 GB de RAM livre (3 VMs × 1 GB)
- Rede `192.168.56.0/24` disponível (padrão do Vagrant)

> Este módulo é **autocontido**: inclui `Vagrantfile` e todos os passos para subir o cluster. Os módulos [12](../12-docker-swarm-ha-proxy/) e [13](../13-docker-swarm-dns/) usam a mesma infraestrutura e podem ser feitos de forma independente.

## Subir o cluster Swarm

Guia detalhado também em [docs/guias/swarm-cluster-setup.md](../docs/guias/swarm-cluster-setup.md).

### 1. VMs

```bash
cd 11-docker-swarm
vagrant up
```

| VM | Hostname | IP | Papel |
|----|----------|-----|-------|
| `swarm-1` | `node-1` | `192.168.56.11` | Manager |
| `swarm-2` | `node-2` | `192.168.56.12` | Worker |
| `swarm-3` | `node-3` | `192.168.56.13` | Worker |

```bash
vagrant ssh swarm-1   # manager
vagrant ssh swarm-2   # worker
vagrant ssh swarm-3   # worker
```

### 2. Inicializar o Swarm (manager — `swarm-1`)

```bash
docker swarm init --advertise-addr 192.168.56.11
docker node ls
sudo ss -lnp | grep 2377
```

### 3. Expor API Docker na porta 2375 (manager)

Editar `/lib/systemd/system/docker.service` e adicionar `-H tcp://0.0.0.0:2375` ao `ExecStart` (ver seção teórica abaixo). Depois:

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
ss -lnp | grep 2375
```

### 4. Workers entram no cluster (`swarm-2` e `swarm-3`)

No manager:

```bash
docker swarm join-token worker
```

Em cada worker:

```bash
docker swarm join --token <WORKER_TOKEN> 192.168.56.11:2377
```

### 5. Cliente remoto (máquina host)

```bash
export DOCKER_HOST=192.168.56.11:2375
docker node ls   # deve listar 3 nós (1 Leader + 2 workers)
```

## Passo a passo do laboratório

Os comandos completos estão em [commands.bash](commands.bash). Com o cluster no ar (passos acima), continue com:

```bash
docker service create -d -p 8080:80 --replicas 3 --name nginx-service nginx:latest
docker service ls
docker service ps nginx-service

curl 192.168.56.11:8080
curl 192.168.56.12:8080
curl 192.168.56.13:8080

docker service scale nginx-service=10
docker service scale nginx-service=2
docker service scale nginx-service=4
```

## Comandos úteis de inspeção

```bash
# Nós e tarefas
docker node ls
docker node inspect node-2
docker node ps node-2

# Serviços
docker service inspect nginx-service
docker service ps nginx-service
docker service logs -f nginx-service

# Rede overlay do serviço
docker network ls
docker network inspect <NETWORK_ID>
```

## Encerrar o ambiente

```bash
vagrant halt          # desliga VMs
vagrant destroy -f    # remove VMs
```

## Referências

- [Subir o cluster Swarm](../docs/guias/swarm-cluster-setup.md) — guia compartilhado (módulos 11, 12 e 13)
- [Docker Swarm mode overview](https://docs.docker.com/engine/swarm/)
- [Manage nodes in a swarm](https://docs.docker.com/engine/swarm/manage-nodes/)
- [Deploy services to a swarm](https://docs.docker.com/engine/swarm/services/)
