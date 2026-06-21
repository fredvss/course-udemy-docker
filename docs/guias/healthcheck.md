# Docker HEALTHCHECK - Guia Prático

## O que é o HEALTHCHECK?

O `HEALTHCHECK` é uma instrução do Dockerfile que permite ao Docker verificar periodicamente se a aplicação dentro do container está saudável.

Exemplo:

```dockerfile
HEALTHCHECK CMD wget --spider http://localhost:3000/ || exit 1
```

Se o comando retornar:

- `0` → container saudável (`healthy`)
- diferente de `0` → container com problema (`unhealthy`)

## HEALTHCHECK é executado no build?

Não.

Durante:

```bash
docker build -t minha-app .
```

o HEALTHCHECK é apenas registrado na imagem.

Ele NÃO é executado durante o build.

## Quando o HEALTHCHECK roda?

Ele começa a rodar quando um container é iniciado:

```bash
docker run minha-app
```

ou

```bash
docker compose up
```

Nesse momento o Docker Engine inicia um processo interno que executa o healthcheck periodicamente.

## Fluxo de execução

Dockerfile:

```dockerfile
HEALTHCHECK --interval=30s CMD wget --spider http://localhost:3000/ || exit 1
```

Container iniciado:

```bash
docker run minha-app
```

Fluxo:

```text
Container inicia
↓
Docker espera o primeiro intervalo
↓
Executa o comando HEALTHCHECK
↓
Resultado OK?
├─ Sim → healthy
└─ Não → unhealthy
↓
Repete a cada 30 segundos
```

## Como ver o status?

### docker ps

```bash
docker ps
```

Exemplo:

```text
CONTAINER ID   IMAGE      STATUS
abc123         app        Up 2m (healthy)
```

### docker inspect

```bash
docker inspect --format='{{json .State.Health}}' container_id
```

## O Docker reinicia automaticamente um container unhealthy?

Não.

O Docker apenas marca o container como:

- healthy
- unhealthy

O processo principal continua rodando.

## Quem usa o HEALTHCHECK?

### Docker Compose

```yaml
depends_on:
  api:
    condition: service_healthy
```

Exemplo:

```yaml
services:
  api:
    build: .
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:3000"]
      interval: 30s

  nginx:
    depends_on:
      api:
        condition: service_healthy
```

O nginx só inicia quando a API estiver saudável.

## Parâmetros importantes

### interval

```dockerfile
--interval=30s
```

Tempo entre execuções.

### timeout

```dockerfile
--timeout=3s
```

Tempo máximo permitido.

### retries

```dockerfile
--retries=3
```

Quantidade de falhas antes de marcar como unhealthy.

### start-period

```dockerfile
--start-period=10s
```

Período de tolerância após a inicialização.

## Exemplo recomendado para Node.js

```dockerfile
HEALTHCHECK   --interval=30s   --timeout=3s   --start-period=10s   --retries=3   CMD wget -q --spider http://localhost:${PORT}/ || exit 1
```

## O HEALTHCHECK roda dentro do container?

Sim.

O comando é executado dentro do próprio container.

Por isso:

```dockerfile
http://localhost:3000
```

significa o próprio container e não a máquina host.

## Resumo

- HEALTHCHECK é definido no Dockerfile.
- Não roda durante o build.
- Começa a rodar quando o container inicia.
- É executado periodicamente pelo Docker Engine.
- O resultado gera os estados `healthy` ou `unhealthy`.
- O Docker não reinicia automaticamente um container unhealthy.
- Docker Compose pode usar esse status para controlar dependências.
- O comando do healthcheck roda dentro do próprio container.
