# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Single-host Ansible project deploying Grafana via Docker Compose on `grafana.local.iamrobertyoung.co.uk`. Secrets are stored in AWS SSM Parameter Store.

## Key Commands

All commands require AWS credentials via aws-vault for SSM parameter lookups.

```bash
# Test connectivity
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible grafana -m ping

# Run full playbook
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-playbook playbooks/site.yml

# Run specific role only
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-playbook playbooks/site.yml --tags grafana

# Install external dependencies (roles)
aws-vault exec iamrobertyoung:home-assistant-production:p -- ansible-galaxy install -r requirements.yml -p .roles

# Lint
yamllint .
ansible-lint
```

## Architecture

### Deployment Stack
The main playbook (`playbooks/site.yml`) applies these roles in order:
1. `configure-system` - Base system configuration
2. `shell` - Shell setup for users (noxious, root)
3. `docker` - Docker installation
4. `telegraf` - Metrics collection to InfluxDB
5. `step-ca-client` - TLS certificates from Step CA
6. `syslog` - Syslog configuration
7. `wazuh-agent` - Security monitoring agent
8. `grafana` - Grafana deployment (Docker Compose with systemd service)

### Grafana Role Structure
The `roles/grafana` role deploys Grafana via Docker Compose:
- `tasks/main.yml` - Main task orchestration
- `defaults/main.yml` - Default variables
- `templates/docker-compose/` - Docker Compose configuration
- `templates/nginx/` - Nginx reverse proxy config
- `handlers/main.yml` - Service restart handlers

Key directories on target host:
- `/etc/grafana` - Configuration files and docker-compose.yml
- `/var/lib/grafana` - Application data
- `/etc/grafana/certs` - TLS certificates

### Secrets Management
Secrets are stored in AWS SSM Parameter Store (region: eu-west-2).
Ansible retrieves them via `lookup('aws_ssm', '/path/to/secret', region='eu-west-2')`.

### External Dependencies
Dependencies in `requirements.yml` are installed to `.roles/` (gitignored). External roles use SSH git URLs requiring SSH keys.

### Available Tags
Run specific parts with `--tags`: `configure-system`, `shell`, `docker`, `telegraf`, `step-ca-client`, `syslog`, `wazuh-agent`, `grafana`

### Tool Versions (mise.toml)
- ansible 13.1.0
- pipx 1.8.0
- uv 0.9.18
