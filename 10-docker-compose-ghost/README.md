# 10 — Docker Compose: Ghost + MySQL

Stack completa com **Ghost** (CMS) e **MySQL 8**, usando volumes nomeados, redes isoladas e **healthcheck** para evitar race condition na subida.

## O que este módulo demonstra

- Dois serviços com dependência real (`ghost` → `db`)
- Variáveis de ambiente do Ghost para conexão MySQL
- Volumes nomeados para persistência (`ghost-data`, `ghost-mysql-data`)
- Redes bridge separadas (`ghost-network`, `ghost-mysql-network`)
- `restart: on-failure:5` em ambos os serviços
- **`healthcheck` no MySQL** + `depends_on: condition: service_healthy`

## Arquitetura

```text
┌─────────────┐     ghost-mysql-network     ┌─────────────┐
│    ghost    │ ──────────────────────────► │     db      │
│  :2368      │                             │  MySQL 8.0  │
└─────────────┘                             └─────────────┘
      │
      │ ghost-network (reservada para extensões futuras)
      ▼
   host :8080
```

## Pré-requisitos

- Docker Compose v2
- ~1 GB de espaço para imagens Ghost e MySQL

## Uso

```bash
docker compose up
```

Primeira subida pode levar alguns segundos enquanto o MySQL inicializa. O Ghost **só sobe depois** que o healthcheck do banco passar:

```text
db Waiting → db Healthy → ghost Starting
```

Em background:

```bash
docker compose up -d
docker compose ps        # db deve estar (healthy)
docker compose logs -f ghost
```

Acesse: [http://localhost:8080](http://localhost:8080)

Parar (mantém volumes):

```bash
docker compose down
```

Remover volumes também:

```bash
docker compose down -v
```

## Problema comum: `ECONNREFUSED` na porta 3306

Sem healthcheck, o Ghost tenta conectar enquanto o MySQL ainda está bootando:

```text
db container started  →  ghost sobe  →  ECONNREFUSED  →  ghost encerra
```

`depends_on: - db` **não espera** o MySQL aceitar conexões — só garante que o container foi criado.

### Solução aplicada neste compose

```yaml
ghost:
  depends_on:
    db:
      condition: service_healthy

db:
  environment:
    MYSQL_DATABASE: ghost
  healthcheck:
    test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-uroot", "-pF6keyX3Ok5mN"]
    interval: 5s
    timeout: 5s
    retries: 10
    start_period: 30s
```

Relacionado ao guia [HEALTHCHECK](../docs/guias/healthcheck.md) e ao uso de `depends_on` com `service_healthy` no Docker Compose.

## Volumes e redes

| Recurso | Nome | Uso |
|---------|------|-----|
| Volume `ghost` | `ghost-data` | Conteúdo, temas e uploads do Ghost |
| Volume `db` | `ghost-mysql-data` | Dados do MySQL |
| Rede | `ghost-mysql-network` | Comunicação ghost ↔ db |
| Rede | `ghost-network` | Rede adicional do Ghost (extensível) |

## Documentação relacionada

- [Redes Linux, Docker e containers](../docs/fundamentos/redes-linux-docker.md)
- [Docker HEALTHCHECK — guia prático](../docs/guias/healthcheck.md)
- [Restart policies](../08-restart-policies/README.md)
