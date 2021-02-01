# Variables
variable "vmname" {
    type = string
    default = "vmwleucvan102"
}
variable "vmnic" {
    type = string
    default = "vmwleucvan102-nic"
}
variable "vmip" {
    type = string
    default = "vmwleucvan102-ip"
}
variable "vmosdisk" {
    type = string
    default = "vmwleucvan102-osdisk"
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
