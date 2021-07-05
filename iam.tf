resource "random_password" "sp" {
  length           = 12
  special          = false
  number           = true
  override_special = "?!#@"
}
resource "azuread_application" "avi" {
  count        = var.create_iam ? 1 : 0
  display_name = "${var.name_prefix}_Avi_Controller"
}
resource "azuread_service_principal" "avi" {
  count          = var.create_iam ? 1 : 0
  application_id = azuread_application.avi[0].application_id
}
resource "azuread_application_password" "avi" {
  application_object_id = azuread_application.avi[0].object_id
  value                 = random_password.sp.result
  end_date_relative     = "4320h"
}
resource "azurerm_role_definition" "custom_controller" {
  count       = var.create_iam ? 1 : 0
  name        = "${var.name_prefix}_Avi_Controller_Role"
  scope       = data.azurerm_subscription.current.id
  description = "Custom Role for Avi Controller."

  permissions {
    actions = [
      "Microsoft.MarketplaceOrdering/offerTypes/publishers/offers/plans/agreements/read",
      "Microsoft.MarketplaceOrdering/offerTypes/publishers/offers/plans/agreements/write",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/checkIpAddressAvailability/read",
      "Microsoft.Network/virtualNetworks/virtualNetworkPeerings/read",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/virtualMachines/read",
      "Microsoft.Network/virtualNetworks/virtualMachines/read",
      "Microsoft.Network/networkInterfaces/join/action",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/ipconfigurations/read",
      "Microsoft.Network/dnsZones/read",
      "Microsoft.Network/dnsZones/A/*",
      "Microsoft.Network/dnsZones/CNAME/*",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/instanceView/read",
      "Microsoft.Compute/virtualMachineScaleSets/read",
      "microsoft.Compute/virtualMachineScaleSets/*/read",
      "Microsoft.Resources/resources/read",
      "Microsoft.Resources/subscriptions/resourcegroups/read",
      "Microsoft.Resources/subscriptions/resourcegroups/resources/read",
      "Microsoft.Compute/virtualMachineScaleSets/read",
      "microsoft.Compute/virtualMachineScaleSets/*/read",
      "Microsoft.Compute/virtualMachineScaleSets/write",
      "microsoft.Compute/virtualMachineScaleSets/delete/action"
    ]
    not_actions = []
  }

  assignable_scopes = [data.azurerm_subscription.current.id]
}
resource "azurerm_role_assignment" "custom_controller" {
  count              = var.create_iam ? 1 : 0
  scope              = data.azurerm_subscription.current.id
  role_definition_id = azurerm_role_definition.custom_controller[0].role_definition_resource_id
  principal_id       = azuread_service_principal.avi[0].object_id
}
resource "azurerm_role_assignment" "contributor" {
  count                = var.create_iam ? 1 : 0
  scope                = azurerm_resource_group.avi[0].id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.avi[0].object_id
}