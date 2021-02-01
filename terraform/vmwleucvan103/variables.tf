# Variables
variable "vmname" {
    type = string
    default = "vmwleucvan103"
}
variable "vmnic" {
    type = string
    default = "vmwleucvan103-nic"
}
variable "vmip" {
    type = string
    default = "vmwleucvan103-ip"
}
variable "vmosdisk" {
    type = string
    default = "vmwleucvan103-osdisk"
}

variable "myterraformgroupName" {
    type = string
}

variable "myterraformsubnetID" {
    type = string
}

variable "myterraformnsgID" {
    type = string
}
