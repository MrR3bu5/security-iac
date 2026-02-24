# IaC Examples

Practical, copy-paste-ready examples for common infrastructure automation tasks.

## Table of Contents

1. [Overview](#overview)
2. [Terraform Examples](#terraform-examples)
3. [Ansible Examples](#ansible-examples)
4. [Combined Examples](#combined-examples)
5. [Homelab Specific Examples](#homelab-specific-examples)
6. [Security Examples](#security-examples)
7. [Troubleshooting Examples](#troubleshooting-examples)

---

## Overview

### How to Use These Examples

**Each example includes:**
- Purpose and use case
- Complete, working code
- Explanation of key parts
- Usage instructions
- Expected output

**To use:**
1. Copy the example
2. Modify for your environment
3. Test in dev first
4. Apply to production

**Variables to customize:**
- IP addresses
- Hostnames
- Proxmox node names
- Storage pools
- Credentials

---

## Terraform Examples

### Example 1: Single VM

**Purpose:** Create one Ubuntu VM

**File: single-vm.tf**

    terraform {
      required_providers {
        proxmox = {
          source  = "telmate/proxmox"
          version = "~> 2.0"
        }
      }
    }
    
    provider "proxmox" {
      pm_api_url      = "https://192.168.1.241:8006/api2/json"
      pm_user         = "terraform@pam"
      pm_password     = var.proxmox_password
      pm_tls_insecure = true
    }
    
    variable "proxmox_password" {
      type      = string
      sensitive = true
    }
    
    resource "proxmox_vm_qemu" "ubuntu_vm" {
      name        = "ubuntu-test"
      target_node = "proxmox-host01"
      
      # Clone from template
      clone = "ubuntu-22.04-template"
      
      # VM specs
      cores   = 2
      memory  = 4096
      
      # Network
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      # Disk
      disk {
        size    = "32G"
        storage = "local-lvm"
        type    = "scsi"
      }
      
      # Cloud-init configuration
      os_type   = "cloud-init"
      ipconfig0 = "ip=10.30.10.50/24,gw=10.30.10.1"
    }
    
    output "vm_ip" {
      value = proxmox_vm_qemu.ubuntu_vm.default_ipv4_address
    }

**Usage:**

    echo 'proxmox_password = "your-password"' > terraform.tfvars
    terraform init
    terraform plan
    terraform apply

**Output:**

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    
    Outputs:
    vm_ip = "10.30.10.50"

---

### Example 2: Multiple VMs with Loop

**Purpose:** Create 3 identical web servers

**File: web-cluster.tf**

    variable "web_count" {
      description = "Number of web servers"
      type        = number
      default     = 3
    }
    
    resource "proxmox_vm_qemu" "web" {
      count       = var.web_count
      name        = "web-${count.index + 1}"
      target_node = "proxmox-host01"
      clone       = "ubuntu-22.04-template"
      
      cores   = 2
      memory  = 4096
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "32G"
        storage = "local-lvm"
      }
      
      # Sequential IPs: 10.30.10.30, 10.30.10.31, 10.30.10.32
      ipconfig0 = "ip=10.30.10.${30 + count.index}/24,gw=10.30.10.1"
    }
    
    # Output all IPs
    output "web_server_ips" {
      value = [for vm in proxmox_vm_qemu.web : vm.default_ipv4_address]
    }
    
    # Output as map
    output "web_servers" {
      value = {
        for vm in proxmox_vm_qemu.web :
        vm.name => vm.default_ipv4_address
      }
    }

**Usage:**

    terraform apply

**Output:**

    Outputs:
    
    web_server_ips = [
      "10.30.10.30",
      "10.30.10.31",
      "10.30.10.32",
    ]
    web_servers = {
      "web-1" = "10.30.10.30"
      "web-2" = "10.30.10.31"
      "web-3" = "10.30.10.32"
    }

---

### Example 3: Different VM Types

**Purpose:** Create different VMs with different specs

**File: mixed-infrastructure.tf**

    # Web server (small)
    resource "proxmox_vm_qemu" "web" {
      name        = "web-server"
      target_node = "proxmox-host01"
      clone       = "ubuntu-22.04-template"
      
      cores   = 2
      memory  = 4096
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "32G"
        storage = "local-lvm"
      }
      
      ipconfig0 = "ip=10.30.10.30/24,gw=10.30.10.1"
    }
    
    # Database server (large)
    resource "proxmox_vm_qemu" "database" {
      name        = "db-server"
      target_node = "proxmox-host01"
      clone       = "ubuntu-22.04-template"
      
      cores   = 4
      memory  = 16384  # 16 GB for database
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "128G"  # More storage for data
        storage = "local-lvm"
      }
      
      ipconfig0 = "ip=10.30.10.40/24,gw=10.30.10.1"
    }
    
    # Monitoring server (medium)
    resource "proxmox_vm_qemu" "monitoring" {
      name        = "monitoring"
      target_node = "proxmox-host01"
      clone       = "ubuntu-22.04-template"
      
      cores   = 4
      memory  = 8192
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "64G"
        storage = "local-lvm"
      }
      
      ipconfig0 = "ip=10.30.10.100/24,gw=10.30.10.1"
    }
    
    output "infrastructure" {
      value = {
        web = {
          ip     = proxmox_vm_qemu.web.default_ipv4_address
          cores  = proxmox_vm_qemu.web.cores
          memory = proxmox_vm_qemu.web.memory
        }
        database = {
          ip     = proxmox_vm_qemu.database.default_ipv4_address
          cores  = proxmox_vm_qemu.database.cores
          memory = proxmox_vm_qemu.database.memory
        }
        monitoring = {
          ip     = proxmox_vm_qemu.monitoring.default_ipv4_address
          cores  = proxmox_vm_qemu.monitoring.cores
          memory = proxmox_vm_qemu.monitoring.memory
        }
      }
    }

---

### Example 4: Using Variables and Modules

**Purpose:** Reusable VM configuration

**File: modules/vm/main.tf**

    variable "vm_name" {
      type = string
    }
    
    variable "vm_cores" {
      type    = number
      default = 2
    }
    
    variable "vm_memory" {
      type    = number
      default = 4096
    }
    
    variable "vm_disk_size" {
      type    = string
      default = "32G"
    }
    
    variable "vm_ip" {
      type = string
    }
    
    resource "proxmox_vm_qemu" "vm" {
      name        = var.vm_name
      target_node = "proxmox-host01"
      clone       = "ubuntu-22.04-template"
      
      cores   = var.vm_cores
      memory  = var.vm_memory
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = var.vm_disk_size
        storage = "local-lvm"
      }
      
      ipconfig0 = "ip=${var.vm_ip}/24,gw=10.30.10.1"
    }
    
    output "ip_address" {
      value = proxmox_vm_qemu.vm.default_ipv4_address
    }

**File: main.tf (using module)**

    module "web_servers" {
      source = "./modules/vm"
      count  = 3
      
      vm_name = "web-${count.index + 1}"
      vm_ip   = "10.30.10.${30 + count.index}"
    }
    
    module "database" {
      source = "./modules/vm"
      
      vm_name      = "database"
      vm_cores     = 4
      vm_memory    = 16384
      vm_disk_size = "128G"
      vm_ip        = "10.30.10.40"
    }
    
    output "web_ips" {
      value = [for vm in module.web_servers : vm.ip_address]
    }
    
    output "db_ip" {
      value = module.database.ip_address
    }

---

## Ansible Examples

### Example 1: Basic Web Server Setup

**Purpose:** Install and configure Apache

**File: webserver.yml**

    ---
    - name: Configure web server
      hosts: webservers
      become: yes
      
      vars:
        http_port: 80
        document_root: /var/www/html
      
      tasks:
        - name: Update apt cache
          apt:
            update_cache: yes
            cache_valid_time: 3600
        
        - name: Install Apache
          apt:
            name: apache2
            state: present
        
        - name: Start and enable Apache
          service:
            name: apache2
            state: started
            enabled: yes
        
        - name: Deploy index page
          copy:
            content: |
              <!DOCTYPE html>
              <html>
              <head>
                  <title>Welcome</title>
              </head>
              <body>
                  <h1>Hello from {{ ansible_hostname }}</h1>
                  <p>IP: {{ ansible_default_ipv4.address }}</p>
              </body>
              </html>
            dest: "{{ document_root }}/index.html"
            owner: www-data
            group: www-data
            mode: '0644'
        
        - name: Configure firewall
          ufw:
            rule: allow
            port: "{{ http_port }}"
            proto: tcp

**Inventory: hosts.ini**

    [webservers]
    web01 ansible_host=10.30.10.30
    web02 ansible_host=10.30.10.31
    
    [webservers:vars]
    ansible_user=ubuntu
    ansible_python_interpreter=/usr/bin/python3

**Usage:**

    ansible-playbook -i hosts.ini webserver.yml

---

### Example 2: User Management

**Purpose:** Create users with SSH keys

**File: users.yml**

    ---
    - name: Manage users
      hosts: all
      become: yes
      
      vars:
        admin_users:
          - name: alice
            ssh_key: "ssh-rsa AAAAB3... alice@laptop"
          - name: bob
            ssh_key: "ssh-rsa AAAAB3... bob@laptop"
        
        developer_users:
          - name: charlie
            ssh_key: "ssh-rsa AAAAB3... charlie@laptop"
          - name: diana
            ssh_key: "ssh-rsa AAAAB3... diana@laptop"
      
      tasks:
        - name: Create admin group
          group:
            name: admins
            state: present
        
        - name: Create developer group
          group:
            name: developers
            state: present
        
        - name: Create admin users
          user:
            name: "{{ item.name }}"
            groups: admins,sudo
            shell: /bin/bash
            create_home: yes
          loop: "{{ admin_users }}"
        
        - name: Add SSH keys for admins
          authorized_key:
            user: "{{ item.name }}"
            key: "{{ item.ssh_key }}"
            state: present
          loop: "{{ admin_users }}"
        
        - name: Create developer users
          user:
            name: "{{ item.name }}"
            groups: developers
            shell: /bin/bash
            create_home: yes
          loop: "{{ developer_users }}"
        
        - name: Add SSH keys for developers
          authorized_key:
            user: "{{ item.name }}"
            key: "{{ item.ssh_key }}"
            state: present
          loop: "{{ developer_users }}"
        
        - name: Configure sudo for admins
          lineinfile:
            path: /etc/sudoers.d/admins
            line: "%admins ALL=(ALL) NOPASSWD: ALL"
            create: yes
            mode: '0440'
            validate: 'visudo -cf %s'

**Usage:**

    ansible-playbook -i hosts.ini users.yml

---

### Example 3: Docker Installation

**Purpose:** Install Docker on all hosts

**File: docker.yml**

    ---
    - name: Install Docker
      hosts: docker_hosts
      become: yes
      
      tasks:
        - name: Install prerequisites
          apt:
            name:
              - apt-transport-https
              - ca-certificates
              - curl
              - gnupg
              - lsb-release
            state: present
            update_cache: yes
        
        - name: Add Docker GPG key
          apt_key:
            url: https://download.docker.com/linux/ubuntu/gpg
            state: present
        
        - name: Add Docker repository
          apt_repository:
            repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
            state: present
        
        - name: Install Docker
          apt:
            name:
              - docker-ce
              - docker-ce-cli
              - containerd.io
              - docker-compose-plugin
            state: present
            update_cache: yes
        
        - name: Add user to docker group
          user:
            name: "{{ ansible_user }}"
            groups: docker
            append: yes
        
        - name: Start and enable Docker
          service:
            name: docker
            state: started
            enabled: yes
        
        - name: Test Docker installation
          command: docker run hello-world
          register: docker_test
          changed_when: false
        
        - name: Show Docker test output
          debug:
            var: docker_test.stdout_lines

**Usage:**

    ansible-playbook -i hosts.ini docker.yml

---

### Example 4: System Hardening

**Purpose:** Basic security hardening

**File: hardening.yml**

    ---
    - name: Harden system security
      hosts: all
      become: yes
      
      tasks:
        - name: Update all packages
          apt:
            upgrade: dist
            update_cache: yes
        
        - name: Install security packages
          apt:
            name:
              - ufw
              - fail2ban
              - unattended-upgrades
            state: present
        
        - name: Disable root SSH login
          lineinfile:
            path: /etc/ssh/sshd_config
            regexp: '^#?PermitRootLogin'
            line: 'PermitRootLogin no'
          notify: Restart SSH
        
        - name: Disable password authentication
          lineinfile:
            path: /etc/ssh/sshd_config
            regexp: '^#?PasswordAuthentication'
            line: 'PasswordAuthentication no'
          notify: Restart SSH
        
        - name: Configure UFW defaults
          ufw:
            direction: "{{ item.direction }}"
            policy: "{{ item.policy }}"
          loop:
            - { direction: 'incoming', policy: 'deny' }
            - { direction: 'outgoing', policy: 'allow' }
        
        - name: Allow SSH
          ufw:
            rule: allow
            port: '22'
            proto: tcp
        
        - name: Enable UFW
          ufw:
            state: enabled
        
        - name: Configure fail2ban
          copy:
            dest: /etc/fail2ban/jail.local
            content: |
              [DEFAULT]
              bantime = 3600
              findtime = 600
              maxretry = 5
              
              [sshd]
              enabled = true
          notify: Restart fail2ban
        
        - name: Enable automatic security updates
          copy:
            dest: /etc/apt/apt.conf.d/50unattended-upgrades
            content: |
              Unattended-Upgrade::Allowed-Origins {
                  "${distro_id}:${distro_codename}-security";
              };
              Unattended-Upgrade::Automatic-Reboot "false";
      
      handlers:
        - name: Restart SSH
          service:
            name: sshd
            state: restarted
        
        - name: Restart fail2ban
          service:
            name: fail2ban
            state: restarted

**Usage:**

    ansible-playbook -i hosts.ini hardening.yml

---

### Example 5: Database Setup

**Purpose:** Install and configure MySQL

**File: database.yml**

    ---
    - name: Configure MySQL database
      hosts: databases
      become: yes
      
      vars:
        mysql_root_password: "{{ vault_mysql_root_password }}"
        databases:
          - name: webapp_prod
          - name: webapp_dev
        
        db_users:
          - name: webapp
            password: "{{ vault_webapp_password }}"
            priv: "webapp_prod.*:ALL"
            host: "10.30.10.%"
      
      tasks:
        - name: Install MySQL
          apt:
            name:
              - mysql-server
              - python3-pymysql
            state: present
            update_cache: yes
        
        - name: Start MySQL
          service:
            name: mysql
            state: started
            enabled: yes
        
        - name: Set MySQL root password
          mysql_user:
            name: root
            password: "{{ mysql_root_password }}"
            login_unix_socket: /var/run/mysqld/mysqld.sock
          no_log: true
        
        - name: Create databases
          mysql_db:
            name: "{{ item.name }}"
            state: present
            login_user: root
            login_password: "{{ mysql_root_password }}"
          loop: "{{ databases }}"
          no_log: true
        
        - name: Create database users
          mysql_user:
            name: "{{ item.name }}"
            password: "{{ item.password }}"
            priv: "{{ item.priv }}"
            host: "{{ item.host }}"
            state: present
            login_user: root
            login_password: "{{ mysql_root_password }}"
          loop: "{{ db_users }}"
          no_log: true
        
        - name: Configure MySQL for remote access
          lineinfile:
            path: /etc/mysql/mysql.conf.d/mysqld.cnf
            regexp: '^bind-address'
            line: 'bind-address = 0.0.0.0'
          notify: Restart MySQL
        
        - name: Configure firewall for MySQL
          ufw:
            rule: allow
            port: '3306'
            proto: tcp
            src: '10.30.10.0/24'
      
      handlers:
        - name: Restart MySQL
          service:
            name: mysql
            state: restarted

**Create vault file:**

    ansible-vault create group_vars/all/vault.yml

**Content:**

    vault_mysql_root_password: "secure_root_password"
    vault_webapp_password: "secure_app_password"

**Usage:**

    ansible-playbook -i hosts.ini --ask-vault-pass database.yml

---

## Combined Examples

### Example 1: Complete Web Stack

**Purpose:** Deploy complete web application stack

**Directory structure:**

    web-stack/
    ├── terraform/
    │   ├── main.tf
    │   └── outputs.tf
    ├── ansible/
    │   ├── inventory.ini (generated)
    │   ├── site.yml
    │   ├── webserver.yml
    │   └── database.yml
    └── deploy.sh

**File: terraform/main.tf**

    terraform {
      required_providers {
        proxmox = {
          source  = "telmate/proxmox"
          version = "~> 2.0"
        }
      }
    }
    
    provider "proxmox" {
      pm_api_url      = var.proxmox_url
      pm_user         = "terraform@pam"
      pm_password     = var.proxmox_password
      pm_tls_insecure = true
    }
    
    variable "proxmox_url" {}
    variable "proxmox_password" { sensitive = true }
    
    # Web servers
    resource "proxmox_vm_qemu" "web" {
      count       = 2
      name        = "web-${count.index + 1}"
      target_node = "proxmox-host01"
      clone       = "ubuntu-22.04-template"
      
      cores   = 2
      memory  = 4096
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "32G"
        storage = "local-lvm"
      }
      
      ipconfig0 = "ip=10.30.10.${30 + count.index}/24,gw=10.30.10.1"
    }
    
    # Database server
    resource "proxmox_vm_qemu" "database" {
      name        = "database"
      target_node = "proxmox-host01"
      clone       = "ubuntu-22.04-template"
      
      cores   = 4
      memory  = 8192
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "64G"
        storage = "local-lvm"
      }
      
      ipconfig0 = "ip=10.30.10.40/24,gw=10.30.10.1"
    }

