terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "lab1_resource_group" {
  name     = "lab1-resources"
  location = "West Europe"
}

resource "azurerm_virtual_network" "lab1_virtual_network" {
  name                = "lab1_virtual_network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.lab1_resource_group.location
  resource_group_name = azurerm_resource_group.lab1_resource_group.name
}

resource "azurerm_subnet" "lab1_subnet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.lab1_resource_group.name
  virtual_network_name = azurerm_virtual_network.lab1_virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "lab1_public_ip" {
  name                = "lab1-public-ip"
  location            = azurerm_resource_group.lab1_resource_group.location
  resource_group_name = azurerm_resource_group.lab1_resource_group.name
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_network_interface" "lab1_network_interface" {
  name                = "lab1-nic"
  location            = azurerm_resource_group.lab1_resource_group.location
  resource_group_name = azurerm_resource_group.lab1_resource_group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab1_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.lab1_public_ip.id
  }
}

resource "azurerm_linux_virtual_machine" "lab1_virtual_machine" {
  name                = "lab1-virtual-machine"
  resource_group_name = azurerm_resource_group.lab1_resource_group.name
  location            = azurerm_resource_group.lab1_resource_group.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.lab1_network_interface.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/my-azure-vm-key.pub")
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
