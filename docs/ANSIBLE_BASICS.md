# Ansible Basics

A comprehensive guide to understanding and using Ansible for configuration management and automation.

## Table of Contents

1. [What is Ansible?](#what-is-ansible)
2. [How Ansible Works](#how-ansible-works)
3. [Core Concepts](#core-concepts)
4. [Ansible Architecture](#ansible-architecture)
5. [Playbooks and YAML](#playbooks-and-yaml)
6. [Inventory](#inventory)
7. [Modules](#modules)
8. [Ansible Workflow](#ansible-workflow)
9. [Your First Ansible Playbook](#your-first-ansible-playbook)
10. [Real-World Examples](#real-world-examples)
11. [Best Practices](#best-practices)

---

## What is Ansible?

### Simple Definition

**Ansible:** An open-source tool that automates configuration management, application deployment, and task execution on remote systems.

You write instructions (playbooks) describing what you want done, and Ansible executes them on your servers.

### Created By

- **Company:** Red Hat (acquired, originally independent)
- **Language:** Written in Python
- **Config Language:** YAML
- **License:** Open source (GPL)

### What Ansible Does

**Configures:**
- Operating systems
- Software installation
- Service configuration
- User management
- File management

**Deploys:**
- Applications
- Configuration files
- Updates and patches
- Security hardening

**Orchestrates:**
- Multi-step processes
- Complex workflows
- Coordinated actions across servers

**Does NOT:**
- Create infrastructure (use Terraform for this)
- Manage infrastructure state like Terraform
- Run continuously (it's task-based, not agent-based)

### Key Features

**Agentless:**
- No software to install on managed systems
- Uses SSH (Linux) or WinRM (Windows)
- Simple and secure

**Idempotent:**
- Safe to run multiple times
- Only makes necessary changes
- Predictable results

**Human-Readable:**
- YAML syntax (easy to read and write)
- Self-documenting
- Low learning curve

---

## How Ansible Works

### The Big Picture

    You Write Playbook → Ansible Connects via SSH → Executes Tasks → Reports Results

### Step-by-Step Process

**1. You Write Playbook (YAML)**

    - name: Install web server
      hosts: webservers
      tasks:
        - name: Install Apache
          apt:
            name: apache2
            state: present

**2. Ansible Connects**
- Uses SSH to connect to target systems
- No agent required
- Authenticates with SSH keys or passwords

**3. Ansible Executes**
- Runs tasks one by one
- Checks current state before making changes
- Only changes what's necessary (idempotent)

**4. Reports Results**
- Shows what changed
- What stayed the same
- Any errors

### Visual Flow

    ┌─────────────────────┐
    │  Write Playbook     │
    │  (YAML file)        │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  Define Inventory   │
    │  (List of servers)  │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  Run ansible-       │
    │  playbook command   │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  Ansible connects   │
    │  via SSH            │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  Execute tasks on   │
    │  remote systems     │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  Report results     │
    │  (changed/ok/failed)│
    └─────────────────────┘

---

## Core Concepts

### 1. Inventory

**Inventory is a list of servers Ansible manages.**

**Simple inventory (INI format):**

    [webservers]
    web01 ansible_host=10.30.10.30
    web02 ansible_host=10.30.10.31
    
    [databases]
    db01 ansible_host=10.30.10.40

**YAML inventory:**

    all:
      children:
        webservers:
          hosts:
            web01:
              ansible_host: 10.30.10.30
            web02:
              ansible_host: 10.30.10.31
        databases:
          hosts:
            db01:
              ansible_host: 10.30.10.40

**What this defines:**
- Groups of servers (webservers, databases)
- Individual hosts (web01, web02, db01)
- Connection information (IP addresses)

### 2. Playbooks

**Playbooks are YAML files describing desired state.**

**Basic structure:**

    ---
    - name: Configure web servers
      hosts: webservers
      become: yes
      
      tasks:
        - name: Install Apache
          apt:
            name: apache2
            state: present
        
        - name: Start Apache
          service:
            name: apache2
            state: started
            enabled: yes

**Breaking it down:**
- `name`: Description of playbook
- `hosts`: Which servers to run on
- `become`: Run as root (sudo)
- `tasks`: List of actions to perform

### 3. Tasks

**Tasks are individual actions.**

**Task structure:**

    - name: Task description
      MODULE:
        argument1: value1
        argument2: value2

**Example:**

    - name: Install nginx
      apt:
        name: nginx
        state: present
        update_cache: yes

**Parts:**
- `name`: Human-readable description (optional but recommended)
- `apt`: Module being used
- `name`, `state`, `update_cache`: Module arguments

### 4. Modules

**Modules are pre-built functions Ansible provides.**

**Common modules:**

| Module | Purpose | Example |
|--------|---------|---------|
| `apt` | Package management (Debian/Ubuntu) | Install packages |
| `yum` | Package management (RedHat/CentOS) | Install packages |
| `service` | Service management | Start/stop services |
| `copy` | Copy files | Deploy config files |
| `template` | Template files | Config with variables |
| `user` | User management | Create users |
| `file` | File/directory management | Create directories |
| `command` | Run commands | Execute scripts |

**Over 3,000 modules available!**

### 5. Variables

**Variables make playbooks flexible and reusable.**

**Define variables:**

    vars:
      http_port: 80
      max_clients: 200

**Use variables:**

    - name: Configure Apache
      template:
        src: apache.conf.j2
        dest: /etc/apache2/apache2.conf
      vars:
        port: "{{ http_port }}"

**Variable syntax:** `{{ variable_name }}`

### 6. Handlers

**Handlers are tasks triggered by changes.**

**Example:**

    tasks:
      - name: Copy Apache config
        copy:
          src: apache2.conf
          dest: /etc/apache2/apache2.conf
        notify: Restart Apache
    
    handlers:
      - name: Restart Apache
        service:
          name: apache2
          state: restarted

**How it works:**
- If config file changes, handler is notified
- Handler runs at end of playbook
- Only runs if triggered (efficiency)

### 7. Roles

**Roles organize playbooks into reusable components.**

**Role structure:**

    roles/
    └── webserver/
        ├── tasks/
        │   └── main.yml
        ├── handlers/
        │   └── main.yml
        ├── templates/
        │   └── apache.conf.j2
        ├── files/
        │   └── index.html
        ├── vars/
        │   └── main.yml
        └── defaults/
            └── main.yml

**Using a role:**

    - name: Configure web servers
      hosts: webservers
      roles:
        - webserver

**Benefits:**
- Organized and modular
- Reusable across projects
- Easier to maintain

---

## Ansible Architecture

### Control Node (Your Computer)

**Where Ansible runs from:**
- Your laptop or desktop
- A dedicated management server
- CI/CD server

**Requirements:**
- Python installed
- Ansible installed
- SSH client

**Does NOT require:**
- Special privileges
- Complex setup

### Managed Nodes (Target Servers)

**Servers Ansible configures:**
- Linux servers
- Windows servers
- Network devices

**Requirements:**
- SSH access (Linux)
- WinRM access (Windows)
- Python installed (Linux)

**Does NOT require:**
- Ansible agent
- Special software

### Communication

**Linux/Unix:**

    Control Node → SSH → Managed Node
    
    1. Ansible generates Python script
    2. Copies script to managed node
    3. Executes script via SSH
    4. Returns results
    5. Deletes script

**Windows:**

    Control Node → WinRM → Managed Node
    
    Uses PowerShell remoting

**No permanent connection:**
- Connects only when running playbook
- No background processes
- Clean and simple

---

## Playbooks and YAML

### YAML Basics

**YAML:** Yet Another Markup Language (or YAML Ain't Markup Language)

**Key features:**
- Human-readable
- Whitespace sensitive (indentation matters!)
- Uses key-value pairs
- Supports lists and dictionaries

### YAML Syntax

**Key-value pairs:**

    name: web-server
    port: 80
    enabled: true

**Lists:**

    packages:
      - apache2
      - mysql-server
      - php

**Nested structures:**

    webserver:
      name: apache2
      port: 80
      modules:
        - mod_ssl
        - mod_rewrite

**Important:** Use spaces for indentation, NOT tabs!

### Playbook Structure

**Complete playbook example:**

    ---
    # This is a comment
    - name: Configure web servers
      hosts: webservers
      become: yes
      
      vars:
        http_port: 80
        doc_root: /var/www/html
      
      tasks:
        - name: Install Apache
          apt:
            name: apache2
            state: present
            update_cache: yes
        
        - name: Copy website files
          copy:
            src: files/index.html
            dest: "{{ doc_root }}/index.html"
            owner: www-data
            group: www-data
            mode: '0644'
        
        - name: Start Apache
          service:
            name: apache2
            state: started
            enabled: yes

**Structure breakdown:**

    ---                     # YAML document start (optional)
    - name: ...            # Play name
      hosts: ...           # Target hosts
      become: yes          # Run as root
      
      vars:                # Variables section
        key: value
      
      tasks:               # Tasks list
        - name: ...        # Task name
          module:          # Module to use
            arg: value     # Module arguments

### Multiple Plays

**A playbook can have multiple plays:**

    ---
    - name: Configure web servers
      hosts: webservers
      tasks:
        - name: Install Apache
          apt:
            name: apache2
            state: present
    
    - name: Configure database servers
      hosts: databases
      tasks:
        - name: Install MySQL
          apt:
            name: mysql-server
            state: present

**Each play targets different hosts.**

---

## Inventory

### Static Inventory

**INI format (simple):**

    [webservers]
    web01 ansible_host=10.30.10.30 ansible_user=ubuntu
    web02 ansible_host=10.30.10.31 ansible_user=ubuntu
    
    [databases]
    db01 ansible_host=10.30.10.40 ansible_user=ubuntu
    
    [lab:children]
    webservers
    databases
    
    [lab:vars]
    ansible_ssh_private_key_file=~/.ssh/id_rsa

**YAML format (structured):**

    all:
      children:
        webservers:
          hosts:
            web01:
              ansible_host: 10.30.10.30
            web02:
              ansible_host: 10.30.10.31
        databases:
          hosts:
            db01:
              ansible_host: 10.30.10.40
      vars:
        ansible_user: ubuntu
        ansible_ssh_private_key_file: ~/.ssh/id_rsa

### Inventory Variables

**Host variables:**

    web01 ansible_host=10.30.10.30 http_port=80

**Group variables:**

    [webservers:vars]
    http_port=80
    max_clients=200

**Variable precedence (highest to lowest):**
1. Extra vars (command line)
2. Task vars
3. Play vars
4. Host vars
5. Group vars
6. Role defaults

### Dynamic Inventory

**Query infrastructure dynamically:**
- Proxmox API
- Cloud providers (AWS, Azure)
- CMDB systems

**Example:** Proxmox dynamic inventory queries VMs automatically

---

## Modules

### Common Modules

**Package Management:**

    # Debian/Ubuntu
    - name: Install package
      apt:
        name: nginx
        state: present
    
    # RedHat/CentOS
    - name: Install package
      yum:
        name: nginx
        state: present

**Service Management:**

    - name: Start service
      service:
        name: nginx
        state: started
        enabled: yes

**File Operations:**

    - name: Create directory
      file:
        path: /opt/myapp
        state: directory
        mode: '0755'
    
    - name: Copy file
      copy:
        src: app.conf
        dest: /etc/app/app.conf
        owner: root
        group: root
        mode: '0644'

**Templates:**

    - name: Deploy config from template
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
        owner: root
        group: root
        mode: '0644'
      notify: Restart nginx

**User Management:**

    - name: Create user
      user:
        name: appuser
        state: present
        groups: sudo
        shell: /bin/bash

**Command Execution:**

    - name: Run script
      command: /opt/scripts/setup.sh
      args:
        creates: /opt/app/setup_complete

**Git Operations:**

    - name: Clone repository
      git:
        repo: https://github.com/user/repo.git
        dest: /opt/app
        version: main

### Module Return Values

**Modules return information:**

    - name: Get system info
      setup:
      register: system_info
    
    - name: Display hostname
      debug:
        msg: "Hostname is {{ system_info.ansible_facts.hostname }}"

**Common return values:**
- `changed`: Whether task made changes
- `failed`: Whether task failed
- `msg`: Status message
- Module-specific data

---

## Ansible Workflow

### Essential Commands

**1. ansible**

**Run ad-hoc commands (one-off tasks):**

    ansible webservers -m ping
    ansible all -m setup
    ansible databases -a "uptime"

**Syntax:**

    ansible [pattern] -m [module] -a "[arguments]"

**Examples:**

    # Ping all hosts
    ansible all -m ping
    
    # Check disk space
    ansible webservers -a "df -h"
    
    # Install package
    ansible databases -m apt -a "name=mysql-server state=present" --become

---

**2. ansible-playbook**

**Run playbooks:**

    ansible-playbook playbook.yml

**Common options:**

    # Specify inventory
    ansible-playbook -i inventory.ini playbook.yml
    
    # Check mode (dry run)
    ansible-playbook --check playbook.yml
    
    # Verbose output
    ansible-playbook -v playbook.yml
    ansible-playbook -vvv playbook.yml  # Very verbose
    
    # Limit to specific hosts
    ansible-playbook --limit web01 playbook.yml
    
    # Tags (run specific tasks)
    ansible-playbook --tags "config" playbook.yml

---

**3. ansible-inventory**

**Display inventory information:**

    # List all hosts
    ansible-inventory --list
    
    # Show specific group
    ansible-inventory --graph webservers

---

**4. ansible-vault**

**Encrypt sensitive data:**

    # Encrypt file
    ansible-vault encrypt secrets.yml
    
    # Edit encrypted file
    ansible-vault edit secrets.yml
    
    # Decrypt file
    ansible-vault decrypt secrets.yml
    
    # Run playbook with vault
    ansible-playbook --ask-vault-pass playbook.yml

---

**5. ansible-galaxy**

**Download and manage roles:**

    # Install role
    ansible-galaxy install geerlingguy.docker
    
    # Create role structure
    ansible-galaxy init myrole
    
    # List installed roles
    ansible-galaxy list

---

### Typical Workflow

**Day 1: Initial Setup**

    1. Create inventory file
    2. Test connectivity (ansible all -m ping)
    3. Write playbook
    4. Test with --check (dry run)
    5. Run playbook
    6. Verify results

**Day 2: Updates**

    1. Edit playbook
    2. Test with --check
    3. Run on test hosts first
    4. Run on production

**Ongoing:**

    1. Maintain playbooks in Git
    2. Run regularly for configuration drift
    3. Update as needed

---

## Your First Ansible Playbook

### Prerequisites

**Install Ansible:**

    # macOS
    brew install ansible
    
    # Ubuntu/Debian
    sudo apt update
    sudo apt install ansible
    
    # Python pip
    pip install ansible

**Verify installation:**

    ansible --version

### Project Setup

**Step 1: Create directory**

    mkdir ansible-test
    cd ansible-test

**Step 2: Create inventory**

**File: inventory.ini**

    [local]
    localhost ansible_connection=local

**Step 3: Test connection**

    ansible -i inventory.ini all -m ping

**Output:**

    localhost | SUCCESS => {
        "changed": false,
        "ping": "pong"
    }

**Success! Ansible works.**

### Simple Playbook

**File: hello.yml**

    ---
    - name: My first playbook
      hosts: local
      
      tasks:
        - name: Print hello message
          debug:
            msg: "Hello from Ansible!"
        
        - name: Display system info
          debug:
            msg: "Running on {{ ansible_hostname }}"
        
        - name: Create a file
          file:
            path: /tmp/ansible-test.txt
            state: touch
            mode: '0644'
        
        - name: Write content to file
          lineinfile:
            path: /tmp/ansible-test.txt
            line: "Created by Ansible on {{ ansible_date_time.date }}"
            create: yes

**Run playbook:**

    ansible-playbook -i inventory.ini hello.yml

**Output:**

    PLAY [My first playbook] *******************************************
    
    TASK [Gathering Facts] *********************************************
    ok: [localhost]
    
    TASK [Print hello message] *****************************************
    ok: [localhost] => {
        "msg": "Hello from Ansible!"
    }
    
    TASK [Display system info] *****************************************
    ok: [localhost] => {
        "msg": "Running on your-hostname"
    }
    
    TASK [Create a file] ***********************************************
    changed: [localhost]
    
    TASK [Write content to file] ***************************************
    changed: [localhost]
    
    PLAY RECAP *********************************************************
    localhost : ok=5    changed=2    unreachable=0    failed=0

**Verify:**

    cat /tmp/ansible-test.txt

**Output:**

    Created by Ansible on 2026-02-24

**Run again:**

    ansible-playbook -i inventory.ini hello.yml

**Notice:** Tasks that created files show `ok` instead of `changed` (idempotent!)

---

## Real-World Examples

### Example 1: Web Server Setup

**File: webserver.yml**

    ---
    - name: Configure web server
      hosts: webservers
      become: yes
      
      vars:
        document_root: /var/www/html
        http_port: 80
      
      tasks:
        - name: Update apt cache
          apt:
            update_cache: yes
            cache_valid_time: 3600
        
        - name: Install Apache
          apt:
            name: apache2
            state: present
        
        - name: Install PHP
          apt:
            name:
              - php
              - libapache2-mod-php
              - php-mysql
            state: present
        
        - name: Create document root
          file:
            path: "{{ document_root }}"
            state: directory
            owner: www-data
            group: www-data
            mode: '0755'
        
        - name: Copy index page
          copy:
            content: "<h1>Welcome!</h1><p>Server: {{ ansible_hostname }}</p>"
            dest: "{{ document_root }}/index.html"
            owner: www-data
            group: www-data
            mode: '0644'
        
        - name: Start and enable Apache
          service:
            name: apache2
            state: started
            enabled: yes
        
        - name: Configure firewall
          ufw:
            rule: allow
            port: "{{ http_port }}"
            proto: tcp

**Run:**

    ansible-playbook -i inventory.ini webserver.yml

---

### Example 2: User Management

**File: users.yml**

    ---
    - name: Manage users
      hosts: all
      become: yes
      
      vars:
        admin_users:
          - alice
          - bob
        
        developer_users:
          - charlie
          - diana
      
      tasks:
        - name: Create admin group
          group:
            name: admins
            state: present
        
        - name: Create admin users
          user:
            name: "{{ item }}"
            groups: admins,sudo
            shell: /bin/bash
            create_home: yes
          loop: "{{ admin_users }}"
        
        - name: Create developer users
          user:
            name: "{{ item }}"
            groups: developers
            shell: /bin/bash
            create_home: yes
          loop: "{{ developer_users }}"
        
        - name: Deploy SSH keys for admins
          authorized_key:
            user: "{{ item }}"
            key: "{{ lookup('file', 'keys/' + item + '.pub') }}"
          loop: "{{ admin_users }}"

---

### Example 3: System Hardening

**File: hardening.yml**

    ---
    - name: Basic system hardening
      hosts: all
      become: yes
      
      tasks:
        - name: Disable root login via SSH
          lineinfile:
            path: /etc/ssh/sshd_config
            regexp: '^PermitRootLogin'
            line: 'PermitRootLogin no'
          notify: Restart SSH
        
        - name: Disable password authentication
          lineinfile:
            path: /etc/ssh/sshd_config
            regexp: '^PasswordAuthentication'
            line: 'PasswordAuthentication no'
          notify: Restart SSH
        
        - name: Install fail2ban
          apt:
            name: fail2ban
            state: present
        
        - name: Start fail2ban
          service:
            name: fail2ban
            state: started
            enabled: yes
        
        - name: Enable firewall
          ufw:
            state: enabled
            policy: deny
        
        - name: Allow SSH
          ufw:
            rule: allow
            port: '22'
            proto: tcp
        
        - name: Set automatic security updates
          apt:
            name: unattended-upgrades
            state: present
      
      handlers:
        - name: Restart SSH
          service:
            name: sshd
            state: restarted

---

### Example 4: Docker Installation

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
              - software-properties-common
            state: present
        
        - name: Add Docker GPG key
          apt_key:
            url: https://download.docker.com/linux/ubuntu/gpg
            state: present
        
        - name: Add Docker repository
          apt_repository:
            repo: deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable
            state: present
        
        - name: Install Docker
          apt:
            name:
              - docker-ce
              - docker-ce-cli
              - containerd.io
            state: present
            update_cache: yes
        
        - name: Add user to docker group
          user:
            name: "{{ ansible_user }}"
            groups: docker
            append: yes
        
        - name: Start Docker service
          service:
            name: docker
            state: started
            enabled: yes
        
        - name: Install Docker Compose
          get_url:
            url: https://github.com/docker/compose/releases/download/v2.15.1/docker-compose-linux-x86_64
            dest: /usr/local/bin/docker-compose
            mode: '0755'

---

## Best Practices

### Playbook Organization

**Small projects:**

    project/
    ├── inventory.ini
    ├── playbook.yml
    └── files/

**Medium projects:**

    project/
    ├── inventories/
    │   ├── production
    │   └── staging
    ├── group_vars/
    │   ├── all.yml
    │   └── webservers.yml
    ├── host_vars/
    │   └── web01.yml
    ├── playbooks/
    │   ├── webserver.yml
    │   └── database.yml
    └── files/

**Large projects (with roles):**

    project/
    ├── inventories/
    ├── group_vars/
    ├── host_vars/
    ├── roles/
    │   ├── common/
    │   ├── webserver/
    │   └── database/
    ├── playbooks/
    └── ansible.cfg

### Naming Conventions

**Playbooks:**
- Descriptive names
- Use hyphens or underscores
- `.yml` extension

**Good:**

    configure-webserver.yml
    deploy_application.yml
    system_hardening.yml

**Variables:**
- Lowercase with underscores
- Descriptive names

**Good:**

    http_port: 80
    max_connections: 200
    document_root: /var/www/html

### Task Naming

**Always name your tasks:**

**Good:**

    - name: Install Apache web server
      apt:
        name: apache2
        state: present

**Bad:**

    - apt:
        name: apache2
        state: present

**Benefits:**
- Readable output
- Easy to understand what playbook does
- Self-documenting

### Idempotency

**Write idempotent playbooks:**

**Good (idempotent):**

    - name: Ensure Apache is installed
      apt:
        name: apache2
        state: present

**Bad (not idempotent):**

    - name: Install Apache
      command: apt-get install apache2

**Why:**
- First example: Checks if installed, installs only if needed
- Second example: Always tries to install, fails if already installed

### Variables

**Use variables for:**
- Configuration values
- Ports, paths, versions
- Anything that might change

**Define clearly:**

    vars:
      # HTTP server configuration
      http_port: 80
      https_port: 443
      document_root: /var/www/html
      
      # Application settings
      app_version: "2.1.0"
      max_connections: 200

### Handlers

**Use handlers for service restarts:**

**Good:**

    tasks:
      - name: Copy nginx config
        copy:
          src: nginx.conf
          dest: /etc/nginx/nginx.conf
        notify: Restart nginx
    
    handlers:
      - name: Restart nginx
        service:
          name: nginx
          state: restarted

**Why:**
- Restart only if config changed
- Restart once at end (even if multiple changes)
- Efficient

### Security

**Never hardcode secrets:**

**Bad:**

    mysql_root_password: "supersecret123"

**Good:**

    mysql_root_password: "{{ vault_mysql_root_password }}"

**Use ansible-vault:**

    # Encrypt secrets
    ansible-vault encrypt group_vars/all/vault.yml
    
    # Run with vault password
    ansible-playbook --ask-vault-pass playbook.yml

### Testing

**Test before production:**

**1. Syntax check:**

    ansible-playbook --syntax-check playbook.yml

**2. Dry run:**

    ansible-playbook --check playbook.yml

**3. Test on subset:**

    ansible-playbook --limit test-server playbook.yml

**4. Then production:**

    ansible-playbook playbook.yml

### Documentation

**Document playbooks:**

    ---
    # Playbook: webserver.yml
    # Purpose: Configure Apache web servers
    # Author: Your Name
    # Date: 2026-02-24
    #
    # Requirements:
    #   - Ubuntu 22.04 or later
    #   - SSH access with sudo privileges
    #   - Python 3 installed
    #
    # Usage:
    #   ansible-playbook -i inventory.ini webserver.yml
    
    - name: Configure web server
      hosts: webservers
      become: yes

---

## Common Pitfalls

### 1. Indentation Errors

**YAML is sensitive to indentation!**

**Wrong:**

    tasks:
    - name: Install Apache
    apt:
      name: apache2

**Right:**

    tasks:
      - name: Install Apache
        apt:
          name: apache2

**Tip:** Use 2 spaces for indentation, be consistent

---

### 2. Using Command Module When Better Modules Exist

**Bad:**

    - name: Install package
      command: apt-get install nginx

**Good:**

    - name: Install package
      apt:
        name: nginx
        state: present

**Why:** Specific modules are idempotent, handle errors better

---

### 3. Not Using become When Needed

**Error:**

    FAILED! => {"msg": "Permission denied"}

**Solution:**

    - name: Install package
      apt:
        name: nginx
      become: yes  # Run as root

---

### 4. Hardcoding Values

**Bad:**

    document_root: /var/www/html

**Good:**

    document_root: "{{ web_root }}"

**Benefit:** Reusable across environments

---

### 5. Not Testing Changes

**Always test:**
1. Syntax check
2. Dry run (--check)
3. Test environment
4. Production

---

## Next Steps

Now that you understand Ansible basics:

1. **Practice:** Try the examples in this guide
2. **Integration:** Read [Terraform and Ansible Together](TERRAFORM_AND_ANSIBLE.md)
3. **Real Projects:** Check [examples](../ansible/examples/)
4. **Advanced:** Learn about roles, vault, and complex playbooks

---

## Quick Reference

**Essential Commands:**

    ansible all -m ping                    # Test connectivity
    ansible-playbook playbook.yml          # Run playbook
    ansible-playbook --check playbook.yml  # Dry run
    ansible-playbook -v playbook.yml       # Verbose
    ansible-vault encrypt file.yml         # Encrypt secrets

**Playbook Structure:**

    ---
    - name: Playbook name
      hosts: target_hosts
      become: yes
      
      vars:
        variable: value
      
      tasks:
        - name: Task name
          module:
            argument: value

**Common Modules:**

    apt:           # Package management (Debian/Ubuntu)
    yum:           # Package management (RedHat/CentOS)
    service:       # Service management
    copy:          # Copy files
    template:      # Deploy templates
    file:          # File/directory management
    user:          # User management
    command:       # Run commands

---

## Additional Resources

**Official Documentation:**
- [Ansible Docs](https://docs.ansible.com/)
- [Module Index](https://docs.ansible.com/ansible/latest/collections/index_module.html)
- [Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)

**Learning:**
- [Ansible Getting Started](https://docs.ansible.com/ansible/latest/getting_started/index.html)
- [Ansible for DevOps](https://www.ansiblefordevops.com/) (book)

**Community:**
- [Ansible Galaxy](https://galaxy.ansible.com/) (pre-built roles)
- r/ansible

---

Last Updated: February 2026
