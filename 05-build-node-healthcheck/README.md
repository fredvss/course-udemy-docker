# 05 — Node.js com HEALTHCHECK completo

Dockerfile Node.js com healthcheck configurado com todos os parâmetros recomendados: `interval`, `timeout`, `start-period` e `retries`.

## O que este módulo demonstra

- Instalação de `wget` para o probe HTTP
- `HEALTHCHECK` com parâmetros de produção
- `ENTRYPOINT` + `CMD` (padrão `node` + `app.js`)
- Endpoint `/` como alvo do healthcheck

## Build e execução

```bash
docker build -t node-health .
docker run --rm -p 3000:3000 --name node-hc node-health
```

Verificar status de saúde:

```bash
docker ps
# STATUS: Up X seconds (healthy)

docker inspect --format='{{json .State.Health}}' node-hc | jq
```

## Documentação

Guia completo: [docs/guias/healthcheck.md](../docs/guias/healthcheck.md)

## Próximo passo

[06-build-python-healthcheck](../06-build-python-healthcheck/) — mesmo conceito com Flask e endpoint `/health`.
