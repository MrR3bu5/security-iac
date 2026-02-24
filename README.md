# Security IaC (Infrastructure as Code)

Infrastructure as Code configurations and automation for security homelab environments using Terraform and Ansible.

## 🎯 Purpose

This repository serves two goals:

1. **Learning**: Understand Infrastructure as Code principles, Terraform, and Ansible
2. **Automation**: Automate deployment and configuration of security homelab infrastructure

## 📚 What You'll Learn

### Infrastructure as Code Concepts
- What is Infrastructure as Code and why use it?
- Declarative vs imperative approaches
- Version control for infrastructure
- Idempotency and state management

### Terraform
- Infrastructure provisioning
- Resource management
- State management
- Providers and modules

### Ansible
- Configuration management
- Automation and orchestration
- Playbooks and roles
- Inventory management

### How They Work Together
- Terraform provisions infrastructure
- Ansible configures what Terraform built
- Complete deployment workflows

## 🚀 Quick Start

**New to IaC?** Start here:

1. Read [Getting Started](docs/GETTING_STARTED.md) - Core concepts
2. Learn [Terraform Basics](docs/TERRAFORM_BASICS.md) - Provisioning infrastructure
3. Learn [Ansible Basics](docs/ANSIBLE_BASICS.md) - Configuring systems
4. Understand [How They Work Together](docs/TERRAFORM_AND_ANSIBLE.md)
5. Follow a [Complete Workflow](docs/WORKFLOW.md)

**Already familiar with IaC?** Jump to:
- [Terraform configurations](terraform/)
- [Ansible playbooks](ansible/)
- [End-to-end workflows](workflows/)

## 🏗️ Repository Structure

    security-iac/
    ├── docs/              # Learning documentation
    ├── terraform/         # Terraform configurations
    ├── ansible/           # Ansible playbooks and roles
    └── workflows/         # Complete deployment workflows

## 🔧 Tools Used

### Terraform
- **Version**: [Your version]
- **Purpose**: Provision infrastructure (VMs, networks, etc.)
- **Providers**: Proxmox, local

### Ansible
- **Version**: [Your version]
- **Purpose**: Configure systems, deploy applications
- **Inventory**: Static and dynamic

## 💡 Real-World Use Cases

### What This Repository Automates

**Homelab Infrastructure:**
- Provision VMs on Proxmox
- Configure network settings
- Deploy firewall configurations
- Set up lab environments

**Security Lab:**
- Deploy vulnerable AD environment
- Configure attack/defense scenarios
- Install security tools
- Set up monitoring (Wazuh)

**Configuration Management:**
- System hardening
- Service installation
- User management
- Firewall rules

## 📖 Documentation

### Learning Path

**Level 1: Foundations**
1. [Getting Started](docs/GETTING_STARTED.md) - IaC concepts
2. [Terraform Basics](docs/TERRAFORM_BASICS.md) - Provision resources
3. [Ansible Basics](docs/ANSIBLE_BASICS.md) - Configure systems

**Level 2: Integration**
4. [Terraform and Ansible Together](docs/TERRAFORM_AND_ANSIBLE.md)
5. [Workflow Guide](docs/WORKFLOW.md) - End-to-end process

**Level 3: Practice**
6. [Examples](docs/EXAMPLES.md) - Common patterns
7. [Workflows](workflows/) - Complete deployments

### Quick References

- [Terraform README](terraform/README.md) - Terraform-specific docs
- [Ansible README](ansible/README.md) - Ansible-specific docs
- [Workflow Examples](workflows/README.md) - Complete workflows

## 🎓 Learning Approach

This repository is designed for **learning by doing**:

1. **Concept explanation** - Understand the "why"
2. **Simple examples** - See basic usage
3. **Real-world applications** - Apply to homelab
4. **Incremental complexity** - Build on previous knowledge

Each section includes:
- Clear explanations
- Commented code examples
- Common pitfalls to avoid
- Best practices

## 🏠 Homelab Context

