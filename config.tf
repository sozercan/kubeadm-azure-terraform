variable "azure" {
  default = {
    subscription_id = ""
    client_id       = ""
    client_secret   = ""
    tenant_id       = ""
  }
}

variable "resource_group_name" {
  description = "The name of the resource group in which the resources will be created"
  default     = ""
}

variable "location" {
  description = "The location where the resources will be created"
  default     = ""
}

variable "master_size" {
  default     = "Standard_DS2_v2"
  description = "Size of the Virtual Machine based on Azure sizing"
}

variable "node_size" {
  default     = "Standard_DS2_v2"
  description = "Size of the Virtual Machine based on Azure sizing"
}

variable "managed_disk_type" {
  default     = "Standard_LRS"
  description = "Type of managed disk for the VMs that will be part of this compute group. Allowable values are 'Standard_LRS' or 'Premium_LRS'."
}

variable "data_disk_size" {
  description = "Specify the size in GB of the data disk"
  default     = "10"
}

variable "admin_username" {
  description = "Admin username"
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password"
  default     = "P@ssw0rd123!"
}

variable "ssh_key" {
  description = "Path to the public key to be used for ssh access to the VM"
  default     = "~/.ssh/id_rsa.pub"
}

variable "master_count" {
  description = "Specify the number of vm instances for masters"
  default     = "1"
}

variable "node_count" {
  description = "Specify the number of vmss instances for nodes"
  default     = "1"
}

variable "node_labels" {
  default = ""
}

variable "kubeadm_token" {
  description = "Token for Kubeadm"
}

variable "node_computer_name_prefix" {
  default = "node"
}

variable "master_computer_name" {
  default = "master"
}
