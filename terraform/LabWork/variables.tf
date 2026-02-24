variable "pm_api_url" {
  type        = string
  description = "Proxmox API endpoint (e.g., https://host:8006/api2/json)"
}

variable "pm_api_token" {
  type        = string
  description = "Proxmox API token in the form 'USER@REALM!TOKEN=SECRET'"
  sensitive   = true
}

variable "pm_tls_insecure" {
  type        = bool
  description = "Allow insecure TLS (useful for self-signed certs in lab)"
  default     = true
}

variable "pve_node" {
  type        = string
  description = "Proxmox node name"
  default     = "pve"
}

variable "vm_name" {
  type        = string
  description = "Name of the Terraform-managed VM"
  default     = "tf-lab-utility-01"
}

variable "template_vm_id" {
  type        = number
  description = "Proxmox template VMID to clone from"
  default     = 9000
}

variable "vm_vlan_id" {
  type        = number
  description = "VLAN tag to apply to the VM NIC (0 = untagged)"
  default     = 0
}

variable "vm_bridge" {
  type        = string
  description = "Proxmox network bridge to attach the VM"
  default     = "vmbr0"
}

variable "ci_user" {
  type        = string
  description = "Cloud-init username"
  default     = "ubuntu"
}

variable "ci_ssh_public_key" {
  type        = string
  description = "SSH public key for cloud-init user"
}