**File: terraform/outputs.tf**

    output "web_servers" {
      value = {
        for vm in proxmox_vm_qemu.web :
        vm.name => vm.default_ipv4_address
      }
    }
    
    output "database_server" {
      value = proxmox_vm_qemu.database.default_ipv4_address
    }

**File: ansible/site.yml**

    ---
    - import_playbook: database.yml
    - import_playbook: webserver.yml

**File: deploy.sh**

    #!/bin/bash
    set -e
    
    echo "==> Deploying web stack"
    
    # Terraform
    cd terraform
    terraform init
    terraform apply -auto-approve
    
    # Generate inventory
    cat > ../ansible/inventory.ini <<EOF
    [webservers]
    $(terraform output -json web_servers | jq -r 'to_entries[] | "\(.key) ansible_host=\(.value)"')
    
    [databases]
    database ansible_host=$(terraform output -raw database_server)
    
    [all:vars]
    ansible_user=ubuntu
    ansible_python_interpreter=/usr/bin/python3
    EOF
    
    # Wait for VMs
    echo "==> Waiting for VMs to boot"
    sleep 30
    
    # Ansible
    cd ../ansible
    ansible-playbook -i inventory.ini site.yml
    
    echo "==> Deployment complete!"

**Usage:**

    chmod +x deploy.sh
    ./deploy.sh

