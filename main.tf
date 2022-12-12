resource "azurerm_resource_group" "terraform_rg" {
  name     = var.terraform_rg_name
  location = var.location
}

resource "azurerm_storage_account" "terraform_sa" {
  name                     = var.storage_account_name
  resource_group_name      = var.terraform_rg_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "${var.vm_name}-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = var.terraform_rg_name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal_subnet"
  resource_group_name  = var.terraform_rg_name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.terraform_rg_name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = var.vm_name
  location              = var.location
  resource_group_name   = var.terraform_rg_name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  delete_os_disk_on_termination = true

  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = var.vm_name
    admin_username = var.vm_user_name
    admin_password = var.vm_user_password
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
}