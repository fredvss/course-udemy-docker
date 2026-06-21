# 03 — Node.js com VOLUME e ENTRYPOINT

Evolução do Dockerfile anterior: declara um volume de dados, separa executável (`ENTRYPOINT`) de argumentos (`CMD`) e inclui um healthcheck básico.

## O que este módulo demonstra

- `VOLUME ["/var/nodeapp"]` — ponto de montagem para dados persistentes
- `ENTRYPOINT ["node"]` + `CMD ["app.js"]` — padrão executável + argumentos
- `HEALTHCHECK` com `wget --spider`
- Mesma base de usuário não-root e variáveis `PORT` / `VERSION`

## Build e execução

```bash
docker build -t node-volume .
docker run --rm -p 3000:3000 node-volume
```

Sobrescrever o script executado (substitui o `CMD`):

```bash
docker run --rm -p 3000:3000 node-volume app.js
```

Volume nomeado:

```bash
docker volume create nodeapp-data
docker run --rm -p 3000:3000 -v nodeapp-data:/var/nodeapp node-volume
```

## Documentação relacionada

- [CMD vs ENTRYPOINT](../04-build-node-entrypoint/README.md) — guia detalhado no módulo 04
- [HEALTHCHECK](../docs/guias/healthcheck.md) — guia completo

## Próximo passo

[04-build-node-entrypoint](../04-build-node-entrypoint/) — foco em `CMD`/`ENTRYPOINT` e histórico de comandos Docker.
