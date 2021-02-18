# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "rg-wl-prod-eucpackaging"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Storage Account
resource "azurerm_storage_account" "mystorageaccount" {
    name = "stwleucpackaging01"
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    location = "eastus"
    account_tier = "Standard"
    account_replication_type = "LRS"
    allow_blob_public_access = true

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_storage_container" "mystoragecontainer" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.mystorageaccount.name
  container_access_type = "blob"
}

resource "azurerm_storage_share" "mystorageshare" {
  name                 = "packaging"
  storage_account_name = azurerm_storage_account.mystorageaccount.name
  quota                = 50
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "PackagingVnetPROD"
    address_space       = ["10.22.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "default"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefixes       = ["10.22.255.128/26"]
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "PackagingNsgPROD"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

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

   tags = {
        environment = "Terraform Demo"
    }
}
