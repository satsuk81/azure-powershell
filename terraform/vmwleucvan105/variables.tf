# Variables
variable "vmname" {
    type = string
    default = "vmwleucvan105"
}
variable "vmnic" {
    type = string
    default = "vmwleucvan105-nic"
}
variable "vmip" {
    type = string
    default = "vmwleucvan105-ip"
}
variable "vmosdisk" {
    type = string
    default = "vmwleucvan105-osdisk"
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
