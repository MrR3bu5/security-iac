# Terraform – Infrastructure as Code (Proxmox)

This directory contains the Terraform configuration used to provision and manage infrastructure for the `security-homelab` project.

The goal of this Terraform implementation is not simply VM creation, but to model **real-world infrastructure patterns** including authentication, RBAC, template-based provisioning, and reproducible builds.

Terraform serves as the **authoritative source of truth** for lab infrastructure.

---

## Scope and Intent

This Terraform configuration is responsible for:

- Authenticating to Proxmox via **API tokens** (no credentials stored in code)
- Enforcing Proxmox RBAC and privilege separation
- Provisioning virtual machines using **template-based cloning**
- Injecting SSH access via **cloud-init**
- Exposing infrastructure metadata through Terraform outputs
- Supporting future handoff into configuration management and security automation

---

## Authentication Model

Terraform authenticates to Proxmox using a **dedicated API token** assigned to a service account.

Key characteristics:
- No passwords or secrets committed to Git
- API token permissions are explicitly assigned using **API Token Permissions**
- Initial broad permissions (`PVEAdmin`) were used for learning and validation
- Future iterations will reduce permissions to least privilege

This mirrors enterprise automation patterns and avoids implicit trust.

---

## Provisioning Model

Virtual machines are provisioned by **cloning from a pre-built Ubuntu 22.04 template** in Proxmox.

Benefits of this approach:
- Consistent and repeatable builds
- Faster provisioning
- Predictable guest configuration
- Clean separation between image creation and infrastructure orchestration

Cloud-init is used to:
- Create a non-root user
- Inject SSH public keys
- Enable immediate, passwordless access for automation

---

## Repository Structure
``` text
terraform/
├── provider.tf # Provider configuration (Proxmox)
├── variables.tf # Input variables
├── terraform.tfvars # Local values (gitignored)
├── vm_from_template.tf # VM cloning and initialization logic
├── outputs.tf # Exported infrastructure data
└── README.md
```
---

## State Management

Terraform state is maintained locally for this lab environment.

- State files are excluded from version control
- `.terraform/` working directories are gitignored
- Terraform outputs are used as the integration point for downstream tooling

Remote state may be introduced in later phases.

---

## Lessons Learned

Key takeaways from this phase include:

- Proxmox API tokens with **Privilege Separation** require explicit API Token Permissions
- Terraform enforces clarity around hardware definitions (disk interfaces, NICs)
- Refactoring from ad-hoc resources to templates simplifies scale and maintenance
- Cloud-init integration eliminates manual provisioning steps

Failures and misconfigurations were intentionally documented to reinforce learning.

---

## Next Phase

The next phase will use Terraform outputs as input to:
- Configuration management
- Baseline hardening
- Security control enforcement

Terraform’s role will remain focused on **infrastructure provisioning**, not system configuration.

---

## Disclaimer

This Terraform configuration is designed for a controlled lab environment.
It intentionally prioritizes learning, visibility, and repeatability over production hardening.