This IaC repository automates the infrastructure described in the [security-homelab](https://github.com/[your-username]/security-homelab) repository:

**What Gets Automated:**
- Proxmox VM provisioning
- Network configuration
- Firewall setup (OPNsense)
- Active Directory lab deployment
- Security tool installation (Kali, Wazuh, etc.)
- System hardening and configuration

**Manual vs Automated:**
- Physical hardware: Manual
- VM provisioning: **Terraform**
- OS configuration: **Ansible**
- Service deployment: **Ansible**
- Ongoing maintenance: **Ansible**

## 🔐 Security Considerations

### Secrets Management

**Never commit secrets to Git!**

This repository uses:
- `.gitignore` for sensitive files
- Environment variables for credentials
- Ansible Vault for encrypted secrets
- Terraform variables for sensitive data

**Files to NEVER commit:**
- `terraform.tfvars` (contains credentials)
- `*.pem`, `*.key` (private keys)
- `secrets.yml` (unencrypted secrets)
- `.env` files (environment variables)

### What's Safe to Commit

- Configuration templates
- Example configurations (with placeholders)
- Encrypted secrets (Ansible Vault)
- Documentation
- Code structure

## 📋 Prerequisites

### Required Software

**On your control machine:**

    # Terraform
    terraform --version  # v1.x or later

    # Ansible
    ansible --version    # v2.x or later

    # Git
    git --version

    # SSH
    ssh -V

### Required Access

- Proxmox API access (for VM provisioning)
- SSH access to target systems
- Network connectivity to homelab

### Knowledge Prerequisites

**Helpful but not required:**
- Basic Linux command line
- SSH concepts
- YAML syntax
- Basic networking

**You'll learn here:**
- Infrastructure as Code concepts
- Terraform usage
- Ansible usage
- How to combine them

## 🎯 Project Goals

### Primary Goals

1. **Learn IaC**: Understand infrastructure automation
2. **Automate Homelab**: Reduce manual deployment time
3. **Reproducible Infrastructure**: Deploy consistently
4. **Version Control**: Track infrastructure changes

### Secondary Goals

1. **Portfolio**: Demonstrate IaC skills
2. **Documentation**: Practice technical writing
3. **Best Practices**: Learn industry standards
4. **Problem Solving**: Troubleshoot automation

## 🚀 Getting Started

### 1. Clone the Repository

    git clone https://github.com/[your-username]/security-iac.git
    cd security-iac

### 2. Install Dependencies

**Terraform:**

    # macOS
    brew install terraform

    # Linux (Debian/Ubuntu)
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform

**Ansible:**

    # macOS
    brew install ansible

    # Linux (Debian/Ubuntu)
    sudo apt update
    sudo apt install ansible

    # Python pip
    pip install ansible

### 3. Start Learning

Read [Getting Started](docs/GETTING_STARTED.md) to understand IaC concepts, then work through the learning path.

### 4. Try Examples

Each section includes working examples you can run in your homelab.

## 📊 Status

### Current State

- [x] Repository structure
- [x] Learning documentation
- [ ] Terraform examples (in progress)
- [ ] Ansible examples (in progress)
- [ ] Complete workflows (planned)

### What's Automated

**Currently:**
- [List what you have automated]

**Planned:**
- VM provisioning with Terraform
- Configuration management with Ansible
- Complete lab deployment workflow
- Security tool installation

## 🤝 Learning Resources

### Official Documentation

- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Proxmox API](https://pve.proxmox.com/wiki/Proxmox_VE_API)

### Recommended Learning

- Terraform: [HashiCorp Learn](https://learn.hashicorp.com/terraform)
- Ansible: [Ansible Getting Started](https://docs.ansible.com/ansible/latest/getting_started/index.html)
- IaC Concepts: [Infrastructure as Code Book](https://www.oreilly.com/library/view/infrastructure-as-code/9781098114664/)

## 💬 Repository Philosophy

### Learning-First Approach

This repository prioritizes **learning and understanding** over production perfection:

- Extensive comments explain "why" not just "what"
- Simple examples before complex ones
- Mistakes documented as learning opportunities
- Multiple approaches shown with trade-offs

### Progressive Complexity

Start simple, add complexity gradually:

1. Single VM deployment
2. Multiple VMs
3. Network configuration
4. Complete environments
5. Advanced patterns

### Real-World Applications

All examples based on actual homelab needs:
- Not just toy examples
- Solve real problems
- Production-ready patterns
- Security best practices

## 📝 License

[Your License]

## 🙏 Acknowledgments

- HashiCorp for Terraform
- Red Hat for Ansible
- Homelab community for inspiration
- [Any other acknowledgments]

---

**Ready to learn Infrastructure as Code?** Start with [Getting Started](docs/GETTING_STARTED.md)!