---

### Example 2: AD Lab Environment

**Purpose:** Deploy Active Directory lab for pentesting

**File: terraform/lab.tf**

    # Domain Controller
    resource "proxmox_vm_qemu" "dc" {
      name        = "dc01"
      target_node = "proxmox-host01"
      clone       = "windows-server-2022-template"
      
      cores   = 2
      memory  = 4096
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "64G"
        storage = "local-lvm"
      }
      
      ipconfig0 = "ip=10.30.10.10/24,gw=10.30.10.1"
    }
    
    # Windows clients
    resource "proxmox_vm_qemu" "client" {
      count       = 2
      name        = "client-${count.index + 1}"
      target_node = "proxmox-host01"
      clone       = "windows-10-template"
      
      cores   = 2
      memory  = 4096
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "64G"
        storage = "local-lvm"
      }
      
      ipconfig0 = "ip=10.30.20.${10 + count.index}/24,gw=10.30.10.1"
    }
    
    # Kali attacker
    resource "proxmox_vm_qemu" "kali" {
      name        = "kali"
      target_node = "proxmox-host01"
      clone       = "kali-linux-template"
      
      cores   = 4
      memory  = 8192
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "64G"
        storage = "local-lvm"
      }
      
      ipconfig0 = "ip=10.30.66.10/24,gw=10.30.10.1"
    }

