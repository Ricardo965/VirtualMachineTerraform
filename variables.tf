# variables.tf
# Variables para configuración de Azure
variable "subscription_id" {
  description = "ID de suscripción de Azure"
  type        = string
}

variable "client_id" {
  description = "ID de cliente para autenticación"
  type        = string
}

variable "client_secret" {
  description = "Secreto de cliente para autenticación"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "ID de inquilino de Azure"
  type        = string
}

# Variables generales del proyecto
variable "project_prefix" {
  description = "Prefijo para nombrar recursos"
  type        = string
  default     = "miproyecto"
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos"
  type        = string
  default     = "rg-vms-terraform"
}

variable "location" {
  description = "Región de Azure para los recursos"
  type        = string
  default     = "eastus"
}


# Variables para máquina Ubuntu
variable "ubuntu_vm_size" {
  description = "Tamaño de la máquina virtual Ubuntu"
  type        = string
  default     = "Standard_B2s"
}

variable "ubuntu_admin_username" {
  description = "Nombre de usuario administrador para Ubuntu"
  type        = string
}

variable "ubuntu_admin_password" {
  description = "Clave de usuario administrador para Ubuntu"
  type        = string
}