output "ubuntu_vm_name" {
  description = "Nombre de la máquina virtual Ubuntu"
  value       = azurerm_linux_virtual_machine.vm_ubuntu.name
}

output "ubuntu_public_ip" {
  description = "Dirección IP pública de la máquina virtual Ubuntu"
  value       = azurerm_public_ip.pip_ubuntu.ip_address
}