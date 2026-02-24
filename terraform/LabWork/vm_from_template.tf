resource "proxmox_virtual_environment_vm" "lab_vm" {
  name      = var.vm_name
  node_name = var.pve_node

  description = "Terraform-managed VM cloned from template (capstone phase 1.3)"

  clone {
    vm_id = var.template_vm_id
  }

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  network_device {
    bridge  = var.vm_bridge
    model   = "virtio"
    vlan_id = var.vm_vlan_id
  }

  initialization {
    user_account {
      username = var.ci_user
      keys     = [var.ci_ssh_public_key]
    }
  }
}
