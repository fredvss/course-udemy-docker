# 08 — Restart Policies

Container de teste que falha após 5 segundos (`exit 1`), ideal para experimentar as políticas de reinício do Docker.

## Build

```bash
docker build -t restart-test .
```

---

# Docker Restart Policies - Guia Prático

## O que são Restart Policies?

Restart Policies definem o que o Docker deve fazer quando o processo principal do container termina.

## Projeto de teste

Dockerfile:

```dockerfile
FROM busybox:1.36.0-glibc

WORKDIR /app

COPY failure.sh .

RUN chmod +x failure.sh

CMD ["./failure.sh"]
```

Script de falha:

```sh
#!/bin/sh

echo "Iniciando..."
sleep 5

echo "Falhou!"
exit 1
```

Build:

```bash
docker build -t restart-test .
```

## Sem Restart Policy

```bash
docker run --name test restart-test
```

Resultado:

```text
Container inicia
↓
Falha
↓
Container para
```

## restart=no

Padrão do Docker.

```bash
docker run --restart=no restart-test
```

Não reinicia.

## restart=on-failure

```bash
docker run --restart=on-failure restart-test
```

Reinicia apenas quando o processo termina com erro.

```text
exit 1 -> reinicia
exit 0 -> não reinicia
```

## restart=on-failure:5

```bash
docker run --restart=on-failure:5 restart-test
```

Reinicia até 5 vezes e depois para.

## restart=always

```bash
docker run --restart=always restart-test
```

Reinicia independentemente do código de saída.

```text
exit 0 -> reinicia
exit 1 -> reinicia
```

## restart=unless-stopped

```bash
docker run --restart=unless-stopped restart-test
```

Reinicia automaticamente, inclusive após reboot do host.

Porém, se você executar:

```bash
docker stop restart-demo
```

o Docker lembra que a parada foi manual e não volta a subir após reboot.

## Diferença entre always e unless-stopped

always:

```text
docker stop
↓
reinicia daemon Docker
↓
container volta
```

unless-stopped:

```text
docker stop
↓
reinicia daemon Docker
↓
container continua parado
```

## Verificando a policy

```bash
docker inspect   --format='{{.HostConfig.RestartPolicy.Name}}'   restart-demo
```

## Docker Compose

```yaml
services:
  app:
    image: restart-test
    restart: unless-stopped
```

Valores possíveis:

```yaml
restart: "no"
restart: on-failure
restart: always
restart: unless-stopped
```

## Relação com HEALTHCHECK

Importante:

```text
HEALTHCHECK = monitora
Restart Policy = reinicia
```

Um container unhealthy NÃO é reiniciado automaticamente.

A Restart Policy só age quando o processo principal (PID 1) termina.

## Recomendações

Desenvolvimento:

```yaml
restart: "no"
```

ou

```yaml
restart: on-failure
```

Produção:

```yaml
restart: unless-stopped
```

## Resumo

| Policy | Reinicia em erro | Reinicia em sucesso | Reinicia após reboot |
|----------|----------|----------|----------|
| no | Não | Não | Não |
| on-failure | Sim | Não | Sim |
| on-failure:N | Sim (até N vezes) | Não | Sim |
| always | Sim | Sim | Sim |
| unless-stopped | Sim | Sim | Sim, exceto se parado manualmente |
