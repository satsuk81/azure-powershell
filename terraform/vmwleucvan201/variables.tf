# Variables
variable "vmname" {
    type = string
    default = "vmwleucvan201"
}
variable "vmnic" {
    type = string
    default = "vmwleucvan201-nic"
}
variable "vmip" {
    type = string
    default = "vmwleucvan201-ip"
}
variable "vmosdisk" {
    type = string
    default = "vmwleucvan201-osdisk"
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
