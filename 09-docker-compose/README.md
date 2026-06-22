# 09 — Docker Compose básico

Primeiro contato com **Docker Compose**: orquestrar múltiplos serviços em um único arquivo YAML — imagem pronta, builds locais e dependência entre serviços.

## O que este módulo demonstra

| Serviço | Origem | Porta host | Descrição |
|---------|--------|------------|-----------|
| `frontend` | `nginx:1.27-alpine` | 8084 | Servidor web estático (imagem oficial, leve) |
| `nodeapp` | build de [02-build-node](../02-build-node/) | 4000 | API Node.js com `VERSION=1.0.2` |
| `pythonapp` | build de [06-build-python-healthcheck](../06-build-python-healthcheck/) | 4001 | API Flask com `VERSION=1.0.5` |

Conceitos praticados:

- `services`, `ports`, `environment`, `build` com `context` e `args`
- Reutilizar Dockerfiles de módulos anteriores sem duplicar código
- `depends_on` — ordem de inicialização entre serviços
- Diferença entre imagem pronta (`image`) e build local (`build`)

## Pré-requisitos

- Docker Compose v2 (`docker compose`)
- Módulos 02 e 06 (usados como contexto de build)

## Uso

```bash
docker compose up
```

Em background:

```bash
docker compose up -d
docker compose ps
docker compose logs -f
```

Parar e remover containers:

```bash
docker compose down
```

## Testes

```bash
curl http://localhost:8084/          # nginx — página padrão
curl http://localhost:4000/          # nodeapp
curl http://localhost:4001/          # pythonapp
curl http://localhost:4001/health    # healthcheck Flask
```

## Observações

### Por que nginx funciona e node sozinho não?

Imagens como `nginx` já vêm com um processo de longa duração (`nginx -g 'daemon off;'`). A imagem `node` sozinha executa `node` sem script e **encerra imediatamente** — por isso usamos `build` apontando para um Dockerfile com app.

### `depends_on` vs serviço pronto

Aqui `pythonapp` depende de `nodeapp` apenas na **ordem de start** do container. Não garante que a API Node já esteja respondendo. Para isso, use `healthcheck` + `condition: service_healthy` — demonstrado no [módulo 10](../10-docker-compose-ghost/).

## Próximo passo

[10-docker-compose-ghost](../10-docker-compose-ghost/) — stack multi-serviço com MySQL, volumes nomeados, redes e healthcheck.
