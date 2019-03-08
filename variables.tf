#------------------------------------------------------------------------------
# REQUIRED
#------------------------------------------------------------------------------

variable "location" {
  description = "The Azure Region where the VMs will be created"
}

variable "resource_group_name" {
  description = "The Resource group that will contain the instances"
}

variable "subnet_ids" {
  description = "A list of subnets where the VMs will be created"
  type        = "list"
}

#------------------------------------------------------------------------------
# OPTIONAL
#------------------------------------------------------------------------------

variable "instance_count" {
  description = "Number of instances to launch"
  default     = 3
}

variable "name" {
  description = "The name prefix for all created resources"
  default     = "rancher"
}

variable "enable_public_endpoint" {
  description = "Create and attached a VIP to the VMs primary network interface"
  default     = true
}

variable "zones" {
  description = "List of availability zones where VMs will be distributed. Set to any empty list to disable."
  default     = ["1", "2", "3"]
}

variable "network_security_group_id" {
  description = "Attach a network security group directoy to the NIC on all VMs. Disabled when value is empty."
  default     = ""
}

variable "vm_size" {
  description = "The virtual machine size for the VMs"
  default     = "Standard_B4ms"
}

variable "vm_os_supported" {
  description = "Specify UbuntuServer, CentOS or RHEL. Set this to empty string in order to provide custom values via vm_os_publisher, vm_os_offer, and vm_os_sku."
  default     = "UbuntuServer"
}

variable "vm_os_publisher" {
  description = "The name of the publisher of the image that you want to deploy. This is ignored when vm_os_simple is provided."
  default     = ""
}

variable "vm_os_offer" {
  description = "The name of the image offer that you want to deploy. This is ignored when vm_os_simple is provided."
  default     = ""
}

variable "vm_os_sku" {
  description = "The sku of the image that you want to deploy. This is ignored when vm_os_simple is provided."
  default     = ""
}

variable "vm_os_version" {
  description = "The version of the image that you want to deploy."
  default     = "latest"
}

variable "os_disk_type" {
  description = "The root partition disk type"
  default     = "Standard_LRS"
}

variable "os_disk_size_gb" {
  description = "The root partition disk size. This value cannot be smaller than the os image default."
  default     = 30
}

variable "delete_os_disk_on_termination" {
  description = "Indicates the managed root disk should be delete when the VMs are terminated"
  default     = true
}

variable "data_disk_size_gb" {
  description = "The data partition disk type"
  default     = 10
}

variable "data_disk_type" {
  description = "The data partition disk size"
  default     = "Standard_LRS"
}

variable "delete_data_disks_on_termination" {
  description = "Indicates the managed data disk should be delete when the VMs are terminated"
  default     = true
}

variable "admin_username" {
  description = "The name of the local administrator on the VMs"
  default     = "rancher-admin"
}

variable "ssh_public_key" {
  description = "Path to the SSH public key that will be installed on the VMs. Password authentication is NOT enabled."
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_private_key" {
  description = "Path to the SSH private key that will be used to connect to the VMs"
  default     = "~/.ssh/id_rsa"
}

variable "ranchhand_distro" {
  description = "Platform where RanchHand binary will be executed. Specify linux or darwnin."
  default     = "linux"
}

variable "ranchhand_release" {
  description = "Specify the RanchHand release version to use. Check https://github.com/dominodatalab/ranchhand/releases for a list of available releases."
  default     = "0.1.0-rc4"
}

variable "tags" {
  description = "A mapping of tags to assign to the resource"
  default     = {}
}
