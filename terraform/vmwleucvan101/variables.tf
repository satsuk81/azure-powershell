# Variables
variable "vmname" {
    type = string
    default = "vmwleucvan101"
}
variable "vmnic" {
    type = string
    default = "vmwleucvan101-nic"
}
variable "vmip" {
    type = string
    default = "vmwleucvan101-ip"
}
variable "vmosdisk" {
    type = string
    default = "vmwleucvan101-osdisk"
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
