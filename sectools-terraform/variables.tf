variable "vm_count" {
  description = "VM count"
  type        = number
  default     = 1
}
variable "opennebula_username" {
  description = "OpenNebula username"
  type        = string
}

variable "opennebula_password" {
  description = "OpenNebula password"
  type        = string
  sensitive   = true
}
