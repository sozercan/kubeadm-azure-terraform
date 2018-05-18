provider "azurerm" {
  subscription_id = "${var.azure["subscription_id"]}"
  client_id       = "${var.azure["client_id"]}"
  client_secret   = "${var.azure["client_secret"]}"
  tenant_id       = "${var.azure["tenant_id"]}"
}

module "resource_group" {
  source = "./modules/resource_group"

  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

module "network" {
  source = "./modules/network"

  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
}

module "master" {
  source = "./modules/master"

  location            = "${var.location}"
  count               = "${var.master_count}"
  resource_group_name = "${var.resource_group_name}"
  subnet_id           = "${module.network.subnet_id}"
  master_ip           = ""
  azure               = "${var.azure}"
  admin_username      = "${var.admin_username}"
  admin_password      = "${var.admin_password}"
  ssh_key             = "${var.ssh_key}"
  master_size         = "${var.master_size}"
  node_labels         = ["role=master"]
  kubeadm_token       = "${var.kubeadm_token}"
  computer_name       = "${var.master_computer_name}"
}

module "node" {
  source = "./modules/node"

  location             = "${var.location}"
  resource_group_name  = "${var.resource_group_name}"
  subnet_id            = "${module.network.subnet_id}"
  master_ip            = "${element(module.master.local_ip_v4, 0)}"
  count                = "${var.node_count}"
  azure                = "${var.azure}"
  admin_username       = "${var.admin_username}"
  admin_password       = "${var.admin_password}"
  ssh_key              = "${var.ssh_key}"
  node_size            = "${var.node_size}"
  computer_name_prefix = "${var.node_computer_name_prefix}"
  node_labels          = ["role=node"]
  kubeadm_token        = "${var.kubeadm_token}"
}