**File: ansible/configure-ad.yml**

    ---
    - name: Configure Domain Controller
      hosts: dc
      
      tasks:
        - name: Install AD Domain Services
          win_feature:
            name: AD-Domain-Services
            state: present
            include_management_tools: yes
        
        - name: Create AD Forest
          win_domain:
            dns_domain_name: lab.local
            safe_mode_password: "P@ssw0rd123"
          register: ad_forest
        
        - name: Reboot after AD install
          win_reboot:
          when: ad_forest.reboot_required
        
        - name: Create OUs
          win_domain_ou:
            name: "{{ item }}"
            path: "DC=lab,DC=local"
            state: present
          loop:
            - Servers
            - Workstations
            - Users
        
        - name: Create domain users
          win_domain_user:
            name: "{{ item.name }}"
            password: "{{ item.password }}"
            path: "OU=Users,DC=lab,DC=local"
            state: present
          loop:
            - { name: "admin", password: "Admin123!" }
            - { name: "user1", password: "User123!" }
            - { name: "user2", password: "User123!" }

---

## Homelab Specific Examples

### Example 1: Jumphost Configuration

**Purpose:** Configure SSH bastion for lab access

**File: jumphost.yml**

    ---
    - name: Configure jumphost
      hosts: jumphost
      become: yes
      
      vars:
        ssh_port: 2222
        allowed_users:
          - alice
          - bob
      
      tasks:
        - name: Change SSH port
          lineinfile:
            path: /etc/ssh/sshd_config
            regexp: '^#?Port'
            line: "Port {{ ssh_port }}"
          notify: Restart SSH
        
        - name: Disable password authentication
          lineinfile:
            path: /etc/ssh/sshd_config
            regexp: '^#?PasswordAuthentication'
            line: 'PasswordAuthentication no'
          notify: Restart SSH
        
        - name: Allow only specific users
          lineinfile:
            path: /etc/ssh/sshd_config
            line: "AllowUsers {{ allowed_users | join(' ') }}"
          notify: Restart SSH
        
        - name: Install useful tools
          apt:
            name:
              - tmux
              - htop
              - vim
              - curl
              - wget
            state: present
        
        - name: Configure firewall
          ufw:
            rule: allow
            port: "{{ ssh_port }}"
            proto: tcp
        
        - name: Enable firewall
          ufw:
            state: enabled
      
      handlers:
        - name: Restart SSH
          service:
            name: sshd
            state: restarted

