# 06 — Python Flask com HEALTHCHECK

Aplicação Flask em Alpine com usuário não-root, dependências via `requirements.txt` e healthcheck apontando para `/health`.

## O que este módulo demonstra

- Imagem `python:3.12-alpine`
- `pip install` em camada separada (cache de build)
- Usuário `pythonapp` sem privilégios
- `HEALTHCHECK` em endpoint dedicado (`/health`)
- `ENTRYPOINT ["python3"]` + `CMD ["app.py"]`

## Build e execução

```bash
docker build -t flask-health .
docker run --rm -p 5000:5000 --name flask-hc flask-health
```

Teste:

```bash
curl http://localhost:5000/
curl http://localhost:5000/health
docker ps   # verificar (healthy)
```

Com porta customizada:

```bash
docker build --build-arg PORT=8080 -t flask-health .
docker run --rm -p 8080:8080 -e PORT=8080 flask-health
```

## Documentação

Guia completo: [docs/guias/healthcheck.md](../docs/guias/healthcheck.md)

## Próximo passo

[07-build-go-multi-staging](../07-build-go-multi-staging/) — multi-stage build e imagem mínima `scratch`.
