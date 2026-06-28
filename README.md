# Curso Docker — Udemy

Material prático de um curso de Docker: scripts de isolamento Linux, builds progressivos com Node.js, Python e Go, restart policies, Docker Compose, **Docker Swarm** (com Vagrant) e guias de referência sobre containers e rede.

## Pré-requisitos

- Linux (ou WSL2)
- [Docker Engine](https://docs.docker.com/engine/install/) instalado
- [Docker Compose v2](https://docs.docker.com/compose/) (incluso no Docker Desktop e nas instalações recentes do Engine)
- Para o módulo 01: `sudo`, `debootstrap` ou acesso root
- Para os módulos 11, 12, 13 e 14: [Vagrant](https://www.vagrantup.com/) e [VirtualBox](https://www.virtualbox.org/) (~3 GB de RAM livre)
- Para o módulo 15: ~4 GB de RAM livre (VM NFS adicional)

## Estrutura do repositório

| Pasta | Tema | Documentação |
|-------|------|--------------|
| [01-chroot_scripts](01-chroot_scripts/) | Chroot, namespaces e isolamento manual | [README](01-chroot_scripts/README.md) |
| [02-build-node](02-build-node/) | Primeiro Dockerfile — Node.js básico | [README](02-build-node/README.md) |
| [03-build-node-volume](03-build-node-volume/) | `VOLUME`, `ENTRYPOINT` e healthcheck inicial | [README](03-build-node-volume/README.md) |
| [04-build-node-entrypoint](04-build-node-entrypoint/) | `CMD`, `ENTRYPOINT` e histórico de comandos | [README](04-build-node-entrypoint/README.md) |
| [05-build-node-healthcheck](05-build-node-healthcheck/) | `HEALTHCHECK` completo em Node.js | [README](05-build-node-healthcheck/README.md) |
| [06-build-python-healthcheck](06-build-python-healthcheck/) | Flask + healthcheck em Python | [README](06-build-python-healthcheck/README.md) |
| [07-build-go-multi-staging](07-build-go-multi-staging/) | Multi-stage build — Go para imagem `scratch` | [README](07-build-go-multi-staging/README.md) |
| [08-restart-policies](08-restart-policies/) | Restart policies (`no`, `on-failure`, `always`…) | [README](08-restart-policies/README.md) |
| [09-docker-compose](09-docker-compose/) | Compose básico — nginx, builds e `depends_on` | [README](09-docker-compose/README.md) |
| [10-docker-compose-ghost](10-docker-compose-ghost/) | Compose avançado — Ghost + MySQL, volumes, redes, healthcheck | [README](10-docker-compose-ghost/README.md) |
| [11-docker-swarm](11-docker-swarm/) | Swarm com Vagrant — cluster, `DOCKER_HOST`, scale de serviços | [README](11-docker-swarm/README.md) |
| [12-docker-swarm-ha-proxy](12-docker-swarm-ha-proxy/) | Swarm — VIP vs DNSRR, HAProxy global e balanceamento | [README](12-docker-swarm-ha-proxy/README.md) |
| [13-docker-swarm-dns](13-docker-swarm-dns/) | Swarm — BIND9, DNS round robin e nginx via routing mesh | [README](13-docker-swarm-dns/README.md) |
| [14-docker-swarm-stacks](14-docker-swarm-stacks/) | Swarm Stacks — Ghost + MySQL com redes overlay e volumes persistentes | [README](14-docker-swarm-stacks/README.md) |
| [15-docker-swarm-nfs](15-docker-swarm-nfs/) | Swarm — WordPress em HA com volume NFS compartilhado e placement constraints | [README](15-docker-swarm-nfs/README.md) |

## Documentação

Índice completo em **[docs/README.md](docs/README.md)**.

### Fundamentos Linux e Docker

Conceitos teóricos que sustentam o restante do curso:

- [Containers Linux — o que são e como funcionam](docs/fundamentos/containers-linux.md)
- [Redes Linux, Docker e containers](docs/fundamentos/redes-linux-docker.md)

### Guias práticos

- [Docker HEALTHCHECK — guia prático](docs/guias/healthcheck.md) — usado nos módulos 05 e 06
- [Subir o cluster Swarm](docs/guias/swarm-cluster-setup.md) — bootstrap compartilhado dos módulos 11, 12 e 13

### Recursos extras

- [Anotações em PDF](docs/recursos/docker_annotations.pdf)
- [Mapa mental Xournal++](docs/recursos/Docker.xopp)

## Ordem sugerida

```text
01-chroot_scripts
    ↓
02-build-node → 03-build-node-volume → 04-build-node-entrypoint
    ↓
05-build-node-healthcheck → 06-build-python-healthcheck
    ↓
07-build-go-multi-staging → 08-restart-policies
    ↓
09-docker-compose → 10-docker-compose-ghost
    ↓
11-docker-swarm → 12-docker-swarm-ha-proxy
              ↘
                13-docker-swarm-dns
                    ↓
              14-docker-swarm-stacks
                    ↓
              15-docker-swarm-nfs
```

Os módulos **11, 12 e 13** são independentes entre si — cada um inclui o mesmo `Vagrantfile` e os passos para subir o cluster. Guia compartilhado: [docs/guias/swarm-cluster-setup.md](docs/guias/swarm-cluster-setup.md).

Leia os fundamentos em `docs/fundamentos/` a qualquer momento — eles complementam os exercícios práticos.

## Comandos rápidos

Build e execução genéricos (ajuste o nome da imagem conforme o módulo):

```bash
cd 02-build-node
docker build -t node-app .
docker run --rm -p 3000:3000 node-app
```

Com variáveis de build:

```bash
docker build --build-arg PORT=8080 --build-arg VERSION=2.0.0 -t node-app .
```

Docker Compose (módulos 09 e 10):

```bash
cd 09-docker-compose
docker compose up

cd ../10-docker-compose-ghost
docker compose up -d
```

Docker Swarm (módulos 11–13 — cada um é autocontido):

```bash
cd 11-docker-swarm    # ou 12-docker-swarm-ha-proxy / 13-docker-swarm-dns
vagrant up
# ver README do módulo ou docs/guias/swarm-cluster-setup.md

export DOCKER_HOST=192.168.56.11:2375
docker node ls
```

Docker Swarm Stacks (módulos 14 e 15):

```bash
# Módulo 14 — Ghost + MySQL
cd 14-docker-swarm-stacks
export DOCKER_HOST=192.168.56.11:2375
docker stack deploy -c docker-compose.yaml ghost-stack

# Módulo 15 — WordPress em HA com NFS
cd 15-docker-swarm-nfs
cd nfs && vagrant up    # VM do servidor NFS
cd ../swarm && vagrant up
export DOCKER_HOST=192.168.56.11:2375
docker stack deploy -c wordpress/docker-compose.yaml wp-stack
```

Portainer (opcional, na máquina host):

```bash
./portainer.sh
# https://localhost:9443
```

## Licença

Material de estudo pessoal — use livremente para aprendizado.
