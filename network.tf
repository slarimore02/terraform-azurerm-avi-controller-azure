# Create VNET and Subnets for AVI Controller and SEs
resource "azurerm_virtual_network" "avi" {
  count               = var.create_networking ? 1 : 0
  name                = "${var.name_prefix}-avi-vnet-${var.region}"
  address_space       = [var.vnet_address_space]
  location            = var.region
  resource_group_name = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_se_resource_group
}

resource "azurerm_subnet" "avi" {
  count                = var.create_networking ? 1 : 0
  name                 = "${var.name_prefix}-avi-subnet"
  resource_group_name  = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_se_resource_group
  virtual_network_name = azurerm_virtual_network.avi[0].name
  address_prefixes     = [var.avi_subnet]
}

resource "azurerm_public_ip" "avi" {
  count               = var.controller_ha ? 3 : 1
  name                = "${var.name_prefix}-avi-controller-pip-${count.index + 1}"
  resource_group_name = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_se_resource_group
  location            = var.region
  allocation_method   = "Static"
}
resource "azurerm_network_interface" "avi" {
  count               = var.controller_ha ? 3 : 1
  name                = "${var.name_prefix}-avi-controller-nic-${count.index + 1}"
  location            = var.region
  resource_group_name = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_se_resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.create_networking ? azurerm_subnet.avi[0].id : data.azurerm_subnet.custom[0].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.avi[count.index].id
  }
}
resource "azurerm_virtual_network_peering" "avi" {
  count                     = var.create_vnet_peering ? 1 : 0
  name                      = "avi_vnet_peering"
  resource_group_name       = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_controller_resource_group
  virtual_network_name      = azurerm_virtual_network.avi[0].name
  remote_virtual_network_id = data.azurerm_virtual_network.peer[0].id
  allow_gateway_transit     = false
  allow_forwarded_traffic   = true
}