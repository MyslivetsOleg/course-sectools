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
 backend "s3" {
    bucket                     = "sectools-cicd-bucket"
    key                        = "tfstate/sectools.tfstate"
    region                     = "us-east-1"
    endpoint                   = "http://minio.sectools.lab:9000"
    access_key                 = var.minio_access_key
    secret_key                 = var.minio_secret_key
    force_path_style           = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
  }
}

provider "opennebula" {
  endpoint = "http://oncloud.grsu.by:2633/RPC2"
  username = var.opennebula_username
  password = var.opennebula_password
}