---

### Example 2: Wazuh SIEM Deployment

**Purpose:** Deploy Wazuh for security monitoring

**File: wazuh.yml**

    ---
    - name: Deploy Wazuh SIEM
      hosts: wazuh
      become: yes
      
      tasks:
        - name: Install prerequisites
          apt:
            name:
              - curl
              - apt-transport-https
              - gnupg
            state: present
        
        - name: Add Wazuh GPG key
          apt_key:
            url: https://packages.wazuh.com/key/GPG-KEY-WAZUH
            state: present
        
        - name: Add Wazuh repository
          apt_repository:
            repo: "deb https://packages.wazuh.com/4.x/apt/ stable main"
            state: present
        
        - name: Install Wazuh manager
          apt:
            name: wazuh-manager
            state: present
            update_cache: yes
        
        - name: Start Wazuh manager
          service:
            name: wazuh-manager
            state: started
            enabled: yes
        
        - name: Get Wazuh manager status
          command: systemctl status wazuh-manager
          register: wazuh_status
          changed_when: false
        
        - name: Display status
          debug:
            var: wazuh_status.stdout_lines

---

## Security Examples

### Example 1: SSL Certificate Deployment

**Purpose:** Deploy Let's Encrypt certificates

**File: ssl-certs.yml**

    ---
    - name: Deploy SSL certificates
      hosts: webservers
      become: yes
      
      vars:
        domain: example.com
        email: admin@example.com
      
      tasks:
        - name: Install certbot
          apt:
            name:
              - certbot
              - python3-certbot-apache
            state: present
        
        - name: Obtain SSL certificate
          command: >
            certbot --apache
            --non-interactive
            --agree-tos
            --email {{ email }}
            -d {{ domain }}
          args:
            creates: /etc/letsencrypt/live/{{ domain }}/fullchain.pem
        
        - name: Set up auto-renewal
          cron:
            name: "Renew Let's Encrypt certificates"
            minute: "0"
            hour: "2"
            job: "certbot renew --quiet"

