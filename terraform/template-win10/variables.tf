# Variables
variable "vmname" {
    type = string
    default = "xxxx"
}
variable "vmnic" {
    type = string
    default = "xxxx-nic"
}
variable "vmip" {
    type = string
    default = "xxxx-ip"
}
variable "vmosdisk" {
    type = string
    default = "xxxx-osdisk"
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
