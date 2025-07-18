terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.46.5"
    }
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  name       = var.vm_name
  node_name  = "proxmox"

  clone {
    vm_id = 999
    full  = true
  }

  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = 4096
  }

  network_device {
    model       = "e1000"
    bridge      = "vmbr0"
    mac_address = var.mac_address
  }

  disk {
    interface    = "scsi0"
    size         = 20
    datastore_id = "Samsung980ZFS"
  }

  operating_system {
    type = "l26"
  }

  agent {
    enabled = false
  }

  tags = var.vm_tags

  connection {
    type     = "ssh"
    user     = "root"
    password = "szkolenie"
    host     = "192.168.20.1"
    port     = 22
  }

provisioner "remote-exec" {
  inline = [
    "sudo sed -i -E 's/^#?Port .*/Port 60201/' /etc/ssh/sshd_config",
    "sudo systemctl daemon-reload",
    "sudo systemctl restart sshd",
    "sudo systemctl enable sshd"
  ]
  }
}

