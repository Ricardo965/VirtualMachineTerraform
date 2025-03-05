# main.tf con los cambios necesarios

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0"
    }
  }
}

provider "azurerm" {
  features {}
  
  # Las credenciales se pasarán a través de variables de entorno o tfvars
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}

# Crear un grupo de recursos
resource "azurerm_resource_group" "rg_vms" {
  name     = var.resource_group_name
  location = var.location
}

# Red Virtual
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.project_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_vms.location
  resource_group_name = azurerm_resource_group.rg_vms.name
}

# Subred
resource "azurerm_subnet" "subnet" {
  name                 = "${var.project_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg_vms.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# IP Pública para Windows Server
resource "azurerm_public_ip" "pip_windows" {
  name                = "${var.project_prefix}-pip-win"
  location            = azurerm_resource_group.rg_vms.location
  resource_group_name = azurerm_resource_group.rg_vms.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# IP Pública para Ubuntu
resource "azurerm_public_ip" "pip_ubuntu" {
  name                = "${var.project_prefix}-pip-ubu"
  location            = azurerm_resource_group.rg_vms.location
  resource_group_name = azurerm_resource_group.rg_vms.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Security Group para Windows
resource "azurerm_network_security_group" "nsg_windows" {
  name                = "${var.project_prefix}-nsg-win"
  location            = azurerm_resource_group.rg_vms.location
  resource_group_name = azurerm_resource_group.rg_vms.name

  security_rule {
    name                       = "RDP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group para Ubuntu
resource "azurerm_network_security_group" "nsg_ubuntu" {
  name                = "${var.project_prefix}-nsg-ubu"
  location            = azurerm_resource_group.rg_vms.location
  resource_group_name = azurerm_resource_group.rg_vms.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Interfaces de red para Windows
resource "azurerm_network_interface" "nic_windows" {
  name                = "${var.project_prefix}-nic-win"
  location            = azurerm_resource_group.rg_vms.location
  resource_group_name = azurerm_resource_group.rg_vms.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_windows.id
  }
}

# Interfaces de red para Ubuntu
resource "azurerm_network_interface" "nic_ubuntu" {
  name                = "${var.project_prefix}-nic-ubu"
  location            = azurerm_resource_group.rg_vms.location
  resource_group_name = azurerm_resource_group.rg_vms.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip_ubuntu.id
  }
}

# Máquina Virtual Windows Server
resource "azurerm_windows_virtual_machine" "vm_windows" {
  name                = "${var.project_prefix}-win"
  computer_name       = "winserver"        # Nombre explícito de 15 caracteres o menos
  resource_group_name = azurerm_resource_group.rg_vms.name
  location            = azurerm_resource_group.rg_vms.location
  size                = var.windows_vm_size
  admin_username      = var.windows_admin_username
  admin_password      = var.windows_admin_password
  network_interface_ids = [
    azurerm_network_interface.nic_windows.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }
}

# Máquina Virtual Ubuntu
resource "azurerm_linux_virtual_machine" "vm_ubuntu" {
  name                = "${var.project_prefix}-ubu"
  computer_name       = "ubuntu"          # Nombre explícito de 15 caracteres o menos
  resource_group_name = azurerm_resource_group.rg_vms.name
  location            = azurerm_resource_group.rg_vms.location
  size                = var.ubuntu_vm_size
  admin_username      = var.ubuntu_admin_username
  network_interface_ids = [
    azurerm_network_interface.nic_ubuntu.id,
  ]

  admin_ssh_key {
    username   = var.ubuntu_admin_username
    public_key = file(var.ubuntu_ssh_public_key_path)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# Asociar NSG a interfaces de red - Con dependencias explícitas
resource "azurerm_network_interface_security_group_association" "windows_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic_windows.id
  network_security_group_id = azurerm_network_security_group.nsg_windows.id
  
  # Esperar a que la red y el grupo de seguridad estén listos
  depends_on = [
    azurerm_network_interface.nic_windows,
    azurerm_network_security_group.nsg_windows
  ]
}

resource "azurerm_network_interface_security_group_association" "ubuntu_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic_ubuntu.id
  network_security_group_id = azurerm_network_security_group.nsg_ubuntu.id
  
  # Esperar a que la red y el grupo de seguridad estén listos
  depends_on = [
    azurerm_network_interface.nic_ubuntu,
    azurerm_network_security_group.nsg_ubuntu
  ]
}