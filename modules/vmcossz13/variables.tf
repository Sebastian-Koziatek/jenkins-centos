
variable "vm_name" {
  description = "Nazwa maszyny wirtualnej"
  type        = string
}

variable "mac_address" {
  description = "Adres MAC maszyny"
  type        = string
}

variable "vm_tags" {
  description = "Tagi maszyny"
  type        = list(string)
}

