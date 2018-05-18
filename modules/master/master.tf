variable azure {
  type = "map"
}

variable resource_group_name {}
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

resource "azurerm_network_interface" "masternic" {
  name                = "masternic${count.index}"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  count               = "${var.count}"

  ip_configuration {
    name                                    = "ipconfiguration${count.index}"
    subnet_id                               = "${var.subnet_id}"
    private_ip_address_allocation           = "dynamic"
    load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.backend_pool.*.id}"]
    load_balancer_inbound_nat_rules_ids     = ["${element(azurerm_lb_nat_rule.ssh.*.id, count.index)}"]
  }
}

resource "azurerm_public_ip" "masterpip" {
  name                         = "masterpip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "Static"
  domain_name_label            = "${var.resource_group_name}"
}

resource "azurerm_lb" "masterlb" {
  name                = "masterlb"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = "${azurerm_public_ip.masterpip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.masterlb.id}"
  name                = "BackEndAddressPool"
}

resource "azurerm_lb_nat_rule" "ssh" {
  resource_group_name            = "${var.resource_group_name}"
  count                          = "${var.count}"
  loadbalancer_id                = "${azurerm_lb.masterlb.id}"
  name                           = "SSH${count.index}"
  protocol                       = "Tcp"
  frontend_port                  = "${22 + count.index}"
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
}

resource "azurerm_virtual_machine" "mastervm" {
  name                  = "master${count.index}"
  count                 = "${var.count}"
  location              = "${var.location}"
  resource_group_name   = "${var.resource_group_name}"
  network_interface_ids = ["${element(azurerm_network_interface.masternic.*.id, count.index)}"]
  vm_size               = "${var.master_size}"
  availability_set_id   = "${azurerm_availability_set.availability_set.id}"

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
