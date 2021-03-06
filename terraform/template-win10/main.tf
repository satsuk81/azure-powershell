# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = var.vmip
    location                     = "eastus"
    resource_group_name          = var.myterraformgroupName
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = var.vmnic
    location                  = "eastus"
    resource_group_name       = var.myterraformgroupName

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = var.myterraformsubnetID
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "example" {
    network_interface_id      = azurerm_network_interface.myterraformnic.id
    network_security_group_id = var.myterraformnsgID
}

# Generate random text for a unique storage account name
#resource "random_id" "randomId" {
#    keepers = {
#        # Generate a new ID only when a new resource group is defined
#        resource_group = azurerm_resource_group.myterraformgroup.name
#    }
#
#    byte_length = 8
#}

# Create storage account for boot diagnostics
#resource "azurerm_storage_account" "mystorageaccount" {
#    name                        = "diag${random_id.randomId.hex}"
#    resource_group_name         = azurerm_resource_group.myterraformgroup.name
#    location                    = "eastus"
#    account_tier                = "Standard"
#    account_replication_type    = "LRS"

#    tags = {
#        environment = "Terraform Demo"
#    }
#}

# Create (and display) an SSH key
#resource "tls_private_key" "example_ssh" {
#  algorithm = "RSA"
#  rsa_bits = 4096
#}
#output "tls_private_key" { value = tls_private_key.example_ssh.private_key_pem }

# Create virtual machine
resource "azurerm_windows_virtual_machine" "myterraformvm" {
    name                  = var.vmname
    location              = "eastus"
    resource_group_name   = var.myterraformgroupName
    network_interface_ids = [azurerm_network_interface.myterraformnic.id]
    size                  = "Standard_B2s"

    os_disk {
        name              = var.vmosdisk
        caching           = "ReadWrite"
        storage_account_type = "Premium_LRS"
    }

    source_image_reference {
        publisher = "MicrosoftWindowsDesktop"
        offer     = "Windows-10"
        sku       = "20h2-ent"
        version   = "latest"
    }

    computer_name  = var.vmname
    admin_username = "apppackager"
    admin_password = "Password1234"
    #disable_password_authentication = false

    #admin_ssh_key {
    #    username       = "azureuser"
    #    public_key     = tls_private_key.example_ssh.public_key_openssh
    #}

    #boot_diagnostics {
    #    storage_account_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    #}

    identity {
        type = "SystemAssigned"
    }

    tags = {
        environment = "Terraform Demo"
    }
}