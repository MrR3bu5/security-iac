# IaC Workflow Guide

Practical workflows for using Terraform and Ansible together in real-world scenarios.

## Table of Contents

1. [Overview](#overview)
2. [Development Workflow](#development-workflow)
3. [Testing Workflow](#testing-workflow)
4. [Production Deployment](#production-deployment)
5. [Day-to-Day Operations](#day-to-day-operations)
6. [Emergency Procedures](#emergency-procedures)
7. [Team Workflows](#team-workflows)
8. [CI/CD Integration](#cicd-integration)

---

## Overview

### What is a Workflow?

**Workflow:** A repeatable process for accomplishing a task using IaC tools.

Good workflows are:
- **Repeatable:** Same steps produce same results
- **Documented:** Clear instructions
- **Safe:** Include validation and rollback
- **Efficient:** Minimize manual steps

### Workflow Types

**Development:**
- Building new infrastructure
- Testing changes
- Iterating on designs

**Production:**
- Deploying to production
- Updating existing systems
- Scaling infrastructure

**Maintenance:**
- Applying updates
- Fixing configuration drift
- Troubleshooting issues

**Emergency:**
- Disaster recovery
- Rapid deployment
- Rollback procedures

---

## Development Workflow

### New Project Setup

**Goal:** Start a new infrastructure project from scratch

**Steps:**

**1. Create project structure**

    mkdir my-project
    cd my-project
    
    # Terraform directory
    mkdir -p terraform
    
    # Ansible directory
    mkdir -p ansible/{playbooks,roles,inventory}
    
    # Documentation
    mkdir docs
    
    # Scripts
    mkdir scripts

**2. Initialize Git**

    git init
    
    # Create .gitignore
    cat > .gitignore <<EOF
    # Terraform
    *.tfstate
    *.tfstate.backup
    .terraform/
    terraform.tfvars
    
    # Ansible
    *.retry
    
    # Generated files
    ansible/inventory/generated.ini
    
    # Secrets
    secrets/
    *.key
    *.pem
    EOF
    
    git add .
    git commit -m "Initial project structure"

**3. Create Terraform configuration**

    cd terraform
    
    # Main configuration
    cat > main.tf <<EOF
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
    EOF
    
    # Variables
    cat > variables.tf <<EOF
    variable "proxmox_url" {
      description = "Proxmox API URL"
      type        = string
    }
    
    variable "proxmox_user" {
      description = "Proxmox user"
      type        = string
      default     = "terraform@pam"
    }
    
    variable "proxmox_password" {
      description = "Proxmox password"
      type        = string
      sensitive   = true
    }
    EOF
    
    # Outputs
    cat > outputs.tf <<EOF
    # Define outputs as needed
    EOF
    
    # Example values (DO NOT COMMIT REAL VALUES)
    cat > terraform.tfvars.example <<EOF
    proxmox_url      = "https://proxmox.local:8006/api2/json"
    proxmox_user     = "terraform@pam"
    proxmox_password = "your-password-here"
    EOF

**4. Initialize Terraform**

    terraform init

**5. Create first resource**

    # Add to main.tf
    cat >> main.tf <<EOF
    
    resource "proxmox_vm_qemu" "test" {
      name        = "test-vm"
      target_node = "proxmox-host01"
      clone       = "ubuntu-22.04-template"
      
      cores   = 2
      memory  = 2048
      
      network {
        bridge = "vmbr0"
        model  = "virtio"
      }
      
      disk {
        size    = "20G"
        storage = "local-lvm"
      }
    }
    EOF

**6. Test deployment**

    # Copy example to actual file
    cp terraform.tfvars.example terraform.tfvars
    # Edit terraform.tfvars with real values
    
    # Plan
    terraform plan
    
    # Apply
    terraform apply

**7. Create Ansible playbook**

    cd ../ansible
    
    # Create basic playbook
    cat > playbooks/test.yml <<EOF
    ---
    - name: Test playbook
      hosts: all
      become: yes
      
      tasks:
        - name: Ping test
          ping:
        
        - name: Get system info
          debug:
            msg: "Running on {{ ansible_hostname }}"
    EOF
    
    # Create inventory
    cat > inventory/hosts.ini <<EOF
    [test]
    test-vm ansible_host=10.30.10.X ansible_user=ubuntu
    
    [all:vars]
    ansible_python_interpreter=/usr/bin/python3
    EOF

**8. Test Ansible**

    ansible-playbook -i inventory/hosts.ini playbooks/test.yml

**9. Commit to Git**

    cd ..
    git add .
    git commit -m "Add test VM configuration"

---

### Iterative Development

**Goal:** Make changes and test incrementally

**Workflow:**

    ┌─────────────────────────────────────┐
    │  1. Make small change               │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │  2. Test locally                    │
    │     terraform plan                  │
    │     (review changes)                │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │  3. Apply to dev environment        │
    │     terraform apply                 │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │  4. Test functionality              │
    │     ansible-playbook ...            │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │  5. Verify working                  │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │  6. Commit to Git                   │
    │     git commit                      │
    └──────────────┬──────────────────────┘
                   │
                   ▼
    ┌─────────────────────────────────────┐
    │  7. Repeat                          │
    └─────────────────────────────────────┘

**Example session:**

    # Add web server to Terraform
    vim terraform/main.tf
    
    # Plan changes
    cd terraform
    terraform plan
    # Review output
    
    # Apply
    terraform apply
    
    # Get IP address
    WEB_IP=$(terraform output -raw web_server_ip)
    
    # Create Ansible playbook
    cd ../ansible
    vim playbooks/webserver.yml
    
    # Update inventory
    echo "web-server ansible_host=$WEB_IP" >> inventory/hosts.ini
    
    # Test playbook
    ansible-playbook -i inventory/hosts.ini playbooks/webserver.yml
    
    # Verify
    curl http://$WEB_IP
    
    # Working? Commit!
    cd ..
    git add .
    git commit -m "Add web server configuration"

---

## Testing Workflow

### Pre-Deployment Testing

**Goal:** Validate changes before applying to production

**Steps:**

**1. Syntax validation**

    # Terraform
    cd terraform
    terraform fmt -check
    terraform validate
    
    # Ansible
    cd ../ansible
    ansible-playbook --syntax-check playbooks/*.yml

**2. Dry run**

    # Terraform plan
    cd terraform
    terraform plan -out=tfplan
    
    # Review plan carefully
    less tfplan
    
    # Ansible check mode
    cd ../ansible
    ansible-playbook --check -i inventory/hosts.ini playbooks/webserver.yml

**3. Test in isolated environment**

    # Create test environment
    cd terraform
    terraform workspace new test
    terraform workspace select test
    
    # Apply to test
    terraform apply
    
    # Test functionality
    cd ../ansible
    ansible-playbook -i inventory/test.ini playbooks/webserver.yml
    
    # Verify everything works
    # Run tests, check logs, etc.
    
    # Destroy test environment
    cd ../terraform
    terraform destroy
    terraform workspace select default
    terraform workspace delete test

**4. Automated testing**

**Create test script:**

**File: scripts/test.sh**

    #!/bin/bash
    set -e
    
    echo "==> Running IaC tests"
    
    # Terraform tests
    echo "Testing Terraform configuration..."
    cd terraform
    terraform fmt -check
    terraform validate
    terraform plan -detailed-exitcode
    cd ..
    
    # Ansible tests
    echo "Testing Ansible playbooks..."
    cd ansible
    for playbook in playbooks/*.yml; do
        ansible-playbook --syntax-check "$playbook"
    done
    cd ..
    
    echo "==> All tests passed!"

**Run tests:**

    chmod +x scripts/test.sh
    ./scripts/test.sh

---

### Testing Individual Components

**Test single Terraform resource:**

    # Comment out other resources
    # Or use -target flag
    terraform apply -target=proxmox_vm_qemu.web

**Test single Ansible task:**

    # Use tags
    - name: Install Apache
      apt:
        name: apache2
      tags: apache
    
    # Run only tagged tasks
    ansible-playbook --tags apache playbook.yml

**Test single host:**

    # Limit to one host
    ansible-playbook --limit web01 playbook.yml

---

## Production Deployment

### Pre-Deployment Checklist

**Before deploying to production:**

    ☐ Code reviewed
    ☐ Tested in dev environment
    ☐ Tested in staging environment
    ☐ Backups completed
    ☐ Rollback plan documented
    ☐ Team notified
    ☐ Maintenance window scheduled
    ☐ Monitoring ready

---

### Safe Production Deployment

**Workflow:**

**1. Preparation**

    # Create backup
    cd terraform
    cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d)
    
    # Review changes
    terraform plan > deployment-plan.txt
    
    # Review plan file
    less deployment-plan.txt

**2. Pre-deployment tasks**

    # Notify team
    echo "Deployment starting at $(date)" | mail -s "Deployment" team@company.com
    
    # Take snapshots
    # (Manual or automated via Proxmox)

**3. Deploy infrastructure**

    cd terraform
    
    # Apply with confirmation
    terraform apply
    
    # Verify outputs
    terraform output

**4. Configure systems**

    cd ../ansible
    
    # Test connectivity first
    ansible all -m ping -i inventory/production.ini
    
    # Apply configuration
    ansible-playbook -i inventory/production.ini playbooks/production.yml

**5. Verification**

    # Run smoke tests
    ./scripts/smoke-test.sh
    
    # Check services
    ansible all -m service -a "name=apache2 state=started" -i inventory/production.ini
    
    # Manual verification
    # Check websites, services, logs

**6. Post-deployment**

    # Document deployment
    cat >> CHANGELOG.md <<EOF
    ## $(date +%Y-%m-%d)
    
    ### Changes
    - Added web server cluster
    - Updated database configuration
    
    ### Deployed by
    $(whoami)
    
    ### Issues
    None
    EOF
    
    # Commit final state
    git add .
    git commit -m "Production deployment $(date +%Y-%m-%d)"
    git tag -a "prod-$(date +%Y%m%d)" -m "Production release"
    git push
    git push --tags
    
    # Notify completion
    echo "Deployment completed successfully at $(date)" | \
      mail -s "Deployment Complete" team@company.com

---

### Staged Rollout

**For large changes, deploy incrementally:**

**Phase 1: One server**

    # Deploy to single server
    ansible-playbook --limit web01 playbook.yml
    
    # Monitor for 1 hour
    # Check logs, performance, errors

**Phase 2: Small group**

    # Deploy to 25% of servers
    ansible-playbook --limit web01,web02,web03 playbook.yml
    
    # Monitor for 4 hours

**Phase 3: Remaining servers**

    # Deploy to all
    ansible-playbook playbook.yml

**Rollback at any phase if issues detected**

---

## Day-to-Day Operations

### Morning Routine

**Daily maintenance tasks:**

    # Check infrastructure state
    cd terraform
    terraform refresh
    
    # Check for drift
    terraform plan
    # Should show "No changes"
    
    # If changes detected:
    # - Investigate why (manual changes?)
    # - Update code or revert changes

---

### Configuration Updates

**Goal:** Update application configuration

**Workflow:**

**1. Update playbook**

    vim ansible/playbooks/webserver.yml
    
    # Change configuration values
    vars:
      max_connections: 500  # Changed from 200

**2. Test in dev**

    ansible-playbook --check playbooks/webserver.yml

**3. Apply to production**

    ansible-playbook playbooks/webserver.yml

**Note:** No Terraform needed (infrastructure unchanged)

---

### Infrastructure Scaling

**Goal:** Add more servers

**Workflow:**

**1. Update Terraform**

    vim terraform/main.tf
    
    # Change count
    resource "proxmox_vm_qemu" "web" {
      count = 5  # Changed from 3
      ...
    }

**2. Apply infrastructure change**

    cd terraform
    terraform plan
    terraform apply

**3. Update inventory**

    ./scripts/generate-inventory.sh

**4. Configure new servers**

    cd ../ansible
    ansible-playbook playbooks/webserver.yml

**Result:** New servers added and configured

---

### Regular Maintenance

**Weekly tasks:**

    # Update packages on all servers
    ansible all -m apt -a "upgrade=dist update_cache=yes" --become
    
    # Check disk space
    ansible all -m shell -a "df -h"
    
    # Check service status
    ansible all -m service -a "name=apache2" | grep -E "(running|stopped)"

**Monthly tasks:**

    # Review infrastructure
    cd terraform
    terraform show > current-state.txt
    
    # Review for optimization
    # - Unused resources?
    # - Oversized VMs?
    # - Cost optimization?
    
    # Update documentation
    vim ../docs/INFRASTRUCTURE.md

---

## Emergency Procedures

### Disaster Recovery

**Scenario:** Proxmox host failure, need to rebuild everything

**Prerequisites:**
- Git repository with all code (up to date)
- Terraform state backup
- Ansible playbooks tested
- Documentation current

**Recovery steps:**

**1. Assess damage**

    # Check what's lost
    # Document current state

**2. Prepare new infrastructure**

    # If new Proxmox host, configure it
    # Update Terraform variables if needed

**3. Restore from code**

    # Clone repository
    git clone https://github.com/user/infrastructure.git
    cd infrastructure
    
    # Restore Terraform state (if available)
    cp backups/terraform.tfstate.latest terraform/terraform.tfstate

**4. Rebuild infrastructure**

    cd terraform
    terraform init
    terraform plan
    terraform apply -auto-approve

**5. Reconfigure systems**

    cd ../ansible
    ./scripts/generate-inventory.sh
    ansible-playbook playbooks/all.yml

**6. Verify and restore data**

    # Check all services
    ./scripts/smoke-test.sh
    
    # Restore data from backups
    ansible-playbook playbooks/restore-data.yml

**Time estimate:**
- Small infrastructure (3-5 VMs): 30-60 minutes
- Medium infrastructure (10-20 VMs): 2-4 hours
- Large infrastructure: 4-8 hours

**This is why IaC is valuable!**

---

### Rollback Procedure

**Scenario:** Deployment caused issues, need to revert

**Option 1: Terraform rollback**

    # Revert to previous Git commit
    git log --oneline
    git revert HEAD
    
    # Or checkout previous version
    git checkout previous-tag
    
    # Apply old configuration
    cd terraform
    terraform apply

**Option 2: Ansible rollback**

    # Revert playbook changes
    git checkout HEAD~1 ansible/playbooks/webserver.yml
    
    # Reapply old configuration
    ansible-playbook playbooks/webserver.yml

**Option 3: Infrastructure restore**

    # Restore from snapshot (fastest)
    # Use Proxmox web interface or API
    
    # Or destroy and recreate
    terraform destroy -target=proxmox_vm_qemu.problem_vm
    terraform apply

**Document rollback:**

    cat >> INCIDENTS.md <<EOF
    ## $(date +%Y-%m-%d) - Rollback
    
    Issue: [Description]
    Rollback: [What was reverted]
    Root cause: [Why it happened]
    Prevention: [How to avoid in future]
    EOF

---

### Quick Fixes

**Emergency configuration change:**

    # Make minimal change
    ansible all -m lineinfile \
      -a "path=/etc/apache2/apache2.conf line='MaxConnections 100'" \
      --become
    
    # Restart service
    ansible all -m service -a "name=apache2 state=restarted" --become
    
    # Later: Update playbook with fix
    vim ansible/playbooks/webserver.yml
    git commit -m "Add MaxConnections fix"

**Quick infrastructure fix:**

    # Increase VM resources
    # Edit in Proxmox web interface
    
    # Later: Update Terraform
    vim terraform/main.tf
    terraform apply
    git commit -m "Increase VM resources"

**Rule:** Emergency fixes in production are OK, but ALWAYS update code afterward!

---

## Team Workflows

### Team Collaboration

**Multiple people working on infrastructure**

**Workflow:**

**1. Use branches**

    # Create feature branch
    git checkout -b feature/add-monitoring
    
    # Make changes
    vim terraform/main.tf
    
    # Test
    terraform plan
    
    # Commit
    git commit -m "Add monitoring infrastructure"
    
    # Push
    git push origin feature/add-monitoring

**2. Pull request review**

    # Team reviews changes
    # Discusses in PR comments
    # Suggests improvements

**3. Test in shared dev environment**

    # Team lead applies to test
    cd terraform
    terraform workspace select dev
    terraform apply

**4. Merge to main**

    # After approval
    git checkout main
    git merge feature/add-monitoring
    git push

**5. Deploy to production**

    # Scheduled deployment
    git checkout main
    git pull
    cd terraform
    terraform apply

---

### State Locking

**Prevent concurrent changes**

**Use remote state with locking:**

**Terraform Cloud (simplest):**

    terraform {
      backend "remote" {
        organization = "my-org"
        
        workspaces {
          name = "production"
        }
      }
    }

**S3 with DynamoDB (AWS):**

    terraform {
      backend "s3" {
        bucket         = "my-terraform-state"
        key            = "prod/terraform.tfstate"
        region         = "us-east-1"
        dynamodb_table = "terraform-locks"
      }
    }

**Benefits:**
- Prevents simultaneous applies
- Team shares state
- Automatic backups

---

### Code Review Checklist

**Before approving Terraform PR:**

    ☐ Resources properly named
    ☐ Variables used instead of hardcoded values
    ☐ Outputs defined for important values
    ☐ No secrets in code
    ☐ Proper resource sizing
    ☐ Tags applied
    ☐ terraform fmt applied
    ☐ terraform validate passes

**Before approving Ansible PR:**

    ☐ Tasks have descriptive names
    ☐ Playbook is idempotent
    ☐ Variables used appropriately
    ☐ Handlers defined for restarts
    ☐ No hardcoded passwords
    ☐ Proper privilege escalation (become)
    ☐ ansible-playbook --syntax-check passes

---

## CI/CD Integration

### Automated Testing Pipeline

**GitHub Actions example:**

**File: .github/workflows/test.yml**

    name: Test IaC
    
    on:
      pull_request:
        branches: [ main ]
    
    jobs:
      terraform:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v2
          
          - name: Setup Terraform
            uses: hashicorp/setup-terraform@v1
          
          - name: Terraform Format
            run: terraform fmt -check
            working-directory: terraform
          
          - name: Terraform Init
            run: terraform init
            working-directory: terraform
          
          - name: Terraform Validate
            run: terraform validate
            working-directory: terraform
          
          - name: Terraform Plan
            run: terraform plan
            working-directory: terraform
            env:
              TF_VAR_proxmox_password: ${{ secrets.PROXMOX_PASSWORD }}
      
      ansible:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v2
          
          - name: Setup Python
            uses: actions/setup-python@v2
            with:
              python-version: '3.9'
          
          - name: Install Ansible
            run: pip install ansible
          
          - name: Ansible Syntax Check
            run: |
              for playbook in ansible/playbooks/*.yml; do
                ansible-playbook --syntax-check "$playbook"
              done

**Result:** Every PR automatically tested

---

### Automated Deployment

**File: .github/workflows/deploy.yml**

    name: Deploy to Production
    
    on:
      push:
        branches: [ main ]
        tags:
          - 'v*'
    
    jobs:
      deploy:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v2
          
          - name: Setup Terraform
            uses: hashicorp/setup-terraform@v1
          
          - name: Terraform Init
            run: terraform init
            working-directory: terraform
          
          - name: Terraform Apply
            run: terraform apply -auto-approve
            working-directory: terraform
            env:
              TF_VAR_proxmox_password: ${{ secrets.PROXMOX_PASSWORD }}
          
          - name: Generate Inventory
            run: ./scripts/generate-inventory.sh
          
          - name: Install Ansible
            run: pip install ansible
          
          - name: Run Ansible
            run: ansible-playbook -i inventory.ini playbooks/all.yml
            working-directory: ansible

**Manual approval step (safer):**

    deploy:
      runs-on: ubuntu-latest
      environment:
        name: production
        url: https://example.com
      steps:
        # ... deployment steps

**GitHub will require manual approval before deploying**

---

## Quick Reference

### Daily Workflow

    # Check infrastructure
    terraform plan
    
    # Apply small changes
    terraform apply
    ansible-playbook playbook.yml
    
    # Commit
    git add .
    git commit -m "Description"
    git push

---

### Emergency Workflow

    # Quick fix
    ansible all -m shell -a "command" --become
    
    # Document later
    vim playbook.yml
    git commit -m "Fix: description"

---

### New Feature Workflow

    # Branch
    git checkout -b feature/new-thing
    
    # Develop
    vim terraform/main.tf
    terraform apply
    
    vim ansible/playbook.yml
    ansible-playbook playbook.yml
    
    # Test
    ./scripts/test.sh
    
    # Commit
    git commit -m "Add new feature"
    
    # PR
    git push origin feature/new-thing
    # Create PR on GitHub

---

## Best Practices Summary

**Always:**
- Plan before apply
- Test in dev first
- Review changes carefully
- Commit working code
- Document changes

**Never:**
- Apply without planning
- Make manual changes (update code instead)
- Commit secrets
- Skip testing
- Deploy on Friday afternoon

**Automation is good, but:**
- Understand what it does
- Have manual override
- Keep backups
- Test regularly
- Document everything

---

## Next Steps

Now that you understand IaC workflows:

1. **Practice:** Follow these workflows in your homelab
2. **Customize:** Adapt to your needs
3. **Automate:** Create scripts for common tasks
4. **Document:** Write your own procedures
5. **Improve:** Refine based on experience

---

## Additional Resources

**Workflow Tools:**
- Make (task automation)
- GitHub Actions (CI/CD)
- GitLab CI (CI/CD)
- Jenkins (CI/CD)

**Project Examples:**
- [Complete workflows](../workflows/)
- [Example scripts](../scripts/)

---

Last Updated: February 2026
