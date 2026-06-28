# Subir o cluster Swarm (Vagrant)

Guia de bootstrap compartilhado pelos módulos [11](../../11-docker-swarm/), [12](../../12-docker-swarm-ha-proxy/) e [13](../../13-docker-swarm-dns/). Cada um inclui o mesmo `Vagrantfile` — execute os passos **na pasta do módulo** que estiver usando.

> **Atenção:** só um cluster pode usar a rede `192.168.56.0/24` por vez. Se outro módulo Swarm estiver ativo, rode `vagrant halt` na pasta anterior antes de subir um novo.

## Topologia

| VM | Hostname | IP | Papel |
|----|----------|-----|-------|
| `swarm-1` | `node-1` | `192.168.56.11` | Manager (leader) |
| `swarm-2` | `node-2` | `192.168.56.12` | Worker |
| `swarm-3` | `node-3` | `192.168.56.13` | Worker |

## 1. Subir as VMs

```bash
vagrant up
```

Acesso SSH:

```bash
vagrant ssh swarm-1   # manager
vagrant ssh swarm-2   # worker
vagrant ssh swarm-3   # worker
```

## 2. Inicializar o Swarm (manager — `swarm-1`)

```bash
docker swarm init --advertise-addr 192.168.56.11
docker node ls
sudo ss -lnp | grep 2377   # porta de gerenciamento do cluster
```

## 3. Expor API Docker na porta 2375 (manager)

Por padrão o Docker escuta só no Unix socket. Para controlar o cluster da máquina host via `DOCKER_HOST`, edite `/lib/systemd/system/docker.service` e altere `ExecStart`:

```ini
ExecStart=/usr/bin/dockerd -H fd:// -H tcp://0.0.0.0:2375
```

Depois:

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
ss -lnp | grep 2375
docker node ls
```

> **Somente laboratório.** A porta 2375 expõe a API sem TLS — qualquer host na rede tem controle total do Docker.

## 4. Workers entram no cluster (`swarm-2` e `swarm-3`)

No **manager**, obter o token:

```bash
docker swarm join-token worker
```

Em **cada worker**:

```bash
docker swarm join --token <WORKER_TOKEN> 192.168.56.11:2377
```

## 5. Cliente remoto (máquina host)

Na sua máquina (fora das VMs):

```bash
export DOCKER_HOST=192.168.56.11:2375
docker node ls
```

Saída esperada — 3 nós, 1 manager e 2 workers:

```text
ID        HOSTNAME   STATUS    AVAILABILITY   MANAGER STATUS
...       node-1     Ready     Active         Leader
...       node-2     Ready     Active
...       node-3     Ready     Active
```

Para tornar permanente na sessão, adicione ao `~/.bashrc`:

```bash
export DOCKER_HOST=192.168.56.11:2375
```

## 6. Encerrar o ambiente

```bash
vagrant halt          # desliga VMs
vagrant destroy -f    # remove VMs
```

## Portas relevantes

| Porta | Uso |
|-------|-----|
| 2377 | Gerenciamento do Swarm (`swarm join`) |
| 2375 | API Docker remota (lab — sem TLS) |
| 7946 | Descoberta de nós (TCP/UDP) |
| 4789 | Overlay VXLAN (UDP) |

## Referências

- [Módulo 11 — teoria e arquitetura](../../11-docker-swarm/)
- [Docker Swarm mode overview](https://docs.docker.com/engine/swarm/)
