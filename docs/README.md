# Documentação

Material de apoio ao [curso Docker](../README.md). Os exercícios práticos ficam nas pastas numeradas na raiz do repositório; aqui ficam os conceitos transversais e recursos de referência.

## Fundamentos

Base teórica sobre como containers funcionam no Linux:

| Documento | Conteúdo |
|-----------|----------|
| [containers-linux.md](fundamentos/containers-linux.md) | Namespaces, cgroups, chroot vs container, relação com Kubernetes |
| [redes-linux-docker.md](fundamentos/redes-linux-docker.md) | veth, docker0, NAT, inspeção de rede, comunicação entre containers |

## Guias práticos

| Documento | Relacionado a |
|-----------|---------------|
| [healthcheck.md](guias/healthcheck.md) | [05-build-node-healthcheck](../05-build-node-healthcheck/), [06-build-python-healthcheck](../06-build-python-healthcheck/), [10-docker-compose-ghost](../10-docker-compose-ghost/) |

## Documentação nos módulos

Alguns tópicos ficam junto do código que os demonstra:

| Módulo | Documento |
|--------|-----------|
| [04-build-node-entrypoint](../04-build-node-entrypoint/) | CMD, ENTRYPOINT e histórico de comandos Docker |
| [08-restart-policies](../08-restart-policies/) | Restart policies — guia completo com exemplos |
| [09-docker-compose](../09-docker-compose/) | Compose básico — múltiplos serviços |
| [10-docker-compose-ghost](../10-docker-compose-ghost/) | Ghost + MySQL — healthcheck e `service_healthy` |

## Recursos

| Arquivo | Descrição |
|---------|-----------|
| [docker_annotations.pdf](recursos/docker_annotations.pdf) | Anotações do curso em PDF |
| [Docker.xopp](recursos/Docker.xopp) | Mapa mental / anotações no Xournal++ |

## Mapa do repositório

```text
course-udemy-docker/
├── README.md                 ← visão geral e índice
├── 01-chroot_scripts/        ← isolamento Linux manual
├── 02-build-node/            ← primeiro Dockerfile
├── …
├── 08-restart-policies/      ← restart policies (+ README)
├── 09-docker-compose/        ← compose básico (+ README)
├── 10-docker-compose-ghost/  ← Ghost + MySQL (+ README)
└── docs/
    ├── README.md             ← este arquivo
    ├── fundamentos/          ← teoria Linux/containers
    ├── guias/                ← guias transversais
    └── recursos/             ← PDF, Xournal++
```
