
# Containers Linux — O que são e como funcionam

## Resumo

Um container não é uma máquina virtual.

Um container é:

- Processo Linux
- Namespaces
- Cgroups
- Filesystem isolado
- Rede isolada

Todos compartilham o mesmo kernel do host.

---

## O que acontece ao executar um container

```bash
docker run nginx
```

De forma simplificada:

1. Docker cria namespaces
2. Docker cria cgroups
3. Docker monta o filesystem
4. Docker cria interfaces de rede
5. Docker inicia o processo principal

---

## Namespaces

Namespaces isolam a visão do processo.

### PID Namespace

```bash
unshare --pid --fork bash
```

Permite que o processo enxergue apenas seus próprios PIDs.

---

### Network Namespace

```bash
unshare --net bash
```

Permite que o processo tenha sua própria pilha de rede.

---

### Mount Namespace

```bash
unshare --mount bash
```

Permite que o processo tenha seus próprios mounts.

---

### UTS Namespace

Controla:

- hostname
- domainname

---

### IPC Namespace

Isola:

- shared memory
- message queues
- semaphores

---

### User Namespace

Permite mapear usuários diferentes dentro do container.

---

## Cgroups

Namespaces isolam.

Cgroups limitam.

Exemplos:

- CPU
- Memória
- I/O
- Número de processos

---

## Chroot x Container

Chroot altera apenas o filesystem.

```bash
chroot rootfs /bin/bash
```

Ainda é possível ver:

- processos do host
- rede do host

Containers adicionam namespaces e cgroups.

---

## Fluxo simplificado de criação

```text
docker run nginx

    |
    v

Namespaces
    |
    v

Cgroups
    |
    v

Filesystem
    |
    v

Rede
    |
    v

Processo nginx
```

---

## Modelo mental

```text
Container
=
Processo Linux
+
Namespaces
+
Cgroups
+
Filesystem
+
Rede
```

---

## Relação com Kubernetes

Quando um Pod é criado:

- kubelet solicita criação
- container runtime cria namespaces
- container runtime cria cgroups
- CNI configura rede

Kubernetes é uma automação massiva desses conceitos.
