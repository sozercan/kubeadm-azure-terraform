variable resource_group_name {}
variable location {}

# create virtual network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet"
  address_space       = ["10.0.0.0/16"]
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

# create subnet
resource "azurerm_subnet" "subnet" {
  name                      = "subnet"
  resource_group_name       = "${var.resource_group_name}"
  virtual_network_name      = "${azurerm_virtual_network.vnet.name}"
  address_prefix            = "10.0.2.0/24"
  network_security_group_id = "${azurerm_network_security_group.nsg.id}"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"

  security_rule {
    name                       = "ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_route_table" "routetable" {
  name                = "routetable"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

output "subnet_id" {
  value = "${azurerm_subnet.subnet.id}"
}
