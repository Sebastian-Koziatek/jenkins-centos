variable "proxmox_api_token" {
  description = "API token do autoryzacji w Proxmox"
  type        = string
  sensitive   = true
}

variable "vm_tags" {
  description = "Tagi przypisane do VM"
  type        = list(string)
  default     = ["CentOS", "Linux", "terraform"]
}

variable "machines" {
  type    = list(string)
  default = []
}
variable "create_zabbix_agents" {
  description = "Czy utworzyć Zabbix Agenty?"
  type        = bool
  default     = true
}
