variable resource_group_name {}
variable location {}

resource "azurerm_resource_group" "resource_group" {
  name     = "${var.resource_group_name}"
  location = "${var.location}"
}

output "resource_group_id" {
  value = "${azurerm_resource_group.resource_group.id}"
}
