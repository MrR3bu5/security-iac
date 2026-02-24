output "lab_vm_id" {
  value       = proxmox_virtual_environment_vm.lab_vm.id
  description = "Proxmox VM resource ID"
}

output "lab_vm_name" {
  value       = proxmox_virtual_environment_vm.lab_vm.name
  description = "Name of the Terraform-managed VM"
}
