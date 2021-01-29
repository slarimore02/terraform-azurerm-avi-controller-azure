# Create VNET and Subnets for AVI Controller and SEs
resource "azurerm_virtual_network" "avi" {
  count               = var.create_networking ? 1 : 0
  name                = "${var.name_prefix}-avi-vnet"
  address_space       = [var.avi_cidr_block]
  location            = var.region
  resource_group_name = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_se_resource_group
}

resource "azurerm_subnet" "avi" {
  count                = var.create_networking ? 1 : 0
  name                 = "${var.name_prefix}-avi-subnet"
  resource_group_name  = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_se_resource_group
  virtual_network_name = azurerm_virtual_network.avi[0].name
  address_prefixes     = [cidrsubnet(azurerm_virtual_network.avi[0].address_space, 8, 230 + count.index)]
}

resource "azurerm_public_ip" "avi" {
  count               = var.controller_ha ? 3 : 1
  name                = "${var.name_prefix}-avi-controller-pip"
  resource_group_name = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_se_resource_group
  location            = var.region
  allocation_method   = "Dynamic"
}
resource "azurerm_network_interface" "avi" {
  count               = var.controller_ha ? 3 : 1
  name                = "${var.name_prefix}-avi-controller-nic"
  location            = var.region
  resource_group_name = var.create_resource_group ? azurerm_resource_group.avi[0].name : var.custom_se_resource_group

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.create_networking ? azurerm_subnet.avi[0].id : var.custom_subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.avi[count.index].id
  }
}