---

### Example 2: Vulnerability Scanning Setup

**Purpose:** Configure OpenVAS for vulnerability scanning

**File: openvas.yml**

    ---
    - name: Install OpenVAS
      hosts: scanner
      become: yes
      
      tasks:
        - name: Install OpenVAS
          apt:
            name: openvas
            state: present
            update_cache: yes
        
        - name: Run OpenVAS setup
          command: gvm-setup
          args:
            creates: /var/lib/gvm/.setup_complete
        
        - name: Start OpenVAS services
          service:
            name: "{{ item }}"
            state: started
            enabled: yes
          loop:
            - gvmd
            - gsad
            - ospd-openvas

---

## Troubleshooting Examples

### Example 1: Connectivity Test Playbook

**Purpose:** Test connectivity and gather info

**File: test-connectivity.yml**

    ---
    - name: Test connectivity
      hosts: all
      gather_facts: no
      
      tasks:
        - name: Ping test
          ping:
        
        - name: Gather facts
          setup:
        
        - name: Display hostname
          debug:
            msg: "Hostname: {{ ansible_hostname }}"
        
        - name: Display IP address
          debug:
            msg: "IP: {{ ansible_default_ipv4.address }}"
        
        - name: Check disk space
          command: df -h
          register: disk_space
        
        - name: Display disk space
          debug:
            var: disk_space.stdout_lines
        
        - name: Check memory
          command: free -h
          register: memory
        
        - name: Display memory
          debug:
            var: memory.stdout_lines

