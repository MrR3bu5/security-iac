# Getting Started with Infrastructure as Code

A beginner-friendly introduction to Infrastructure as Code (IaC) concepts, terminology, and workflows.

## Table of Contents

1. [What is Infrastructure as Code?](#what-is-infrastructure-as-code)
2. [Why Use IaC?](#why-use-iac)
3. [Key Concepts](#key-concepts)
4. [Declarative vs Imperative](#declarative-vs-imperative)
5. [IaC Workflow](#iac-workflow)
6. [Common Tools](#common-tools)
7. [Terraform and Ansible Roles](#terraform-and-ansible-roles)
8. [Your First IaC Journey](#your-first-iac-journey)

---

## What is Infrastructure as Code?

### The Traditional Way (Manual)

Imagine you need to deploy a new server:

    1. Log into Proxmox web interface
    2. Click "Create VM"
    3. Fill out form: name, CPU, RAM, disk
    4. Click "Create"
    5. Wait for VM to be created
    6. SSH into the VM
    7. Run commands to install software
    8. Edit configuration files manually
    9. Restart services
    10. Test everything works

**Problems with this approach:**
- Takes time (15-30 minutes per VM)
- Easy to make mistakes (typos, missed steps)
- Hard to repeat exactly
- No record of what you did
- Doesn't scale (what if you need 10 VMs?)

### The IaC Way (Automated)

With Infrastructure as Code:

    1. Write code describing what you want
    2. Run one command
    3. Infrastructure is created automatically
    4. Exactly the same every time

**Benefits:**
- Fast (seconds to minutes, no human interaction)
- Consistent (no human error)
- Repeatable (run it 100 times, get same result)
- Version controlled (track changes in Git)
- Documented (code IS documentation)

### Simple Definition

**Infrastructure as Code (IaC):** Managing and provisioning infrastructure through machine-readable files rather than manual processes.

You write code that describes your infrastructure, and tools execute that code to make it reality.

---

## Why Use IaC?

### Real-World Example: Lab Deployment

**Without IaC (Manual):**

    Time to deploy AD lab with DC, SQL, 2 clients:
    - Create 4 VMs: 30 minutes
    - Install Windows on each: 2 hours
    - Configure networking: 30 minutes
    - Install AD on DC: 30 minutes
    - Join clients to domain: 20 minutes
    - Install SQL Server: 30 minutes
    - Configure everything: 1 hour
    
    Total: ~5 hours
    
    If you make a mistake? Start over (another 5 hours)
    Need to deploy again next week? Another 5 hours

**With IaC (Automated):**

    terraform apply    # Provisions VMs (5 minutes)
    ansible-playbook lab.yml    # Configures everything (20 minutes)
    
    Total: ~25 minutes
    
    Deploy again? 25 minutes
    Deploy 100 times? Still 25 minutes each (but automated)

### Key Benefits

**Speed:**
- Manual: Hours per deployment
- IaC: Minutes per deployment

**Consistency:**
- Manual: Each deployment slightly different (human error)
- IaC: Identical every time

**Documentation:**
- Manual: Word doc that gets outdated
- IaC: Code is always current

**Version Control:**
- Manual: No history of changes
- IaC: Git tracks every change

**Disaster Recovery:**
- Manual: Hope you remember everything
- IaC: Run the code, infrastructure restored

**Experimentation:**
- Manual: Scared to change things
- IaC: Deploy, test, destroy, repeat (safe to experiment)

---

## Key Concepts

### 1. Declarative Configuration

**You describe WHAT you want, not HOW to get it.**

**Example:**

    I want:
    - A VM named "web-server"
    - With 4 CPU cores
    - With 8 GB RAM
    - Running Ubuntu 22.04

The IaC tool figures out HOW to make that happen.

### 2. Idempotency

**Running the same code multiple times produces the same result.**

**Example:**

    First run:  Creates VM (doesn't exist yet)
    Second run: Does nothing (VM already exists as specified)
    Third run:  Does nothing (still correct)
    
    Change RAM to 16GB:
    Next run:   Updates VM (changes RAM, nothing else)

This is powerful because:
- Safe to run repeatedly
- Only changes what needs changing
- Can correct drift (if someone manually changed something)

### 3. State Management

**The tool tracks what infrastructure exists.**

**Example:**

    State file records:
    - VM "web-server" exists
    - Has 4 CPUs, 8GB RAM
    - IP address: 10.30.10.30
    
    When you run again:
    - Tool checks current state
    - Compares to desired state (your code)
    - Only makes necessary changes

### 4. Infrastructure as Code Lifecycle

    Write → Plan → Apply → Manage → Destroy
    
    Write:   Create configuration files
    Plan:    Preview what will change
    Apply:   Make the changes
    Manage:  Update as needed
    Destroy: Remove when done (optional)

---

## Declarative vs Imperative

### Imperative (Step-by-Step Instructions)

**You tell the computer HOW to do something, step by step.**

**Bash script example:**

    #!/bin/bash
    # Create VM
    qm create 100 --name web-server
    qm set 100 --cores 4
    qm set 100 --memory 8192
    qm set 100 --net0 virtio,bridge=vmbr0
    qm start 100

**Problems:**
- What if VM 100 already exists? (error)
- What if you run it twice? (tries to create duplicate)
- What if you want to change RAM? (need different script)
- Hard to maintain

### Declarative (Desired State)

**You tell the computer WHAT you want, it figures out HOW.**

**Terraform example:**

    resource "proxmox_vm_qemu" "web_server" {
      name    = "web-server"
      cores   = 4
      memory  = 8192
      network {
        bridge = "vmbr0"
      }
    }

**Benefits:**
- If it exists, does nothing
- Run it 100 times, same result
- Change RAM in code, run again, updates VM
- Tool handles the "how"

### Key Difference

**Imperative:** "Do this, then this, then this"
**Declarative:** "I want this final result"

IaC tools (Terraform, Ansible) are primarily declarative.

---

## IaC Workflow

### Typical Development Workflow

    1. Write configuration
       ├─ Create/edit .tf files (Terraform)
       └─ Create/edit .yml files (Ansible)
    
    2. Version control
       ├─ git add .
       ├─ git commit -m "Add web server"
       └─ git push
    
    3. Plan changes (preview)
       ├─ terraform plan
       └─ See what will change
    
    4. Review plan
       ├─ Check proposed changes
       └─ Verify looks correct
    
    5. Apply changes
       ├─ terraform apply
       └─ Infrastructure created/updated
    
    6. Verify
       ├─ Test infrastructure
       └─ Confirm working as expected
    
    7. Iterate
       └─ Make changes, repeat process

### Production Workflow

    Development → Testing → Staging → Production
    
    1. Dev:     Test changes in dev environment
    2. Testing: Automated tests run
    3. Staging: Deploy to staging, manual testing
    4. Prod:    Deploy to production

For homelab, you'll mostly work in dev/testing.

---

## Common Tools

### Infrastructure Provisioning

**Terraform (What we'll use):**
- Creates infrastructure (VMs, networks, etc.)
- Declarative
- Provider-based (supports many platforms)
- State management
- Plan before apply

**Alternatives:**
- Pulumi (code-based IaC)
- CloudFormation (AWS only)
- ARM Templates (Azure only)

### Configuration Management

**Ansible (What we'll use):**
- Configures systems after they exist
- Agentless (uses SSH)
- Playbooks (YAML)
- Idempotent
- Large module library

**Alternatives:**
- Chef (agent-based, Ruby)
- Puppet (agent-based, declarative)
- SaltStack (agent-based, Python)

### Why Terraform + Ansible?

**Terraform:**
- Best for infrastructure provisioning
- Creates VMs, networks, storage
- Manages infrastructure lifecycle

**Ansible:**
- Best for configuration management
- Installs software, configures systems
- Ongoing maintenance tasks

**Together:** Complete infrastructure automation

---

## Terraform and Ansible Roles

### What Each Tool Does Best

**Terraform = Infrastructure Layer**

    What Terraform Creates:
    ├─ Virtual machines
    ├─ Networks and subnets
    ├─ Storage volumes
    ├─ Load balancers
    └─ Cloud resources

**Ansible = Configuration Layer**

    What Ansible Configures:
    ├─ Operating system settings
    ├─ Software installation
    ├─ Service configuration
    ├─ User management
    └─ Application deployment

### Visual Workflow

    ┌─────────────────────────────────────┐
    │  1. Write Terraform Config          │
    │     Describe infrastructure         │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │  2. Terraform Provisions            │
    │     Creates VMs on Proxmox          │
    │     VMs are empty (just OS)         │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │  3. Terraform Outputs               │
    │     IP addresses of new VMs         │
    │     Can pass to Ansible             │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │  4. Write Ansible Playbook          │
    │     Describe configuration          │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │  5. Ansible Configures              │
    │     Installs software               │
    │     Configures services             │
    │     Sets up users, firewall, etc.   │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │  6. Complete Infrastructure         │
    │     Ready to use                    │
    └─────────────────────────────────────┘

### Real Example: Web Server Deployment

**Terraform's Job:**

    resource "proxmox_vm_qemu" "web" {
      name   = "web-server"
      cores  = 2
      memory = 4096
      # Creates the VM
    }

**Result:** Empty Ubuntu VM exists

**Ansible's Job:**

    - name: Configure web server
      hosts: web-server
      tasks:
        - name: Install Apache
          apt:
            name: apache2
            state: present
        
        - name: Copy website files
          copy:
            src: website/
            dest: /var/www/html/
        
        - name: Start Apache
          service:
            name: apache2
            state: started

**Result:** Web server fully configured and running

### Why Not Use Just One Tool?

**Could you use only Terraform?**
- Yes, but it's not designed for configuration
- Would be complex and harder to maintain
- Terraform is optimized for infrastructure

**Could you use only Ansible?**
- Yes, Ansible can create VMs
- But Terraform is better at infrastructure state
- Terraform handles dependencies better

**Best practice: Use both**
- Each tool does what it's best at
- Terraform: Infrastructure (build the house)
- Ansible: Configuration (furnish the house)

---

## Your First IaC Journey

### Learning Path

**Week 1: Terraform Basics**
1. Read [Terraform Basics](TERRAFORM_BASICS.md)
2. Install Terraform
3. Try simple example (local file)
4. Deploy first VM to Proxmox

**Week 2: Ansible Basics**
1. Read [Ansible Basics](ANSIBLE_BASICS.md)
2. Install Ansible
3. Try simple playbook (ping)
4. Configure a VM with Ansible

**Week 3: Integration**
1. Read [Terraform and Ansible Together](TERRAFORM_AND_ANSIBLE.md)
2. Terraform creates VM
3. Ansible configures it
4. Complete workflow

**Week 4: Real Projects**
1. Deploy lab environment
2. Automate something useful
3. Document your work

### What You'll Build

**Project 1: Single VM**
- Terraform: Create Ubuntu VM
- Ansible: Install Docker

**Project 2: Web Server**
- Terraform: Create VM
- Ansible: Install Apache, deploy website

**Project 3: Lab Environment**
- Terraform: Create DC, SQL, clients
- Ansible: Configure AD, join domain

**Project 4: Your Choice**
- Automate something from your homelab
- Practice what you've learned

---

## Key Takeaways

**Infrastructure as Code:**
- Write code to describe infrastructure
- Tools execute code automatically
- Fast, consistent, repeatable

**Declarative Approach:**
- Describe what you want
- Tool figures out how to get there
- Idempotent (safe to run repeatedly)

**Terraform:**
- Provisions infrastructure
- Creates VMs, networks, etc.
- Manages infrastructure lifecycle

**Ansible:**
- Configures systems
- Installs software, configures services
- Ongoing management

**Together:**
- Terraform builds infrastructure
- Ansible configures it
- Complete automation solution

---

## Common Questions

**Q: Do I need to know programming?**
A: No! IaC uses configuration languages (HCL for Terraform, YAML for Ansible). They're simpler than programming languages. If you can write a config file, you can do IaC.

**Q: What if I break something?**
A: That's what homelabs are for! IaC makes it easy to destroy and rebuild. Break things, learn, try again.

**Q: How long does it take to learn?**
A: Basics: 1-2 weeks. Proficiency: 2-3 months of practice. Mastery: Ongoing.

**Q: Do I need both Terraform AND Ansible?**
A: For complete automation, yes. But you can start with one and add the other later.

**Q: What if I just want to automate one thing?**
A: Start simple! Automate one task, then expand. You don't need to automate everything at once.

**Q: Can I use this in production?**
A: Yes! These are production-grade tools. Practice in homelab first, then apply skills at work.

---

## Next Steps

Now that you understand IaC concepts:

1. **Learn Terraform:** Read [Terraform Basics](TERRAFORM_BASICS.md)
2. **Learn Ansible:** Read [Ansible Basics](ANSIBLE_BASICS.md)
3. **See Integration:** Read [Terraform and Ansible Together](TERRAFORM_AND_ANSIBLE.md)
4. **Try Examples:** Work through examples in each section

---

## Additional Resources

### Recommended Reading

**Concepts:**
- [Infrastructure as Code](https://www.oreilly.com/library/view/infrastructure-as-code/9781098114664/)
- [Terraform: Up & Running](https://www.terraformupandrunning.com/)
- [Ansible for DevOps](https://www.ansiblefordevops.com/)

**Documentation:**
- [Terraform Docs](https://www.terraform.io/docs)
- [Ansible Docs](https://docs.ansible.com/)

**Community:**
- r/Terraform
- r/Ansible
- r/homelab

### Homelab Context

Remember: This IaC repository automates your [security-homelab](https://github.com/[your-username]/security-homelab) infrastructure. Refer to that documentation for what we're automating.

---

Last Updated: February 2026
