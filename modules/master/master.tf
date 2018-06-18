variable azure {
  type = "map"
}

variable resource_group_name {}
variable "resource_group_id" {}
variable count {}
variable location {}
variable master_ip {}
variable subnet_id {}
variable admin_username {}
variable admin_password {}
variable computer_name {}
variable ssh_key {}
variable master_size {}
variable kubeadm_token {}

variable node_labels {
  type = "list"
}

resource "azurerm_availability_set" "availability_set" {
  name                = "masteras"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  managed             = true
}

resource "azurerm_virtual_machine" "virtual_machine" {
  name                  = "master${count.index}"
  count                 = "${var.count}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(azurerm_network_interface.masternic.*.id, count.index)}"]
  vm_size               = "${var.master_size}"
  availability_set_id   = "${azurerm_availability_set.availability_set.id}"

  # identity {
  #   type = "systemAssigned"
  # }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "master${format("%03d", count.index)}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "${var.computer_name}${count.index}"
    admin_username = "${var.admin_username}"
    admin_password = "${var.admin_password}"
    custom_data    = "${data.template_file.cloud-config.rendered}"
  }
  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.ssh_key}")}"
    }
  }
}

# resource "azurerm_virtual_machine_extension" "virtual_machine_extension" {
#   name                       = "master${count.index}-msi"
#   count                      = "${var.count}"
#   location                   = "${var.location}"
#   resource_group_name        = "${var.resource_group_name}"
#   virtual_machine_name       = "${element(azurerm_virtual_machine.virtual_machine.*.name, count.index)}"
#   auto_upgrade_minor_version = true
#   publisher                  = "Microsoft.ManagedIdentity"
#   type                       = "ManagedIdentityExtensionForLinux"
#   type_handler_version       = "1.0"

#   settings = <<SETTINGS
#     {
#         "port": 50342
#     }
# SETTINGS
# }

# data "azurerm_subscription" "subscription" {}

# # Grant the VM identity contributor rights to the current subscription
# resource "azurerm_role_assignment" "role_assignment" {
#   scope                = "${var.resource_group_id}"
#   role_definition_name = "Contributor"
#   principal_id         = "${lookup(azurerm_virtual_machine.virtual_machine.identity[0], "principal_id")}"

#   lifecycle {
#     ignore_changes = ["name"]
#   }
# }

data "template_file" "cloud-config" {
  template = "${file("${path.root}/bootstrap/bootstrap.sh")}"

  vars {
    SUBSCRIPTION_ID = "${var.azure["subscription_id"]}"
    TENANT_ID       = "${var.azure["tenant_id"]}"
    CLIENT_ID       = "${var.azure["client_id"]}"
    CLIENT_SECRET   = "${var.azure["client_secret"]}"
    LOCATION        = "${var.location}"
    RESOURCE_GROUP  = "${var.resource_group_name}"
    master_ip       = "${var.master_ip}"
    node_labels     = "${join(",", var.node_labels)}"
    admin_username  = "${var.admin_username}"
    kubeadm_token   = "${var.kubeadm_token}"
  }
}

output "local_ip_v4" {
  value = ["${azurerm_network_interface.masternic.*.private_ip_address}"]
}
