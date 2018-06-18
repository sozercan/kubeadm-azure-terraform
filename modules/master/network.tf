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
