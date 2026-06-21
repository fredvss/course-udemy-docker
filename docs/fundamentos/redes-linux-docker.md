
# Redes Linux, Docker e Containers

## Visão geral

Fluxo completo:

```text
Container
   |
 eth0
   |
 veth
   |
docker0
   |
Host eth0
   |
Gateway
   |
Internet
```

---

# Componentes

## eth0 (container)

É a interface de rede visível dentro do container.

Exemplo:

```bash
docker exec -it app bash
ip a
```

Saída:

```text
eth0@if123
172.17.0.2/16
```

Ela é uma ponta de um par veth.

---

## veth

Virtual Ethernet Pair.

Funciona como um cabo virtual.

```text
vethA <-------> vethB
```

Tudo que entra de um lado sai do outro.

---

Exemplo:

```text
Container Namespace
      |
    eth0
      |
   vethA

Host Namespace
      |
   vethB
```

---

## docker0

Bridge Linux criada pelo Docker.

Funciona como um switch virtual.

```text
Container A
     |
    veth
     |
  docker0
     |
    veth
     |
Container B
```

---

## Host eth0

Interface física da máquina.

Exemplo:

```bash
ip a
```

```text
eth0
192.168.1.10
```

É ela que conversa com o gateway da rede.

---

## Gateway

Exemplo:

```text
192.168.1.1
```

Responsável por encaminhar tráfego para outras redes.

Ver rota:

```bash
ip route
```

Exemplo:

```text
default via 192.168.1.1
```

---

# NAT

Importante:

docker0 NÃO faz NAT.

docker0 apenas comuta tráfego.

O NAT normalmente é feito pelo host via:

- iptables
- nftables

Fluxo:

```text
Container
172.17.0.2

      |

Host
192.168.1.10

      |

Internet
```

---

# Inspecionando a rede

## Ver interfaces do host

```bash
ip a
```

---

## Ver rotas

```bash
ip route
```

---

## Ver interfaces do container

```bash
docker exec -it meu_container ip a
```

---

## Ver rotas do container

```bash
docker exec -it meu_container ip route
```

---

## Ver redes Docker

```bash
docker network ls
```

---

## Inspecionar uma rede

```bash
docker network inspect bridge
```

Exemplo de saída relevante:

```json
{
  "Subnet": "172.17.0.0/16",
  "Gateway": "172.17.0.1"
}
```

---

## Descobrir IP do container

```bash
docker inspect meu_container
```

ou

```bash
docker inspect meu_container \
| grep IPAddress
```

---

## Conectar container em uma rede

```bash
docker network connect minha_rede meu_container
```

---

## Criar rede bridge

```bash
docker network create minha_rede
```

---

# Comunicação entre containers

```text
Container A
172.17.0.2

Container B
172.17.0.3
```

Fluxo:

```text
A
 |
veth
 |
docker0
 |
veth
 |
B
```

Não passa pela internet.

Não passa pelo gateway.

Não usa NAT.

---

# Comunicação com a internet

```text
Container
    |
docker0
    |
Host
    |
NAT
    |
eth0
    |
Gateway
    |
Internet
```

---

# Relação com Kubernetes

Kubernetes usa exatamente os mesmos conceitos:

- namespaces
- veth
- bridge
- rotas
- NAT
- iptables
- nftables

Além disso pode adicionar:

- VXLAN
- Overlay Networks
- Cilium
- Calico
- Flannel

---

# Modelo mental final

```text
Aplicação
    |
TCP/UDP
    |
IP
    |
eth0
    |
veth
    |
docker0
    |
Host eth0
    |
Gateway
    |
Roteador
    |
Internet
```
