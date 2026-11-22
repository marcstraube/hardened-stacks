# Forgejo Runner

Executes [Forgejo Actions](https://forgejo.org/docs/latest/user/actions/overview/) jobs for the
[forgejo](../forgejo/) stack.

## Security Model

A workflow is arbitrary code. Anyone who can push a workflow file can run it on the runner, so the runner is
designed to be compromised without consequences for the rest of the homelab:

| Layer                     | Purpose                                                             |
| ------------------------- | ------------------------------------------------------------------- |
| Dedicated VM              | Security boundary — a container escape ends in the VM, not the NAS  |
| Docker-in-Docker (`dind`) | Jobs run in their own Docker daemon, separate from the VM's daemon  |
| Runner container          | Unprivileged, `cap_drop: ALL`, read-only root, no job Docker access |
| Firewall (optional)       | Jobs cannot reach the LAN, only Forgejo and the internet            |

The `docker` container must run with `privileged: true`. This is the only exception to the hardening rules in
this repository and the reason the stack belongs in a VM.

## How Deployment Works

The stack is managed from the NAS like every other stack, but its containers run in the VM:
`./stacks deploy forgejo-runner` connects to the VM's Docker daemon over SSH (`REMOTE_DOCKER_HOST`). The VM
needs no repository, no `.env` and no setup — only Docker and an SSH key.

- The NAS can control the VM, the VM has no access to the NAS.
- The stack uses no bind mounts, only named volumes that live in the VM.
- Without `REMOTE_DOCKER_HOST` the stack is never deployed, so it cannot accidentally start on the NAS.
- The VM holds no state worth keeping. If it breaks, recreate it and deploy again — the registration lives in
  `.env` on the NAS.

## Setup

### 1. Create the VM

Example for a Synology DS720+ (Virtual Machine Manager):

- OS: Debian 13 (netinst ISO), only with the SSH server
- 2 vCPUs, 4 GB RAM, 50 GB disk
- Install [Docker Engine](https://docs.docker.com/engine/install/debian/)
- Create a deploy user that may use Docker:

```bash
sudo adduser --disabled-password deploy
sudo usermod -aG docker deploy
```

### 2. Allow SSH access from the NAS

On the NAS, as the user that runs `./stacks deploy`:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/runner-vm -N ""
cat ~/.ssh/runner-vm.pub
```

In the VM, add the key to `/home/deploy/.ssh/authorized_keys`. The `command=` restriction limits the key to
the Docker API — it cannot open a shell:

```text
restrict,command="docker system dial-stdio" ssh-ed25519 AAAA... runner-vm
```

On the NAS, add a host entry to `~/.ssh/config` and accept the host key once:

```text
Host runner-vm
  HostName 192.168.1.20
  User deploy
  IdentityFile ~/.ssh/runner-vm
```

Then trust the VM's host key (compare the fingerprint with `ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub`
in the VM) and test the connection:

```bash
ssh-keyscan -t ed25519 192.168.1.20 >> ~/.ssh/known_hosts
docker -H ssh://runner-vm info
```

### 3. Register the runner in Forgejo

Site Administration → Actions → Runners → **Create new runner**. Copy the displayed UUID and token.

Runners can also be registered for a single user, organization or repository
(see [registration](https://forgejo.org/docs/latest/admin/actions/registration/)).

### 4. Configure and deploy

On the NAS:

```bash
sudo ./stacks setup forgejo-runner
vim forgejo-runner/.env   # REMOTE_DOCKER_HOST=ssh://runner-vm, FORGEJO_URL, RUNNER_UUID, RUNNER_TOKEN
./stacks deploy forgejo-runner
```

`FORGEJO_URL` must be reachable from the VM — usually the reverse proxy URL, which should match Forgejo's
`FORGEJO_URL` so that checkout URLs work. The runner shows up as *Idle* in Forgejo once connected.

To check on the runner from the NAS:

```bash
docker -H ssh://runner-vm logs forgejo-runner
```

### 5. Use it in a workflow

```yaml
# .forgejo/workflows/test.yml
on: [push]
jobs:
  test:
    runs-on: docker
    steps:
      - uses: actions/checkout@v4
      - run: echo "Hello from Forgejo Actions"
```

Available labels (`docker`, `ubuntu-latest`) and their images are defined in the runner configuration inside
[docker-compose.yml](docker-compose.yml).

## Network Isolation (recommended)

Jobs should not be able to reach other devices in the LAN. Docker evaluates the `DOCKER-USER` chain for all
container traffic, so the following rules in the VM block the LAN except for Forgejo and DNS. Adjust the
interface (`ens3`), the NAS / reverse proxy IP and the DNS server:

```bash
sudo iptables -I DOCKER-USER -o ens3 -d 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 -j REJECT
sudo iptables -I DOCKER-USER -o ens3 -d 192.168.1.1 -p udp --dport 53 -j ACCEPT
sudo iptables -I DOCKER-USER -o ens3 -d 192.168.1.10 -p tcp --dport 443 -j ACCEPT
sudo iptables -I DOCKER-USER -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```

Persist them with `iptables-persistent`. These rules only affect container traffic, so SSH from the NAS to
the VM keeps working. A separate VLAN for the VM achieves the same without host rules.

## Docker Inside Jobs

Jobs have no access to the Docker daemon by default. To allow `docker build` in workflows, change the
`container:` section of the runner configuration in [docker-compose.yml](docker-compose.yml):

```yaml
container:
  options: -v /certs/client:/certs/client:ro -e DOCKER_HOST=tcp://docker:2376 -e DOCKER_TLS_VERIFY=1 -e DOCKER_CERT_PATH=/certs/client
  valid_volumes:
    - /certs/client
```

Jobs can then control all job containers of this runner — acceptable inside the VM, but only enable it if
needed.
