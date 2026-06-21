# 01 — Chroot e isolamento Linux

Scripts para montar um ambiente chroot mínimo e entrar nele com namespaces (`pid` e `mount`), simulando o que o Docker faz antes de existir como produto.

Relacionado ao conceito de containers descrito em [Containers Linux](../docs/fundamentos/containers-linux.md).

## Arquivos

| Script | Função |
|--------|--------|
| `setup-chroot.sh` | Cria o rootfs em `../chroot` com binários e libs mínimas |
| `enter-isolated.sh` | Entra no chroot com `unshare --pid --mount` |
| `teardown-chroot.sh` | Remove o diretório chroot |

## Uso

```bash
./setup-chroot.sh
./enter-isolated.sh
# dentro do chroot:
ps aux    # vê apenas processos do namespace
exit
./teardown-chroot.sh
```

## O que observar

- **Chroot sozinho** isola só o filesystem — processos e rede do host ainda são visíveis.
- **Namespaces** (`unshare`) adicionam isolamento de PID e mounts, aproximando-se de um container real.
- Compare com o fluxo descrito em [containers-linux.md](../docs/fundamentos/containers-linux.md).

## Requisitos

- Linux com `sudo`
- Binários referenciados no script: `bash`, `ps`, `ls` (e dependências via `ldd`)
