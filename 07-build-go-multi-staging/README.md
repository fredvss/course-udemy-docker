# 07 — Go multi-stage build (scratch)

Build em duas etapas: compila o binário Go com a imagem completa do toolchain e copia apenas o executável estático para uma imagem `scratch` — sem SO, sem shell.

## O que este módulo demonstra

- Multi-stage build com `AS builder`
- `CGO_ENABLED=0` para binário estático
- Imagem final `FROM scratch` — tamanho mínimo
- `COPY --from=builder` — apenas o artefato necessário

## Build e execução

```bash
docker build -t go-scratch .
docker run --rm -p 3000:3000 go-scratch
```

Teste:

```bash
curl http://localhost:3000/
```

Inspecionar tamanho da imagem:

```bash
docker images go-scratch
```

## Observações

- Imagem `scratch` não tem shell — depuração exige `docker run` com outra imagem ou inspeção externa.
- Binário escuta na porta 3000 (definida em `app.go`).
- Contraste com as imagens Node/Python anteriores: aqui o objetivo é **tamanho e superfície de ataque mínimos**.

## Próximo passo

[08-restart-policies](../08-restart-policies/) — comportamento do Docker quando o processo principal termina.
