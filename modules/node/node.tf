variable azure {
  type = "map"
}

variable resource_group_name {}
variable location {}
variable master_ip {}
variable subnet_id {}
variable count {}
variable admin_username {}
variable admin_password {}
variable ssh_key {}
variable node_size {}
variable computer_name_prefix {}
variable kubeadm_token {}

variable node_labels {
  type = "list"
}

resource "azurerm_virtual_machine_scale_set" "vmss" {
  name                = "node${count.index}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  upgrade_policy_mode = "Manual"

  sku {
    name     = "${var.node_size}"
    tier     = "Standard"
    capacity = "${var.count}"
  }

  storage_profile_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_profile_os_disk {
    name              = ""
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name_prefix = "${var.computer_name_prefix}${ count.index}"
    admin_username       = "${var.admin_username}"
    admin_password       = "${var.admin_password}"

    custom_data = "${element(data.template_file.cloud-config.*.rendered, count.index)}"
  }

  os_profile_linux_config {
    disable_password_authentication = false

    ssh_keys {
      path     = "/home/${var.admin_username}/.ssh/authorized_keys"
      key_data = "${file("${var.ssh_key}")}"
    }
  }

  network_profile {
    name    = "networkprofile"
    primary = true

    ip_configuration {
      name      = "IPConfiguration"
      subnet_id = "${var.subnet_id}"
    }
  }
}

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
