# Homelab Grafana

Ansible project for deploying [Grafana](https://github.com/grafana/grafana) via Docker Compose on a single host.

**Target host:** `grafana.local.iamrobertyoung.co.uk`

## Project Structure

```
.
├── ansible.cfg                 # Ansible configuration
├── inventories/
│   ├── hosts.yml               # Inventory with grafana group
│   └── group_vars/             # Group variables
├── host_vars/                  # Host-specific variables
├── roles/
│   └── grafana/                # Custom Grafana role
├── .roles/                     # External roles (gitignored)
├── playbooks/
│   └── site.yml                # Main playbook
├── files/                      # Static files
├── templates/                  # Jinja2 templates
├── scripts/                    # Utility scripts
└── requirements.yml            # External role dependencies
```

## Prerequisites

- Ansible installed (see `mise.toml` for version)
- SSH access to the target host
- AWS credentials via aws-vault for SSM parameter access (region: eu-west-2)

## Setup

Install external role dependencies:

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-galaxy install -r requirements.yml -p .roles
```

## Usage

All commands require AWS credentials via aws-vault for SSM parameter lookups.

### Test connectivity

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible grafana -m ping
```

### Run full playbook

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-playbook playbooks/site.yml
```

### Run specific role

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-playbook playbooks/site.yml --tags grafana
```

## Roles

The playbook applies these roles in order:

| Role | Source | Description |
|------|--------|-------------|
| `configure-system` | External | Base system configuration |
| `shell` | External | Shell setup (noxious, root users) |
| `docker` | External | Docker installation |
| `telegraf` | External | Metrics collection to InfluxDB |
| `step-ca-client` | External | TLS certificates from Step CA |
| `syslog` | External | Syslog configuration |
| `wazuh-agent` | External | Wazuh security agent |
| `grafana` | Custom | Grafana deployment |

## Available Tags

Run specific parts of the playbook:

- `configure-system`
- `shell`
- `docker`
- `telegraf`
- `step-ca-client`
- `syslog`
- `wazuh-agent`
- `grafana`

## Secrets

Secrets are stored in AWS SSM Parameter Store (eu-west-2) and retrieved via `lookup('aws_ssm', ...)`.

## Adding Roles

Create a new custom role:

```bash
ansible-galaxy init roles/role_name
```

Add external roles to `requirements.yml` and install:

```bash
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-galaxy install -r requirements.yml -p .roles
```
