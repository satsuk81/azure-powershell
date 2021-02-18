# Output variable definitions

output "myterraformgroup" {
  description = "ARN of the bucket"
  value       = azurerm_resource_group.myterraformgroup
}

output "myterraformnetwork" {
  description = "ARN of the bucket"
  value       = azurerm_virtual_network.myterraformnetwork
}

output "myterraformsubnet" {
  description = "ARN of the bucket"
  value       = azurerm_subnet.myterraformsubnet
}

output "myterraformnsg" {
  description = "ARN of the bucket"
  value       = azurerm_network_security_group.myterraformnsg
}
