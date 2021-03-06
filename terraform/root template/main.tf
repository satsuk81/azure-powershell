# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.26"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
    features {}
}
# Variables
variable "vmname" {
    type = string
    default = "test"
}
variable "vmnic" {
    type = string
    default = "test-nic"
}
variable "vmip" {
    type = string
    default = "test-ip"
}
variable "vmosdisk" {
    type = string
    default = "test-osdisk"
}

module "environment" {
  source = "./environment"
}
