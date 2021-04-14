resource "azurerm_virtual_network_peering" "peering-a-b" {
  name                      = "peerAtoB"
  resource_group_name       = azurerm_resource_group.resourcegroupa.name
  virtual_network_name      = azurerm_virtual_network.vneta.name
  remote_virtual_network_id = azurerm_virtual_network.vnetb.id
}

resource "azurerm_virtual_network_peering" "peering-b-a" {
  name                      = "peerBtoA"
  resource_group_name       = azurerm_resource_group.resourcegroupb.name
  virtual_network_name      = azurerm_virtual_network.vnetb.name
  remote_virtual_network_id = azurerm_virtual_network.vneta.id
}