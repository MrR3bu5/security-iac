# Terraform, Infrastructure as Code, Proxmox

This directory contains the Terraform configuration used to provision and manage infrastructure for the `security-homelab` project.

The purpose of this implementation is to model realistic infrastructure patterns, not just create virtual machines. The design focuses on authentication, RBAC, template driven provisioning, and repeatable builds that reflect enterprise automation practices.

Terraform acts as the source of truth for lab infrastructure.

---

## Scope and Intent

This configuration is responsible for:

- Authenticating to Proxmox using API tokens with no credentials stored in code
- Enforcing RBAC and privilege separation
- Provisioning virtual machines through template based cloning
- Injecting SSH access with cloud init
- Publishing infrastructure metadata through Terraform outputs
- Supporting future integration with configuration management and security workflows

---

## Authentication Model

Terraform connects to Proxmox through a dedicated API token assigned to a service account.

Key design choices:

- No passwords or secrets committed to the repository
- API token permissions assigned explicitly through API Token Permissions
- Broad permissions were used during early validation
- Future iterations will reduce permissions toward least privilege

This approach mirrors enterprise automation patterns and removes implicit administrative access.

---

## Provisioning Model

Virtual machines are deployed by cloning a pre built Ubuntu 22.04 template in Proxmox.

Benefits of this model:

- Consistent and repeatable builds
- Faster deployment cycles
- Predictable guest configuration
- Clear separation between image creation and infrastructure orchestration

Cloud init handles:

- Creation of a non root user
- Injection of SSH public keys
- Immediate key based access for automation workflows

---

## Repository Structure

```text
terraform/
├── provider.tf            # Proxmox provider configuration
├── variables.tf           # Input variables
├── terraform.tfvars       # Local values, gitignored
├── vm_from_template.tf    # VM cloning and initialization logic
├── outputs.tf             # Exported infrastructure metadata
└── README.md
```

---

## State Management

Terraform state is maintained locally during this phase of the lab.

- State files are excluded from version control
- `.terraform/` working directories are gitignored
- Terraform outputs serve as the integration point for downstream tooling

Remote state management may be introduced in a future iteration.

---

## Lessons Learned

Key observations from this phase:

- Proxmox API tokens with privilege separation require explicit permission mapping
- Terraform exposes gaps in hardware definitions such as disk layout and network interfaces
- Moving from ad hoc builds to template driven provisioning improves consistency and long term maintenance
- Cloud init reduces manual provisioning steps and supports repeatable deployment

Failures and misconfigurations were documented to capture decisions and reinforce learning.

---

## Next Phase

The next stage will use Terraform outputs as input for:

- Configuration management workflows
- Baseline hardening activities
- Security control enforcement

Terraform will continue to focus on infrastructure provisioning rather than system configuration.

---

## Disclaimer

This Terraform configuration is built for a controlled lab environment. The design emphasizes learning, visibility, and repeatable workflows instead of production level hardening.
