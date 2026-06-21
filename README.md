# Curso Docker — Udemy

Material prático de um curso de Docker: scripts de isolamento Linux, builds progressivos com Node.js, Python e Go, e guias de referência sobre containers, rede, healthcheck e restart policies.

## Pré-requisitos

- Linux (ou WSL2)
- [Docker Engine](https://docs.docker.com/engine/install/) instalado
- Para o módulo 01: `sudo`, `debootstrap` ou acesso root

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

## Documentação

Índice completo em **[docs/README.md](docs/README.md)**.

### Fundamentos Linux e Docker

Conceitos teóricos que sustentam o restante do curso:

- [Containers Linux — o que são e como funcionam](docs/fundamentos/containers-linux.md)
- [Redes Linux, Docker e containers](docs/fundamentos/redes-linux-docker.md)

### Guias práticos

- [Docker HEALTHCHECK — guia prático](docs/guias/healthcheck.md) — usado nos módulos 05 e 06

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
```

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

## Licença

Material de estudo pessoal — use livremente para aprendizado.
