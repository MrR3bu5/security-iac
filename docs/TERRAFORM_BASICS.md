# Terraform Basics

A comprehensive guide to understanding and using Terraform for infrastructure provisioning.

## Table of Contents

1. [What is Terraform?](#what-is-terraform)
2. [How Terraform Works](#how-terraform-works)
3. [Core Concepts](#core-concepts)
4. [Terraform Language (HCL)](#terraform-language-hcl)
5. [Terraform Workflow](#terraform-workflow)
6. [Providers](#providers)
7. [State Management](#state-management)
8. [Your First Terraform Project](#your-first-terraform-project)
9. [Proxmox Example](#proxmox-example)
10. [Best Practices](#best-practices)

---

## What is Terraform?

### Simple Definition

**Terraform:** An open-source tool that lets you define and provision infrastructure using code.

You write configuration files describing what infrastructure you want, and Terraform makes it happen.

### Created By

- **Company:** HashiCorp
- **Language:** Written in Go
- **Config Language:** HCL (HashiCorp Configuration Language)
- **License:** Open source (Mozilla Public License)

### What Terraform Does

**Creates:**
- Virtual machines
- Networks and subnets
- Storage volumes
- Load balancers
- DNS records
- Cloud resources (AWS, Azure, GCP)
- On-premises infrastructure (Proxmox, VMware)

**Manages:**
- Infrastructure lifecycle (create, update, destroy)
- Dependencies between resources
- State tracking
- Changes over time

**Does NOT:**
- Install software on systems (use Ansible for this)
- Configure operating systems (use Ansible for this)
- Replace configuration management tools

---

## How Terraform Works

### The Big Picture

    You Write Code → Terraform Reads It → Checks Current State → Makes Changes

### Step-by-Step Process

**1. You Write Configuration**

    resource "proxmox_vm_qemu" "web" {
      name   = "web-server"
      cores  = 2
      memory = 4096
    }

**2. Terraform Plans**
- Reads your configuration
- Checks current infrastructure state
- Calculates what needs to change

**3. You Review Plan**
- See exactly what will happen
- Approve or reject

**4. Terraform Applies**
- Makes the changes
- Creates, updates, or destroys resources
- Updates state file

**5. Infrastructure Exists**
- VMs are running
- Networks configured
- Everything matches your code

### Visual Flow

    ┌─────────────────────┐
    │  Write .tf Files    │
    │  (Your Code)        │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  terraform init     │
    │  (Initialize)       │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  terraform plan     │
    │  (Preview Changes)  │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  Review Output      │
    │  (Check Plan)       │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  terraform apply    │
    │  (Execute Plan)     │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  Infrastructure     │
    │  Created!           │
    └─────────────────────┘

---

## Core Concepts

### 1. Resources

**Resources are the things you want to create.**

**Syntax:**

    resource "TYPE" "NAME" {
      argument = value
    }

**Example:**

    resource "proxmox_vm_qemu" "my_vm" {
      name   = "test-server"
      cores  = 4
      memory = 8192
    }

**Breaking it down:**
- `resource`: Keyword (tells Terraform this is a resource)
- `"proxmox_vm_qemu"`: Resource type (what kind of thing)
- `"my_vm"`: Local name (what you call it in your code)
- `{}`: Arguments block (configuration details)

### 2. Providers

**Providers connect Terraform to platforms (Proxmox, AWS, Azure, etc.)**

**Example:**

    terraform {
      required_providers {
        proxmox = {
          source  = "telmate/proxmox"
          version = "~> 2.0"
        }
      }
    }
    
    provider "proxmox" {
      pm_api_url = "https://proxmox.local:8006/api2/json"
      pm_user    = "terraform@pam"
      pm_password = var.proxmox_password
    }

**What this does:**
- Tells Terraform to use the Proxmox provider
- Configures connection to Proxmox server
- Authenticates with credentials

### 3. Variables

**Variables make your code reusable and flexible.**

**Define variables:**

    variable "vm_count" {
      description = "Number of VMs to create"
      type        = number
      default     = 3
    }
    
    variable "vm_memory" {
      description = "RAM in MB"
      type        = number
      default     = 4096
    }

**Use variables:**

    resource "proxmox_vm_qemu" "web" {
      count  = var.vm_count
      name   = "web-${count.index}"
      memory = var.vm_memory
    }

**Benefits:**
- Change values without editing code
- Reuse same code with different values
- Environment-specific configurations

### 4. Outputs

**Outputs display information after Terraform runs.**

**Example:**

    output "vm_ip_address" {
      description = "IP address of the VM"
      value       = proxmox_vm_qemu.web.default_ipv4_address
    }

**After apply, you see:**

    Outputs:
    
    vm_ip_address = "10.30.10.50"

**Why useful:**
- Get IP addresses for new VMs
- Pass information to other tools (Ansible)
- Document important values

### 5. Data Sources

**Data sources query existing infrastructure.**

**Example:**

    data "proxmox_template" "ubuntu" {
      name = "ubuntu-22.04-template"
    }
    
    resource "proxmox_vm_qemu" "web" {
      clone = data.proxmox_template.ubuntu.name
    }

**What this does:**
- Queries Proxmox for existing template
- Uses that template to create new VM
- No hardcoded values

### 6. Modules

**Modules are reusable Terraform configurations.**

**Think of them as functions for infrastructure.**

**Example module structure:**

    modules/
    └── web-server/
        ├── main.tf       # Resources
        ├── variables.tf  # Inputs
        └── outputs.tf    # Outputs

**Using a module:**

    module "web_servers" {
      source = "./modules/web-server"
      
      vm_count = 3
      memory   = 8192
    }

**Benefits:**
- Reuse code across projects
- Standardize infrastructure patterns
- Easier to maintain

---

## Terraform Language (HCL)

### Basic Syntax

**HCL (HashiCorp Configuration Language) is easy to read and write.**

**Structure:**

    BLOCK_TYPE "BLOCK_LABEL" "BLOCK_NAME" {
      argument1 = value1
      argument2 = value2
      
      nested_block {
        nested_argument = nested_value
      }
    }

**Example:**

    resource "proxmox_vm_qemu" "web" {
      name   = "web-server"
      cores  = 4
      memory = 8192
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "32G"
        storage = "local-lvm"
      }
    }

### Data Types

**String:**

    name = "web-server"

**Number:**

    cores = 4

**Boolean:**

    onboot = true

**List:**

    tags = ["web", "production", "frontend"]

**Map:**

    labels = {
      environment = "production"
      team        = "platform"
    }

### Comments

**Single line:**

    # This is a comment
    name = "web-server"  # Inline comment

**Multi-line:**

    /*
    This is a
    multi-line comment
    */

### String Interpolation

**Reference variables:**

    name = "web-${var.environment}"
    # Result: "web-production"

**Reference resource attributes:**

    ip_address = proxmox_vm_qemu.web.default_ipv4_address

**Expressions:**

    memory = var.base_memory * 2
    # If base_memory = 4096, result = 8192

### Conditionals

**Ternary operator:**

    memory = var.environment == "production" ? 8192 : 4096
    # If production: 8192, else: 4096

**Count with condition:**

    count = var.create_backup ? 1 : 0
    # Creates resource only if create_backup is true

### Loops

**Count:**

    resource "proxmox_vm_qemu" "web" {
      count = 3
      name  = "web-${count.index}"
    }
    # Creates: web-0, web-1, web-2

**For each:**

    resource "proxmox_vm_qemu" "web" {
      for_each = toset(["dev", "staging", "prod"])
      name     = "web-${each.key}"
    }
    # Creates: web-dev, web-staging, web-prod

---

## Terraform Workflow

### Essential Commands

**1. terraform init**

**What it does:**
- Initializes working directory
- Downloads required providers
- Sets up backend for state

**When to run:**
- First time in a directory
- After adding new providers
- After changing backend configuration

**Example:**

    terraform init

**Output:**

    Initializing provider plugins...
    - Finding telmate/proxmox versions matching "~> 2.0"...
    - Installing telmate/proxmox v2.9.14...
    
    Terraform has been successfully initialized!

---

**2. terraform plan**

**What it does:**
- Compares desired state (your code) with current state
- Shows what will change
- Does NOT make any changes

**When to run:**
- Before applying changes
- To review what will happen
- To catch errors before execution

**Example:**

    terraform plan

**Output:**

    Terraform will perform the following actions:
    
      # proxmox_vm_qemu.web will be created
      + resource "proxmox_vm_qemu" "web" {
          + name   = "web-server"
          + cores  = 4
          + memory = 8192
        }
    
    Plan: 1 to add, 0 to change, 0 to destroy.

**Read the plan carefully!**
- `+` means create
- `-` means destroy
- `~` means update in place
- `-/+` means destroy and recreate

---

**3. terraform apply**

**What it does:**
- Executes the plan
- Creates/updates/destroys resources
- Updates state file

**When to run:**
- After reviewing plan
- When you want to make changes
- With caution (makes real changes!)

**Example:**

    terraform apply

**You'll be prompted:**

    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.
    
      Enter a value: yes

**To skip prompt (use carefully!):**

    terraform apply -auto-approve

---

**4. terraform destroy**

**What it does:**
- Destroys all resources managed by Terraform
- Removes infrastructure
- Updates state file

**When to run:**
- Tearing down test environments
- Removing old infrastructure
- Starting fresh

**Example:**

    terraform destroy

**Be careful!** This deletes real infrastructure.

---

**5. terraform validate**

**What it does:**
- Checks syntax and configuration
- Validates resource definitions
- Does not access remote state

**When to run:**
- After writing new configuration
- Before committing to Git
- Part of CI/CD pipeline

**Example:**

    terraform validate

**Output if valid:**

    Success! The configuration is valid.

**Output if invalid:**

    Error: Argument or block definition required
    
      on main.tf line 10:
      10: resource "proxmox_vm_qemu" "web"
    
    An argument or block definition is required here.

---

**6. terraform fmt**

**What it does:**
- Formats code to standard style
- Fixes indentation
- Makes code readable

**When to run:**
- Before committing code
- After editing files
- As part of development workflow

**Example:**

    terraform fmt

**Changes:**

    Before:
    resource "proxmox_vm_qemu" "web" {
    name="web-server"
    cores=4
    }
    
    After:
    resource "proxmox_vm_qemu" "web" {
      name  = "web-server"
      cores = 4
    }

---

**7. terraform show**

**What it does:**
- Shows current state
- Displays resource details
- Human-readable format

**Example:**

    terraform show

---

**8. terraform output**

**What it does:**
- Displays output values
- Useful for getting specific information
- Can be parsed by scripts

**Example:**

    terraform output vm_ip_address

**Output:**

    "10.30.10.50"

---

### Typical Workflow

**Day 1: Initial Deployment**

    1. Write configuration (main.tf)
    2. terraform init
    3. terraform validate
    4. terraform plan
    5. Review plan carefully
    6. terraform apply
    7. Verify infrastructure created

**Day 2: Make Changes**

    1. Edit configuration
    2. terraform plan (preview changes)
    3. Review what will change
    4. terraform apply
    5. Verify changes

**Day 30: Tear Down**

    1. terraform destroy
    2. Confirm destruction
    3. Infrastructure removed

---

## Providers

### What are Providers?

**Providers are plugins that let Terraform interact with APIs.**

Each provider knows how to:
- Authenticate to a platform
- Create resources
- Update resources
- Delete resources
- Query existing resources

### Common Providers

**Cloud:**
- AWS
- Azure
- Google Cloud

**Virtualization:**
- Proxmox (what we use!)
- VMware
- VirtualBox

**Services:**
- DNS (Cloudflare)
- Databases
- Monitoring tools

**Local:**
- Local files
- Random values
- Time delays

### Proxmox Provider

**For our homelab, we use the Proxmox provider.**

**Configuration:**

    terraform {
      required_providers {
        proxmox = {
          source  = "telmate/proxmox"
          version = "~> 2.0"
        }
      }
    }
    
    provider "proxmox" {
      pm_api_url      = "https://192.168.x.241:8006/api2/json"
      pm_user         = "terraform@pam"
      pm_password     = var.proxmox_password
      pm_tls_insecure = true  # Self-signed cert
    }

**What you need:**
- Proxmox API URL
- Username with API access
- Password (or API token)
- TLS setting (if using self-signed cert)

**Provider Documentation:**
[Telmate Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)

---

## State Management

### What is State?

**State is Terraform's record of infrastructure.**

Stored in `terraform.tfstate` file (JSON format).

**Contains:**
- Resources Terraform manages
- Resource attributes (IPs, IDs, etc.)
- Dependencies between resources
- Metadata

### Why State Matters

**Without state, Terraform wouldn't know:**
- What infrastructure already exists
- What needs to be created
- What needs to be updated
- What needs to be deleted

**State enables:**
- Idempotent operations (run multiple times safely)
- Change detection
- Dependency management
- Resource tracking

### State File Example

**Your code:**

    resource "proxmox_vm_qemu" "web" {
      name   = "web-server"
      cores  = 4
      memory = 8192
    }

**State file (simplified):**

    {
      "resources": [
        {
          "type": "proxmox_vm_qemu",
          "name": "web",
          "instances": [
            {
              "attributes": {
                "name": "web-server",
                "cores": 4,
                "memory": 8192,
                "vmid": 100,
                "default_ipv4_address": "10.30.10.50"
              }
            }
          ]
        }
      ]
    }

### Local vs Remote State

**Local State (Default):**
- State file stored locally
- File: `terraform.tfstate`
- Good for: Testing, learning, single-user

**Problems with local state:**
- Not shared across team
- No locking (concurrent changes)
- Risk of loss (no backup)

**Remote State (Production):**
- State stored remotely (S3, Terraform Cloud, etc.)
- Shared across team
- Locking prevents conflicts
- Automatic backups

**For homelab:** Local state is fine (you're the only user)

**For team/production:** Use remote state

### State Best Practices

**DO:**
- Commit `.tf` files to Git
- Back up state file regularly
- Use remote state for teams
- Review state occasionally

**DO NOT:**
- Manually edit state file
- Commit state to Git (contains sensitive data)
- Delete state file casually
- Run Terraform from multiple locations simultaneously

### Protecting State

**Add to .gitignore:**

    # Terraform
    *.tfstate
    *.tfstate.backup
    .terraform/
    terraform.tfvars

**Why:**
- State contains sensitive data
- IP addresses, passwords, keys
- Should not be in version control

---

## Your First Terraform Project

### Project: Create a Local File

**This simple example demonstrates Terraform basics without needing infrastructure.**

**Step 1: Create directory**

    mkdir terraform-test
    cd terraform-test

**Step 2: Create main.tf**

    # This is your first Terraform configuration!
    
    # Configure Terraform to use local provider
    terraform {
      required_providers {
        local = {
          source  = "hashicorp/local"
          version = "~> 2.0"
        }
      }
    }
    
    # Create a local file
    resource "local_file" "hello" {
      filename = "hello.txt"
      content  = "Hello from Terraform!"
    }
    
    # Output the file path
    output "file_path" {
      value = local_file.hello.filename
    }

**Step 3: Initialize**

    terraform init

**Output:**

    Initializing provider plugins...
    - Finding hashicorp/local versions matching "~> 2.0"...
    - Installing hashicorp/local v2.4.0...
    
    Terraform has been successfully initialized!

**Step 4: Plan**

    terraform plan

**Output:**

    Terraform will perform the following actions:
    
      # local_file.hello will be created
      + resource "local_file" "hello" {
          + content  = "Hello from Terraform!"
          + filename = "hello.txt"
          + id       = (known after apply)
        }
    
    Plan: 1 to add, 0 to change, 0 to destroy.

**Step 5: Apply**

    terraform apply

Type `yes` when prompted.

**Output:**

    local_file.hello: Creating...
    local_file.hello: Creation complete after 0s [id=...]
    
    Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
    
    Outputs:
    
    file_path = "hello.txt"

**Step 6: Verify**

    cat hello.txt

**Output:**

    Hello from Terraform!

**Step 7: Modify**

Edit `main.tf`, change content:

    content = "Hello from Terraform! Updated!"

**Step 8: Apply again**

    terraform apply

**Output:**

    Terraform will perform the following actions:
    
      # local_file.hello will be updated in-place
      ~ resource "local_file" "hello" {
            filename = "hello.txt"
          ~ content  = "Hello from Terraform!" -> "Hello from Terraform! Updated!"
            id       = "..."
        }
    
    Plan: 0 to add, 1 to change, 0 to destroy.

**Note the `~` symbol: update in place**

**Step 9: Destroy**

    terraform destroy

**Confirms:**

    Plan: 0 to add, 0 to change, 1 to destroy.
    
    Do you really want to destroy all resources?

Type `yes`.

**File is deleted!**

---

## Proxmox Example

### Prerequisites

**On Proxmox:**
1. Create user for Terraform
2. Assign appropriate permissions
3. Create VM template (optional but recommended)

**Create Terraform user:**

    pveum useradd terraform@pam
    pveum passwd terraform@pam
    pveum aclmod / -user terraform@pam -role Administrator

### Simple VM Creation

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
      pm_api_url      = "https://192.168.x.241:8006/api2/json"
      pm_user         = "terraform@pam"
      pm_password     = var.proxmox_password
      pm_tls_insecure = true
    }
    
    resource "proxmox_vm_qemu" "test_vm" {
      name        = "terraform-test"
      target_node = "proxmox-host01"
      
      clone = "ubuntu-22.04-template"
      
      cores   = 2
      memory  = 2048
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "20G"
        storage = "local-lvm"
        type    = "scsi"
      }
      
      os_type = "cloud-init"
      ipconfig0 = "ip=dhcp"
    }
    
    output "vm_ip" {
      value = proxmox_vm_qemu.test_vm.default_ipv4_address
    }

**File: variables.tf**

    variable "proxmox_password" {
      description = "Proxmox password"
      type        = string
      sensitive   = true
    }

**File: terraform.tfvars** (DO NOT commit to Git!)

    proxmox_password = "your-password-here"

**Deploy:**

    terraform init
    terraform plan
    terraform apply

**Result:** New VM created on Proxmox!

**Get IP address:**

    terraform output vm_ip

**Destroy when done:**

    terraform destroy

---

## Best Practices

### Code Organization

**Small projects:**

    project/
    ├── main.tf          # Resources
    ├── variables.tf     # Variable definitions
    ├── outputs.tf       # Outputs
    └── terraform.tfvars # Variable values (don't commit!)

**Larger projects:**

    project/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── network.tf       # Network resources
    ├── compute.tf       # VMs
    ├── storage.tf       # Storage
    └── modules/
        ├── web-server/
        └── database/

### Naming Conventions

**Resources:**
- Use descriptive names
- Lowercase with underscores
- Environment prefix if needed

**Good:**

    resource "proxmox_vm_qemu" "web_server_prod" { }
    resource "proxmox_vm_qemu" "db_primary" { }

**Avoid:**

    resource "proxmox_vm_qemu" "vm1" { }
    resource "proxmox_vm_qemu" "WebServer" { }

### Variables

**Always define:**
- Description
- Type
- Default (if applicable)

**Example:**

    variable "vm_count" {
      description = "Number of web servers to create"
      type        = number
      default     = 3
      
      validation {
        condition     = var.vm_count >= 1 && var.vm_count <= 10
        error_message = "VM count must be between 1 and 10."
      }
    }

### Comments

**Explain why, not what:**

**Good:**

    # Using larger disk because application generates significant logs
    disk {
      size = "100G"
    }

**Less useful:**

    # Disk size is 100G
    disk {
      size = "100G"
    }

### Security

**Never commit secrets:**
- Use variables for sensitive data
- Store values in `terraform.tfvars` (gitignored)
- Or use environment variables
- Consider using Vault for production

**Example:**

    # Bad: Hardcoded password
    pm_password = "mypassword123"
    
    # Good: Use variable
    pm_password = var.proxmox_password

### Version Control

**Commit to Git:**
- `*.tf` files
- `*.tfvars.example` (template)
- `.gitignore`
- Documentation

**DO NOT commit:**
- `*.tfstate` (state file)
- `*.tfstate.backup`
- `.terraform/` (provider plugins)
- `terraform.tfvars` (actual secrets)
- `*.tfvars` (if contains secrets)

**.gitignore example:**

    # Terraform
    *.tfstate
    *.tfstate.backup
    .terraform/
    terraform.tfvars
    *.tfvars
    
    # Keep example files
    !*.tfvars.example

---

## Common Pitfalls

### 1. Forgetting to Run Init

**Error:**

    Error: Could not load plugin
    
    Plugin reinitialization required. Please run "terraform init".

**Solution:** Run `terraform init` first.

---

### 2. State File Conflicts

**Problem:** Multiple people running Terraform simultaneously

**Solution:** Use remote state with locking (for teams)

---

### 3. Hardcoded Values

**Problem:**

    name = "web-production"

**Can't reuse for different environments**

**Solution:**

    name = "web-${var.environment}"

---

### 4. No Plan Review

**Problem:** Running `apply` without checking plan

**Solution:** Always run `plan` first, review carefully

---

### 5. Committing Secrets

**Problem:** Credentials in Git history

**Solution:**
- Use `.gitignore`
- Use variables
- Never commit actual credentials

---

## Next Steps

Now that you understand Terraform basics:

1. **Practice:** Try the examples in this guide
2. **Learn Ansible:** Read [Ansible Basics](ANSIBLE_BASICS.md)
3. **Integration:** See [Terraform and Ansible Together](TERRAFORM_AND_ANSIBLE.md)
4. **Real Projects:** Check [examples](../terraform/examples/)

---

## Quick Reference

**Essential Commands:**

    terraform init       # Initialize directory
    terraform plan       # Preview changes
    terraform apply      # Execute changes
    terraform destroy    # Remove infrastructure
    terraform validate   # Check syntax
    terraform fmt        # Format code
    terraform output     # Show outputs

**Project Structure:**

    project/
    ├── main.tf          # Main configuration
    ├── variables.tf     # Variable definitions
    ├── outputs.tf       # Output values
    └── terraform.tfvars # Variable values (gitignore!)

**Basic Resource:**

    resource "TYPE" "NAME" {
      argument = value
    }

---

## Additional Resources

**Official Documentation:**
- [Terraform Docs](https://www.terraform.io/docs)
- [Terraform Registry](https://registry.terraform.io/) (providers, modules)
- [HCL Syntax](https://www.terraform.io/language/syntax/configuration)

**Learning:**
- [HashiCorp Learn](https://learn.hashicorp.com/terraform)
- [Terraform: Up & Running](https://www.terraformupandrunning.com/) (book)

**Proxmox Provider:**
- [Telmate Provider Docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)

---

Last Updated: February 2026
