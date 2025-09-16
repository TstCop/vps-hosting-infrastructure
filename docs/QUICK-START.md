# Quick Start Guide

## Deploy VPS Infrastructure in 5 Minutes

### Prerequisites Check

```bash
# Check virtualization support
sudo virt-host-validate

# Verify available resources
free -h
df -h

# Ensure you have root access
sudo whoami
```

### One-Command Deployment

```bash
# Clone and deploy everything
git clone https://github.com/TstCop/vps-hosting-infrastructure.git
cd vps-hosting-infrastructure
sudo ./core/shared/scripts/infrastructure-mgmt.sh deploy
```

### Verify Deployment

```bash
# Check infrastructure status
sudo ./core/shared/scripts/infrastructure-mgmt.sh status

# Run health check
sudo /opt/health-check.sh

# Open monitoring dashboard
sudo /opt/monitoring-dashboard.sh
```

### Access Your Infrastructure

- **GitLab**: <https://136.243.208.130>
- **Application**: <https://136.243.208.131>
- **GitLab Monitoring**: <http://10.0.0.10:19999>
- **App Monitoring**: <http://10.0.0.20:19999>

### Default Credentials

- **GitLab admin**: `root` / (check `/etc/gitlab/initial_root_password` on GitLab VPS)

That's it! Your production VPS infrastructure is ready.

---

## Manual Deployment (Step by Step)

If you prefer manual control:

### 1. Install Dependencies

```bash
# Install Vagrant
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vagrant

# Install KVM/QEMU
sudo apt install qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils

# Install Vagrant Libvirt plugin
vagrant plugin install vagrant-libvirt

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh
```

### 2. Deploy GitLab VPS

```bash
cd core/gitlab-vps
vagrant up --provider=libvirt
# Wait 10-15 minutes for GitLab installation
```

### 3. Deploy Nginx App VPS

```bash
cd ../nginx-app-vps
vagrant up --provider=libvirt
# Wait 5-10 minutes for application setup
```

### 4. Configure Shared Infrastructure

```bash
cd ../shared
sudo ./scripts/security-hardening.sh
sudo ./scripts/monitoring-setup.sh
sudo ./scripts/backup-management.sh --verify
```

---

## Common Commands

```bash
# Infrastructure management
sudo ./core/shared/scripts/infrastructure-mgmt.sh status
sudo ./core/shared/scripts/infrastructure-mgmt.sh monitor
sudo ./core/shared/scripts/infrastructure-mgmt.sh health
sudo ./core/shared/scripts/infrastructure-mgmt.sh backup

# Individual VPS control
cd core/gitlab-vps && vagrant status
cd core/nginx-app-vps && vagrant status

# Monitoring
sudo /opt/monitoring-dashboard.sh
sudo tail -f /var/log/health-check.log

# Troubleshooting
sudo systemctl status nginx
sudo gitlab-ctl status
sudo docker ps
```

---

For detailed information, see the [complete documentation](README.md).
