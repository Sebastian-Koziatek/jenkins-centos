terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.46.5"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://192.168.0.3:8006/"
  insecure  = true
  api_token = var.proxmox_api_token
}
