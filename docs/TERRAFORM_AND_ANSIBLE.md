# Terraform and Ansible Together

A comprehensive guide to integrating Terraform and Ansible for complete infrastructure automation.

## Table of Contents

1. [Why Use Both?](#why-use-both)
2. [The Division of Labor](#the-division-of-labor)
3. [Integration Patterns](#integration-patterns)
4. [Workflow Examples](#workflow-examples)
5. [Passing Data Between Tools](#passing-data-between-tools)
6. [Complete Lab Deployment Example](#complete-lab-deployment-example)
7. [Best Practices](#best-practices)
8. [Common Patterns](#common-patterns)
9. [Troubleshooting](#troubleshooting)

---

## Why Use Both?

### The Problem with Using Just One

**If you only use Terraform:**
- Creates infrastructure (VMs, networks)
- But VMs are empty (just OS installed)
- You still need to:
  - Install software
  - Configure services
  - Deploy applications
  - Manage users

**If you only use Ansible:**
- Can install software and configure systems
- But infrastructure must already exist
- You still need to:
  - Create VMs manually
  - Set up networks manually
  - Manage infrastructure lifecycle

### The Solution: Use Both

**Terraform + Ansible = Complete Automation**

    ┌─────────────────────────────────────┐
    │         Terraform                   │
    │  "Build the house"                  │
    │                                     │
    │  Creates:                           │
    │  - Virtual machines                 │
    │  - Networks                         │
    │  - Storage                          │
    │  - Infrastructure                   │
    └──────────────┬──────────────────────┘
                   │
                   │ Outputs: IP addresses, hostnames
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │         Ansible                     │
    │  "Furnish the house"                │
    │                                     │
    │  Configures:                        │
    │  - Software installation            │
    │  - Service configuration            │
    │  - Application deployment           │
    │  - System settings                  │
    └─────────────────────────────────────┘

### Real-World Analogy

**Building a house:**

**Terraform = Construction crew**
- Pours foundation
- Builds walls
- Installs plumbing and electrical
- Creates structure

**Ansible = Interior designer**
- Paints walls
- Installs furniture
- Arranges decorations
- Makes it livable

**Both are needed for a complete house!**

---

## The Division of Labor

### What Terraform Does Best

**Infrastructure Provisioning:**

    ✓ Create VMs
    ✓ Define networks
    ✓ Allocate storage
    ✓ Set up load balancers
    ✓ Configure cloud resources
    ✓ Manage infrastructure lifecycle

**Terraform excels at:**
- Creating infrastructure from scratch
- Managing infrastructure state
- Handling resource dependencies
- Destroying infrastructure cleanly

**Example Terraform task:**

    resource "proxmox_vm_qemu" "web" {
      name   = "web-server"
      cores  = 4
      memory = 8192
    }

**Result:** VM exists, powered on, with OS installed

---

### What Ansible Does Best

**Configuration Management:**

    ✓ Install software packages
    ✓ Configure services
    ✓ Deploy applications
    ✓ Manage users and permissions
    ✓ Update configurations
    ✓ Run maintenance tasks

**Ansible excels at:**
- Configuring existing systems
- Installing and managing software
- Ongoing system maintenance
- Complex multi-step procedures

**Example Ansible task:**

    - name: Configure web server
      tasks:
        - name: Install Apache
          apt:
            name: apache2
            state: present
        
        - name: Deploy website
          copy:
            src: website/
            dest: /var/www/html/

**Result:** Web server fully configured and serving content

---

### Clear Boundaries

**Question:** Where does Terraform end and Ansible begin?

**Answer:** When the infrastructure exists and needs configuration.

**The Handoff:**

    Terraform creates VM → VM boots → Ansible configures VM
    
    Terraform's job ends when:
    - VM is created
    - Network is configured
    - VM is accessible via SSH
    
    Ansible's job starts when:
    - VM is reachable
    - SSH connection works
    - Ready for configuration

---

## Integration Patterns

### Pattern 1: Sequential Execution (Simple)

**Most common pattern for beginners**

**Steps:**

    1. Run Terraform
       terraform apply
    
    2. Wait for infrastructure
       (VMs are created)
    
    3. Get outputs
       terraform output -json > outputs.json
    
    4. Run Ansible
       ansible-playbook playbook.yml

**Workflow:**

    Manual → Terraform → Manual → Ansible → Done
    
    You run:        terraform apply
    Terraform:      Creates VMs
    You check:      VMs are ready
    You run:        ansible-playbook playbook.yml
    Ansible:        Configures VMs
    Done:           Complete infrastructure

**Pros:**
- Simple and clear
- Easy to understand
- Good for learning
- Easy to troubleshoot

**Cons:**
- Manual steps between tools
- Not fully automated
- Requires intervention

**Best for:**
- Learning
- Small projects
- When you want control at each step

---

### Pattern 2: Terraform Outputs to Ansible Inventory (Better)

**Automate the handoff**

**How it works:**

    1. Terraform creates infrastructure
    2. Terraform outputs IP addresses
    3. Script generates Ansible inventory
    4. Ansible runs automatically

**Terraform outputs:**

    output "vm_ips" {
      value = {
        web01 = proxmox_vm_qemu.web01.default_ipv4_address
        web02 = proxmox_vm_qemu.web02.default_ipv4_address
      }
    }

**Generate inventory script:**

    #!/bin/bash
    # generate_inventory.sh
    
    terraform output -json vm_ips | jq -r 'to_entries[] | 
      "\(.key) ansible_host=\(.value)"' > inventory.ini

**Run complete workflow:**

    terraform apply
    ./generate_inventory.sh
    ansible-playbook -i inventory.ini playbook.yml

**Pros:**
- Semi-automated
- Terraform outputs feed Ansible
- Still maintainable

**Cons:**
- Requires script
- Manual execution steps

**Best for:**
- Production workflows
- Team environments
- Repeatable deployments

---

### Pattern 3: Local-Exec Provisioner (Automated)

**Terraform calls Ansible automatically**

**Terraform configuration:**

    resource "proxmox_vm_qemu" "web" {
      name   = "web-server"
      cores  = 4
      memory = 8192
      
      # Wait for VM to be ready
      provisioner "remote-exec" {
        inline = ["echo 'VM is ready'"]
        
        connection {
          type     = "ssh"
          host     = self.default_ipv4_address
          user     = "ubuntu"
          private_key = file("~/.ssh/id_rsa")
        }
      }
      
      # Run Ansible
      provisioner "local-exec" {
        command = "ansible-playbook -i '${self.default_ipv4_address},' playbook.yml"
      }
    }

**Workflow:**

    terraform apply
    
    Terraform:
    1. Creates VM
    2. Waits for SSH
    3. Calls Ansible automatically
    4. Returns when complete

**Pros:**
- Fully automated
- Single command
- Integrated workflow

**Cons:**
- Tightly coupled (if Ansible fails, Terraform state affected)
- Harder to debug
- Less flexible

**Best for:**
- Simple deployments
- When full automation needed
- CI/CD pipelines

---

### Pattern 4: Separate Tool Orchestration (Advanced)

**Use orchestration tool to manage both**

**Tools:**
- Shell scripts
- Makefiles
- CI/CD pipelines (GitHub Actions, GitLab CI)

**Makefile example:**

    .PHONY: all plan deploy destroy
    
    all: deploy
    
    plan:
    	terraform plan
    
    deploy:
    	terraform apply -auto-approve
    	./generate_inventory.sh
    	ansible-playbook -i inventory.ini playbook.yml
    
    destroy:
    	terraform destroy -auto-approve

**Usage:**

    make deploy

**Pros:**
- Complete control
- Can add validation steps
- Easy to extend
- Professional approach

**Cons:**
- Requires additional tool
- More complexity

**Best for:**
- Large projects
- Teams
- Production environments
- Complex workflows

---

## Workflow Examples

### Example 1: Single Web Server

**Goal:** Deploy one web server with Apache

**Terraform (infrastructure):**

**File: main.tf**

    terraform {
      required_providers {
        proxmox = {
          source  = "telmate/proxmox"
          version = "~> 2.0"
        }
      }
    }
    
    provider "proxmox" {
      pm_api_url  = var.proxmox_url
      pm_user     = var.proxmox_user
      pm_password = var.proxmox_password
      pm_tls_insecure = true
    }
    
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
        type    = "scsi"
      }
      
      ipconfig0 = "ip=10.30.10.30/24,gw=10.30.10.1"
    }
    
    output "web_server_ip" {
      value = proxmox_vm_qemu.web.default_ipv4_address
    }

**Step 1: Create infrastructure**

    terraform init
    terraform apply

**Output:**

    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    
    Outputs:
    
    web_server_ip = "10.30.10.30"

---

**Ansible (configuration):**

**File: inventory.ini**

    [webservers]
    web-server ansible_host=10.30.10.30 ansible_user=ubuntu

**File: webserver.yml**

    ---
    - name: Configure web server
      hosts: webservers
      become: yes
      
      tasks:
        - name: Update apt cache
          apt:
            update_cache: yes
        
        - name: Install Apache
          apt:
            name: apache2
            state: present
        
        - name: Deploy website
          copy:
            content: |
              <html>
              <head><title>My Web Server</title></head>
              <body>
                <h1>Hello from Ansible!</h1>
                <p>Server: {{ ansible_hostname }}</p>
                <p>IP: {{ ansible_default_ipv4.address }}</p>
              </body>
              </html>
            dest: /var/www/html/index.html
            owner: www-data
            group: www-data
        
        - name: Start Apache
          service:
            name: apache2
            state: started
            enabled: yes

**Step 2: Configure system**

    ansible-playbook -i inventory.ini webserver.yml

**Output:**

    PLAY [Configure web server] ************************************
    
    TASK [Update apt cache] ****************************************
    changed: [web-server]
    
    TASK [Install Apache] ******************************************
    changed: [web-server]
    
    TASK [Deploy website] ******************************************
    changed: [web-server]
    
    TASK [Start Apache] ********************************************
    ok: [web-server]
    
    PLAY RECAP *****************************************************
    web-server : ok=4    changed=3    unreachable=0    failed=0

**Step 3: Verify**

    curl http://10.30.10.30

**Result:** Web page loads!

---

### Example 2: Multiple Servers with Automated Inventory

**Goal:** Deploy 3 web servers automatically

**Terraform:**

**File: main.tf**

    variable "web_count" {
      default = 3
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
      
      ipconfig0 = "ip=10.30.10.${30 + count.index}/24,gw=10.30.10.1"
    }
    
    output "web_servers" {
      value = {
        for vm in proxmox_vm_qemu.web :
        vm.name => vm.default_ipv4_address
      }
    }

**Generate inventory script:**

**File: generate_inventory.sh**

    #!/bin/bash
    
    # Generate Ansible inventory from Terraform outputs
    
    echo "[webservers]" > inventory.ini
    
    terraform output -json web_servers | jq -r '
      to_entries[] | 
      "\(.key) ansible_host=\(.value) ansible_user=ubuntu"
    ' >> inventory.ini
    
    echo "" >> inventory.ini
    echo "[webservers:vars]" >> inventory.ini
    echo "ansible_python_interpreter=/usr/bin/python3" >> inventory.ini

**Deploy script:**

**File: deploy.sh**

    #!/bin/bash
    set -e
    
    echo "==> Step 1: Creating infrastructure with Terraform"
    terraform init
    terraform apply -auto-approve
    
    echo ""
    echo "==> Step 2: Generating Ansible inventory"
    ./generate_inventory.sh
    
    echo ""
    echo "==> Waiting 30 seconds for VMs to fully boot..."
    sleep 30
    
    echo ""
    echo "==> Step 3: Configuring servers with Ansible"
    ansible-playbook -i inventory.ini webserver.yml
    
    echo ""
    echo "==> Deployment complete!"
    echo "==> Web servers available at:"
    terraform output -json web_servers | jq -r 'to_entries[] | "    http://\(.value)"'

**Run complete deployment:**

    chmod +x deploy.sh generate_inventory.sh
    ./deploy.sh

**Result:** 3 web servers created and configured automatically!

---

### Example 3: AD Lab Environment

**Goal:** Deploy complete Active Directory lab

**Infrastructure needs:**
- Domain Controller (Windows Server)
- SQL Server
- 2 Windows clients
- All on lab VLAN

**Terraform creates:**
- 4 VMs with proper specs
- Network configuration
- Storage allocation

**Ansible configures:**
- Install AD Domain Services
- Create domain
- Install SQL Server
- Join clients to domain
- Configure DNS

**File structure:**

    lab-deployment/
    ├── terraform/
    │   ├── main.tf           # VM definitions
    │   ├── variables.tf
    │   └── outputs.tf        # IP addresses
    ├── ansible/
    │   ├── inventory/
    │   │   └── hosts.ini     # Generated from Terraform
    │   ├── playbooks/
    │   │   ├── domain-controller.yml
    │   │   ├── sql-server.yml
    │   │   └── join-domain.yml
    │   └── group_vars/
    │       └── all.yml       # Domain config
    └── deploy.sh             # Master script

**We'll build this complete example in the workflows/ directory!**

---

## Passing Data Between Tools

### Terraform Outputs

**Terraform can output any resource attribute:**

    output "vm_details" {
      value = {
        name       = proxmox_vm_qemu.web.name
        ip_address = proxmox_vm_qemu.web.default_ipv4_address
        vm_id      = proxmox_vm_qemu.web.vmid
        memory     = proxmox_vm_qemu.web.memory
        cores      = proxmox_vm_qemu.web.cores
      }
    }

**Get outputs:**

    # Human-readable
    terraform output
    
    # JSON format (for scripts)
    terraform output -json
    
    # Specific output
    terraform output vm_details

---

### Converting to Ansible Inventory

**Method 1: Manual inventory creation**

After terraform apply, create inventory.ini:

    [webservers]
    web01 ansible_host=10.30.10.30
    web02 ansible_host=10.30.10.31

---

**Method 2: Script generation**

**Using jq:**

    terraform output -json web_servers | \
      jq -r 'to_entries[] | "\(.key) ansible_host=\(.value)"' \
      > inventory.ini

---

**Method 3: Dynamic inventory**

**Python script that reads Terraform state:**

    #!/usr/bin/env python3
    import json
    import subprocess
    
    # Get Terraform outputs
    result = subprocess.run(
        ['terraform', 'output', '-json'],
        capture_output=True,
        text=True
    )
    outputs = json.loads(result.stdout)
    
    # Build Ansible inventory
    inventory = {
        'webservers': {
            'hosts': []
        }
    }
    
    for name, ip in outputs['web_servers']['value'].items():
        inventory['webservers']['hosts'].append(ip)
    
    print(json.dumps(inventory, indent=2))

**Use with Ansible:**

    ansible-playbook -i terraform_inventory.py playbook.yml

---

### Passing Variables

**Terraform → Ansible:**

**Terraform outputs:**

    output "domain_name" {
      value = "lab.local"
    }
    
    output "dc_ip" {
      value = proxmox_vm_qemu.dc.default_ipv4_address
    }

**Ansible variables (from Terraform):**

    # Get values
    DOMAIN=$(terraform output -raw domain_name)
    DC_IP=$(terraform output -raw dc_ip)
    
    # Pass to Ansible
    ansible-playbook playbook.yml \
      -e "domain_name=$DOMAIN" \
      -e "dc_ip_address=$DC_IP"

**Or write to vars file:**

    terraform output -json | jq '{
      domain_name: .domain_name.value,
      dc_ip_address: .dc_ip.value
    }' > ansible/group_vars/all.yml

---

## Complete Lab Deployment Example

### Scenario: Simple Web Application Stack

**Components:**
- 1 web server (Apache + PHP)
- 1 database server (MySQL)
- Network configuration

### Step-by-Step Implementation

**Directory structure:**

    web-stack/
    ├── terraform/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ansible/
    │   ├── inventory.ini (generated)
    │   ├── webserver.yml
    │   └── database.yml
    └── deploy.sh

---

**Terraform configuration:**

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
      pm_user         = var.proxmox_user
      pm_password     = var.proxmox_password
      pm_tls_insecure = true
    }
    
    # Web server
    resource "proxmox_vm_qemu" "web" {
      name        = "web-server"
      target_node = var.proxmox_node
      clone       = var.template_name
      
      cores   = 2
      memory  = 4096
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "32G"
        storage = var.storage
      }
      
      ipconfig0 = "ip=10.30.10.30/24,gw=10.30.10.1"
    }
    
    # Database server
    resource "proxmox_vm_qemu" "db" {
      name        = "db-server"
      target_node = var.proxmox_node
      clone       = var.template_name
      
      cores   = 2
      memory  = 8192  # More RAM for database
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "64G"  # More storage for database
        storage = var.storage
      }
      
      ipconfig0 = "ip=10.30.10.40/24,gw=10.30.10.1"
    }

**File: terraform/variables.tf**

    variable "proxmox_url" {
      description = "Proxmox API URL"
      type        = string
    }
    
    variable "proxmox_user" {
      description = "Proxmox API user"
      type        = string
      default     = "terraform@pam"
    }
    
    variable "proxmox_password" {
      description = "Proxmox API password"
      type        = string
      sensitive   = true
    }
    
    variable "proxmox_node" {
      description = "Proxmox node name"
      type        = string
      default     = "proxmox-host01"
    }
    
    variable "template_name" {
      description = "VM template to clone"
      type        = string
      default     = "ubuntu-22.04-template"
    }
    
    variable "storage" {
      description = "Storage pool"
      type        = string
      default     = "local-lvm"
    }

**File: terraform/outputs.tf**

    output "web_server_ip" {
      description = "Web server IP address"
      value       = proxmox_vm_qemu.web.default_ipv4_address
    }
    
    output "db_server_ip" {
      description = "Database server IP address"
      value       = proxmox_vm_qemu.db.default_ipv4_address
    }
    
    output "stack_info" {
      description = "Complete stack information"
      value = {
        web = {
          name = proxmox_vm_qemu.web.name
          ip   = proxmox_vm_qemu.web.default_ipv4_address
        }
        db = {
          name = proxmox_vm_qemu.db.name
          ip   = proxmox_vm_qemu.db.default_ipv4_address
        }
      }
    }

---

**Ansible configuration:**

**File: ansible/webserver.yml**

    ---
    - name: Configure web server
      hosts: webservers
      become: yes
      
      vars:
        db_host: "{{ groups['databases'][0] }}"
      
      tasks:
        - name: Update apt cache
          apt:
            update_cache: yes
            cache_valid_time: 3600
        
        - name: Install web server packages
          apt:
            name:
              - apache2
              - php
              - php-mysql
              - libapache2-mod-php
            state: present
        
        - name: Deploy sample PHP application
          copy:
            content: |
              <?php
              $servername = "{{ db_host }}";
              $username = "webapp";
              $password = "secure_password";
              $dbname = "myapp";
              
              // Create connection
              $conn = new mysqli($servername, $username, $password, $dbname);
              
              // Check connection
              if ($conn->connect_error) {
                die("Connection failed: " . $conn->connect_error);
              }
              
              echo "<h1>Web Application</h1>";
              echo "<p>Connected to database successfully!</p>";
              echo "<p>Database server: $servername</p>";
              
              $conn->close();
              ?>
            dest: /var/www/html/index.php
            owner: www-data
            group: www-data
            mode: '0644'
        
        - name: Enable PHP module
          apache2_module:
            name: php
            state: present
          notify: Restart Apache
        
        - name: Start Apache
          service:
            name: apache2
            state: started
            enabled: yes
      
      handlers:
        - name: Restart Apache
          service:
            name: apache2
            state: restarted

**File: ansible/database.yml**

    ---
    - name: Configure database server
      hosts: databases
      become: yes
      
      vars:
        mysql_root_password: "root_secure_password"
        db_name: "myapp"
        db_user: "webapp"
        db_password: "secure_password"
      
      tasks:
        - name: Update apt cache
          apt:
            update_cache: yes
            cache_valid_time: 3600
        
        - name: Install MySQL server
          apt:
            name:
              - mysql-server
              - python3-pymysql
            state: present
        
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
        
        - name: Create application database
          mysql_db:
            name: "{{ db_name }}"
            state: present
            login_user: root
            login_password: "{{ mysql_root_password }}"
        
        - name: Create application user
          mysql_user:
            name: "{{ db_user }}"
            password: "{{ db_password }}"
            priv: "{{ db_name }}.*:ALL"
            host: "10.30.10.%"
            state: present
            login_user: root
            login_password: "{{ mysql_root_password }}"
          no_log: true
        
        - name: Configure MySQL to listen on all interfaces
          lineinfile:
            path: /etc/mysql/mysql.conf.d/mysqld.cnf
            regexp: '^bind-address'
            line: 'bind-address = 0.0.0.0'
          notify: Restart MySQL
      
      handlers:
        - name: Restart MySQL
          service:
            name: mysql
            state: restarted

---

**Deployment script:**

**File: deploy.sh**

    #!/bin/bash
    set -e
    
    echo "============================================"
    echo "Web Stack Deployment"
    echo "============================================"
    echo ""
    
    # Change to terraform directory
    cd terraform
    
    echo "==> Step 1: Initializing Terraform"
    terraform init
    
    echo ""
    echo "==> Step 2: Creating infrastructure"
    terraform apply -auto-approve
    
    echo ""
    echo "==> Step 3: Getting infrastructure details"
    WEB_IP=$(terraform output -raw web_server_ip)
    DB_IP=$(terraform output -raw db_server_ip)
    
    echo "    Web Server IP: $WEB_IP"
    echo "    Database IP: $DB_IP"
    
    # Return to root directory
    cd ..
    
    echo ""
    echo "==> Step 4: Generating Ansible inventory"
    cat > ansible/inventory.ini <<EOF
[webservers]
web-server ansible_host=$WEB_IP ansible_user=ubuntu

[databases]
db-server ansible_host=$DB_IP ansible_user=ubuntu

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
    
    echo "    Inventory generated"
    
    echo ""
    echo "==> Step 5: Waiting for VMs to be ready (30 seconds)"
    sleep 30
    
    echo ""
    echo "==> Step 6: Testing connectivity"
    cd ansible
    ansible all -i inventory.ini -m ping
    
    echo ""
    echo "==> Step 7: Configuring database server"
    ansible-playbook -i inventory.ini database.yml
    
    echo ""
    echo "==> Step 8: Configuring web server"
    ansible-playbook -i inventory.ini webserver.yml
    
    cd ..
    
    echo ""
    echo "============================================"
    echo "Deployment Complete!"
    echo "============================================"
    echo ""
    echo "Web Application URL: http://$WEB_IP/index.php"
    echo ""
    echo "To destroy:"
    echo "  cd terraform && terraform destroy"

**Make executable and run:**

    chmod +x deploy.sh
    ./deploy.sh

**Output:**

    ============================================
    Web Stack Deployment
    ============================================
    
    ==> Step 1: Initializing Terraform
    ...
    
    ==> Step 2: Creating infrastructure
    Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
    
    ==> Step 3: Getting infrastructure details
        Web Server IP: 10.30.10.30
        Database IP: 10.30.10.40
    
    ==> Step 4: Generating Ansible inventory
        Inventory generated
    
    ==> Step 5: Waiting for VMs to be ready (30 seconds)
    
    ==> Step 6: Testing connectivity
    web-server | SUCCESS => ...
    db-server | SUCCESS => ...
    
    ==> Step 7: Configuring database server
    PLAY [Configure database server] ...
    ...
    
    ==> Step 8: Configuring web server
    PLAY [Configure web server] ...
    ...
    
    ============================================
    Deployment Complete!
    ============================================
    
    Web Application URL: http://10.30.10.30/index.php

**Visit URL and see working application!**

---

## Best Practices

### 1. Clear Separation of Concerns

**Terraform:**
- Only infrastructure
- No configuration
- Outputs: Minimum data needed by Ansible

**Ansible:**
- Only configuration
- Assumes infrastructure exists
- No infrastructure creation

---

### 2. Idempotent Workflows

**Both tools should be idempotent:**

**Run deployment twice:**

    ./deploy.sh  # First run: Creates everything
    ./deploy.sh  # Second run: No changes (idempotent)

**Terraform:** No infrastructure changes (already exists)
**Ansible:** No configuration changes (already correct)

---

### 3. State Management

**Terraform state:**
- Track infrastructure
- Commit .tf files to Git
- DO NOT commit terraform.tfstate

**Ansible:**
- Stateless (checks current state each run)
- Commit playbooks to Git
- Safe to run repeatedly

---

### 4. Error Handling

**In deployment scripts:**

    #!/bin/bash
    set -e  # Exit on error
    
    # Terraform
    if ! terraform apply -auto-approve; then
        echo "ERROR: Terraform failed"
        exit 1
    fi
    
    # Wait and test
    sleep 30
    if ! ansible all -m ping -i inventory.ini; then
        echo "ERROR: VMs not reachable"
        exit 1
    fi
    
    # Ansible
    if ! ansible-playbook playbook.yml -i inventory.ini; then
        echo "ERROR: Ansible failed"
        exit 1
    fi

---

### 5. Documentation

**Document the workflow:**

    # README.md
    
    ## Deployment
    
    Prerequisites:
    - Terraform installed
    - Ansible installed
    - Proxmox access configured
    
    Deploy:
    ```
    ./deploy.sh
    ```
    
    Destroy:
    ```
    cd terraform
    terraform destroy
    ```

---

### 6. Version Control

**What to commit:**

    ✓ Terraform .tf files
    ✓ Ansible playbooks
    ✓ Deployment scripts
    ✓ Documentation
    
    ✗ terraform.tfstate
    ✗ terraform.tfvars (if contains secrets)
    ✗ Generated inventory files
    ✗ .terraform/ directory

**.gitignore:**

    # Terraform
    *.tfstate
    *.tfstate.backup
    .terraform/
    terraform.tfvars
    
    # Ansible
    *.retry
    ansible/inventory.ini  # If generated
    
    # General
    *.log
    .DS_Store

---

## Common Patterns

### Pattern: Infrastructure Updates

**Update VM specs:**

**Change Terraform:**

    resource "proxmox_vm_qemu" "web" {
      cores  = 4  # Changed from 2
      memory = 8192  # Changed from 4096
    }

**Apply changes:**

    terraform apply

**Re-run Ansible (configuration unchanged):**

    ansible-playbook -i inventory.ini playbook.yml

---

### Pattern: Configuration Updates

**Change application config:**

**Update Ansible playbook:**

    - name: Update max connections
      lineinfile:
        path: /etc/mysql/mysql.conf.d/mysqld.cnf
        line: "max_connections = 500"

**Infrastructure unchanged, just run Ansible:**

    ansible-playbook -i inventory.ini database.yml

**No need to touch Terraform!**

---

### Pattern: Complete Rebuild

**Destroy and recreate everything:**

    # Destroy infrastructure
    cd terraform
    terraform destroy -auto-approve
    
    # Rebuild everything
    cd ..
    ./deploy.sh

**Result:** Fresh environment from scratch

---

### Pattern: Scaling

**Add more web servers:**

**Update Terraform:**

    variable "web_count" {
      default = 3  # Changed from 1
    }
    
    resource "proxmox_vm_qemu" "web" {
      count = var.web_count
      name  = "web-${count.index + 1}"
      # ... rest of config
    }

**Apply infrastructure:**

    terraform apply

**Regenerate inventory and configure all:**

    ./generate_inventory.sh
    ansible-playbook -i inventory.ini webserver.yml

**Ansible runs on all servers (including new ones)**

---

## Troubleshooting

### Issue 1: Ansible Can't Connect

**Symptom:**

    UNREACHABLE! => {"msg": "Failed to connect to the host via ssh"}

**Causes:**
1. VM not fully booted
2. SSH not started
3. Wrong IP address
4. Firewall blocking

**Solutions:**

    # Wait longer
    sleep 60
    
    # Test connectivity
    ansible all -m ping -i inventory.ini
    
    # Try manual SSH
    ssh ubuntu@10.30.10.30
    
    # Check Terraform outputs
    terraform output

---

### Issue 2: Terraform State Out of Sync

**Symptom:**

    Error: resource already exists

**Cause:** State file doesn't match reality

**Solutions:**

    # Import existing resource
    terraform import proxmox_vm_qemu.web 100
    
    # Or refresh state
    terraform refresh
    
    # Or recreate state
    terraform destroy
    terraform apply

---

### Issue 3: Changes Not Applied

**Symptom:** Ansible shows "ok" but nothing changed

**Cause:** Task not idempotent or already in desired state

**Solutions:**

    # Force handlers to run
    ansible-playbook --force-handlers playbook.yml
    
    # Check actual state on server
    ssh ubuntu@10.30.10.30
    systemctl status apache2
    
    # Use changed_when for custom logic
    - name: Custom task
      command: /some/script
      changed_when: true

---

### Issue 4: Secrets Management

**Problem:** How to handle passwords?

**Solutions:**

**Terraform:**

    # Use variables
    variable "proxmox_password" {
      sensitive = true
    }
    
    # Set via environment
    export TF_VAR_proxmox_password="password"

**Ansible:**

    # Use vault
    ansible-vault encrypt secrets.yml
    
    # Run with vault
    ansible-playbook --ask-vault-pass playbook.yml

---

## Quick Reference

**Complete workflow:**

    1. terraform init
    2. terraform plan
    3. terraform apply
    4. ./generate_inventory.sh
    5. ansible-playbook playbook.yml

**Update infrastructure:**

    terraform apply
    # Ansible not needed if only infrastructure changed

**Update configuration:**

    ansible-playbook playbook.yml
    # Terraform not needed if only configuration changed

**Rebuild everything:**

    terraform destroy
    ./deploy.sh

**Verify state:**

    terraform show
    ansible all -m setup

---

## Next Steps

Now that you understand how Terraform and Ansible work together:

1. **Practice:** Try the complete lab deployment example
2. **Build:** Create your own integrated workflows
3. **Explore:** Check out [workflow examples](../workflows/)
4. **Advanced:** Learn about CI/CD integration

---

## Additional Resources

**Integration Guides:**
- [Terraform Provisioners](https://www.terraform.io/docs/provisioners/index.html)
- [Ansible Dynamic Inventory](https://docs.ansible.com/ansible/latest/user_guide/intro_dynamic_inventory.html)

**Example Projects:**
- [Complete workflows](../workflows/)
- [Terraform examples](../terraform/examples/)
- [Ansible examples](../ansible/examples/)

---

Last Updated: February 2026