**Usage:**

    ansible-playbook -i hosts.ini test-connectivity.yml

---

### Example 2: Service Status Check

**Purpose:** Check status of services across all hosts

**File: check-services.yml**

    ---
    - name: Check service status
      hosts: all
      become: yes
      
      vars:
        services_to_check:
          - apache2
          - mysql
          - docker
      
      tasks:
        - name: Check service status
          service_facts:
        
        - name: Display service status
          debug:
            msg: "{{ item }} is {{ ansible_facts.services[item + '.service'].state | default('not installed') }}"
          loop: "{{ services_to_check }}"

---

### Example 3: Log Collection

**Purpose:** Collect logs from all servers

**File: collect-logs.yml**

    ---
    - name: Collect logs
      hosts: all
      become: yes
      
      tasks:
        - name: Create logs directory locally
          local_action:
            module: file
            path: "./collected-logs/{{ inventory_hostname }}"
            state: directory
          run_once: no
        
        - name: Fetch syslog
          fetch:
            src: /var/log/syslog
            dest: "./collected-logs/{{ inventory_hostname }}/syslog"
            flat: yes
        
        - name: Fetch auth log
          fetch:
            src: /var/log/auth.log
            dest: "./collected-logs/{{ inventory_hostname }}/auth.log"
            flat: yes

**Usage:**

    ansible-playbook -i hosts.ini collect-logs.yml
    ls collected-logs/

---

## Quick Reference

### Common Terraform Commands

    terraform init              # Initialize
    terraform plan              # Preview changes
    terraform apply             # Apply changes
    terraform destroy           # Destroy infrastructure
    terraform output            # Show outputs
    terraform show              # Show state
    terraform fmt               # Format code
    terraform validate          # Validate syntax

### Common Ansible Commands

    ansible all -m ping                          # Test connectivity
    ansible all -m setup                         # Gather facts
    ansible-playbook playbook.yml                # Run playbook
    ansible-playbook --check playbook.yml        # Dry run
    ansible-playbook --syntax-check playbook.yml # Check syntax
    ansible-playbook --list-tasks playbook.yml   # List tasks
    ansible-playbook --limit host playbook.yml   # Run on one host
    ansible-playbook --tags tag playbook.yml     # Run specific tags

---

## Next Steps

Now that you have examples:

1. **Copy and modify:** Adapt examples for your environment
2. **Test:** Always test in dev first
3. **Combine:** Mix examples to create your workflows
4. **Document:** Add your own examples
5. **Share:** Contribute back to the community

---

## Additional Resources

**More examples:**
- [Terraform Examples](../terraform/examples/)
- [Ansible Examples](../ansible/examples/)
- [Complete Workflows](../workflows/)

**Documentation:**
- [Terraform Docs](TERRAFORM_BASICS.md)
- [Ansible Docs](ANSIBLE_BASICS.md)
- [Integration Guide](TERRAFORM_AND_ANSIBLE.md)

---

Last Updated: February 2026
