# 02 — Build Node.js básico

Primeiro Dockerfile do curso: imagem Node.js Alpine com usuário não-root, variáveis de ambiente e servidor HTTP simples.

## O que este módulo demonstra

- `FROM`, `WORKDIR`, `COPY`, `RUN`, `EXPOSE`
- `ARG` / `ENV` para `PORT` e `VERSION`
- Usuário dedicado (`nodeapp`) em vez de root
- `CMD` como comando padrão do container

## Build e execução

```bash
docker build -t node-basic .
docker run --rm -p 3000:3000 node-basic
```

Com argumentos de build:

```bash
docker build \
  --build-arg PORT=8080 \
  --build-arg VERSION=2.0.0 \
  -t node-basic .

docker run --rm -p 8080:8080 -e PORT=8080 node-basic
```

Teste:

```bash
curl http://localhost:3000/
```

## Próximo passo

[03-build-node-volume](../03-build-node-volume/) — adiciona `VOLUME`, `ENTRYPOINT` e um healthcheck inicial.
