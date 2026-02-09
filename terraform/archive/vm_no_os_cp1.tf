resource "proxmox_virtual_environment_vm" "lab_vm_cp1" {
  name      = var.vm_name
  node_name = var.pve_node

  description = "Terraform-managed lab VM (capstone phase 1)"

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    interface    = "scsi0"
    datastore_id = "local-lvm"
    size         = 20
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  boot_order = ["scsi0"]
}
