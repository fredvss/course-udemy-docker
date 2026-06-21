# 04 — Node.js com VOLUME (CMD padrão)

Dockerfile Node.js com `VOLUME` e `CMD` simples — base para entender a diferença entre `CMD` e `ENTRYPOINT` (demonstrado no módulo [03-build-node-volume](../03-build-node-volume/)).

## Build e execução

```bash
docker build -t node-entrypoint .
docker run --rm -p 3000:3000 node-entrypoint
```

Sobrescrever o comando padrão:

```bash
docker run --rm node-entrypoint node -e "console.log('override')"
```

---

# CMD, ENTRYPOINT e histórico de comandos Docker

## 1. Buscar comandos já executados

### Método mais simples

```bash
history | grep docker
```

Exemplo:

```bash
history | grep compose
```

Saída:

```text
1023 docker compose up -d
1024 docker compose logs -f
1025 docker compose down
```

---

### Melhor método: busca reversa interativa

Pressione:

```text
Ctrl + R
```

e comece a digitar:

```text
docker
```

Vai aparecendo o último comando que contém essa palavra.

Exemplo:

```text
(reverse-i-search)`docker': docker compose up -d
```

Pressione:

- `Ctrl + R` novamente → próximo resultado
- `Enter` → executa
- seta direita → edita antes de executar

Depois que você acostuma, praticamente abandona o `history | grep`.

---

### Procurar sem mostrar números

```bash
history | grep docker | cut -c 8-
```

ou

```bash
history | grep docker | awk '{$1=""; print substr($0,2)}'
```

---

### Buscar no arquivo de histórico

Bash:

```bash
grep docker ~/.bash_history
```

Zsh:

```bash
grep docker ~/.zsh_history
```

---

# 2. Diferença entre ENTRYPOINT e CMD

A melhor forma de entender:

- **ENTRYPOINT = qual programa será executado**
- **CMD = argumentos padrão desse programa**

---

### Exemplo

Dockerfile:

```dockerfile
ENTRYPOINT ["echo"]
CMD ["Olá mundo"]
```

Ao executar:

```bash
docker run minha-imagem
```

Resultado:

```text
Olá mundo
```

O Docker faz internamente:

```bash
echo "Olá mundo"
```

---

### Sobrescrevendo CMD

```bash
docker run minha-imagem "Docker"
```

Resultado:

```text
Docker
```

Porque o CMD foi substituído.

Internamente:

```bash
echo Docker
```

---

## Exemplo real: Python

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

Sem argumentos:

```bash
docker run minha-imagem
```

Executa:

```bash
python app.py
```

Mas você pode trocar o CMD:

```bash
docker run minha-imagem outro.py
```

Executa:

```bash
python outro.py
```

---

## Sobrescrevendo o ENTRYPOINT

```bash
docker run --entrypoint bash minha-imagem
```

Agora o Docker não executa mais o comando original.

---

## Quando usar cada um?

### CMD

Quando quer um comando padrão facilmente substituível.

Exemplo:

```dockerfile
CMD ["npm", "start"]
```

ou

```dockerfile
CMD ["python", "app.py"]
```

### ENTRYPOINT

Quando o container **sempre deve executar um programa específico**.

Exemplo:

```dockerfile
ENTRYPOINT ["nginx", "-g", "daemon off;"]
```

ou

```dockerfile
ENTRYPOINT ["postgres"]
```

---

## Exemplo muito usado

```dockerfile
ENTRYPOINT ["python"]
CMD ["app.py"]
```

Permite:

```bash
docker run imagem
# python app.py

docker run imagem teste.py
# python teste.py
```

Esse padrão (`ENTRYPOINT` fixo + `CMD` como argumentos padrão) é provavelmente o uso mais elegante dos dois juntos.

---

## Regra prática

- **CMD** → "o que executar por padrão"
- **ENTRYPOINT** → "qual executável principal do container"
- **ENTRYPOINT + CMD** → "executável fixo + argumentos padrão"

É por isso que em imagens como PostgreSQL, Redis e Nginx você costuma ver muito `ENTRYPOINT`, enquanto em aplicações simples frequentemente só aparece `CMD`.
