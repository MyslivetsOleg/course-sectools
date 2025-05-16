resource "opennebula_virtual_machine" "vm" {
  count        = var.vm_count
  name         = "sectools-credit-${count.index}"
  template_id  = 2434  # ID шаблона в OpenNebula
  memory       = 1024
  cpu          = 2
}
terraform {
  required_providers {
    opennebula = {
      source  = "OpenNebula/opennebula"
      version = ">= 1.4.1"
    }
  }
}

provider "opennebula" {
  endpoint = "http://oncloud.grsu.by:2633/RPC2"
  username = var.opennebula_username
  password = var.opennebula_password
}
