resource "azurerm_resource_group" "AzureLG" {
  name     = var.resource_group_name
  location = var.location_name
}

resource "azurerm_virtual_network" "vnet" {
  name                = var.network_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.AzureLG.location
  resource_group_name = azurerm_resource_group.AzureLG.name
}

resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.AzureLG.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "vnic"
  location            = azurerm_resource_group.AzureLG.location
  resource_group_name = azurerm_resource_group.AzureLG.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}
resource "azurerm_public_ip" "pip" {
  name                = "VIP"
  location            = azurerm_resource_group.AzureLG.location
  resource_group_name = azurerm_resource_group.AzureLG.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm1"
  resource_group_name = azurerm_resource_group.AzureLG.name
  location            = azurerm_resource_group.AzureLG.location
  size                = "Standard_F2"
  admin_username      = "azureuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("/home/keys-lg/azure.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  plan {
    name      = "centos-8-stream-free"
    product   = "centos-8-stream-free"
    publisher = "cognosys"
  }


  source_image_reference {
    publisher = "cognosys"
    offer     = "centos-8-stream-free"
    sku       = "centos-8-stream-free"
    version   = "22.03.28"
  }
}

resource "azurerm_network_security_group" "nsg_LG" {
  name			= "securitygroup"
  location		= azurerm_resource_group.AzureLG.location
  resource_group_name	= azurerm_resource_group.AzureLG.name

  security_rule {
	name				= "sshprule"
	priority			= 1001
	direction			= "Inbound"
	access				= "Allow"
	protocol			= "Tcp"
	source_port_range		= "*"
	destination_port_range		= "22"
	source_address_prefix		= "*"
	destination_address_prefix	= "*"
   }

security_rule {
         name                            = "httprule"
         priority                        = 1002
         direction                       = "Inbound"
         access                          = "Allow"
         protocol                        = "Tcp"
         source_port_range               = "*"
         destination_port_range          = "8080"
         source_address_prefix           = "*"
         destination_address_prefix      = "*"

   }
}


resource "azurerm_subnet_network_security_group_association" "nsg_LG" {
   subnet_id			= azurerm_subnet.subnet.id
   network_security_group_id	= azurerm_network_security_group.nsg_LG.id
}

resource "azurerm_container_registry" "containerRegistrylg" {
  name                = "containerRegistrylg"
  resource_group_name = azurerm_resource_group.AzureLG.name
  location            = azurerm_resource_group.AzureLG.location
  sku                 = "Premium"
  admin_enabled       = false
 }

resource "azurerm_kubernetes_cluster" "AKSLG" {
  name                = "AKSLG"
  location            = azurerm_resource_group.AzureLG.location
  resource_group_name = azurerm_resource_group.AzureLG.name
  dns_prefix          = "AKSLG"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Pro_LG"
  }
}
