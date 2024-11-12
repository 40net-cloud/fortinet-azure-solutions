##############################################################################################################
#
# Azure Container App
# Terraform deployment template for Microsoft Azure
# https://thomasthornton.cloud/2022/09/05/deploying-azure-container-apps-into-your-virtual-network-using-terraform-and-azapi/
#
##############################################################################################################

resource "azurerm_log_analytics_workspace" "loganalytics" {
  name                = "${var.prefix}-loganalytics"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}
	
resource "azapi_resource" "containerapp_environment" {
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  name      = "${var.prefix}-azurecontainerapp-environment"
  parent_id = azurerm_resource_group.resourcegroup.id
  location  = azurerm_resource_group.resourcegroup.location
 
  body = jsonencode({
    properties = {
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = azurerm_log_analytics_workspace.loganalytics.workspace_id
          sharedKey  = azurerm_log_analytics_workspace.loganalytics.primary_shared_key
        }
      }
      vnetConfiguration = {
        internal               = true
        infrastructureSubnetId = azurerm_subnet.subnet3.id
        dockerBridgeCidr       = "10.2.0.1/16"
        platformReservedCidr   = "10.1.0.0/16"
        platformReservedDnsIP  = "10.1.0.2"
      }
    }
  })
  depends_on = [
    azurerm_virtual_network.vnet
  ]
  response_export_values  = ["properties.defaultDomain", "properties.staticIp"]
  ignore_missing_property = true
}

resource "azapi_resource" "containerapp" {
  type      = "Microsoft.App/containerapps@2022-03-01"
  name      = "app01acae"
  parent_id = azurerm_resource_group.resourcegroup.id
  location  = azurerm_resource_group.resourcegroup.location
 
  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.containerapp_environment.id
      configuration = {
        ingress = {
          external : true,
          targetPort : 80
        },
 
      }
      template = {
        containers = [
          {
            image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
            name  = "simple-hello-world-container"
            resources = {
              cpu    = 0.25
              memory = "0.5Gi"
            }
          }
        ]
        scale = {
          minReplicas = 0,
          maxReplicas = 2
        }
      }
    }
 
  })
  depends_on = [
    azapi_resource.containerapp_environment
  ]
}

resource "azurerm_private_dns_zone" "private_dns_zone" {
  name                = jsondecode(azapi_resource.containerapp_environment.output).properties.defaultDomain
  resource_group_name = azurerm_resource_group.resourcegroup.name
  #   depends_on = [
  #     azapi_resource.containerapp_environment
  #   ]
}
 
resource "azurerm_private_dns_zone_virtual_network_link" "vnet_link" {
  name                  = "containerapplink"
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
 
resource "azurerm_private_dns_a_record" "containerapp_record" {
  name                = "app01acae"
  zone_name           = azurerm_private_dns_zone.private_dns_zone.name
  resource_group_name = azurerm_resource_group.resourcegroup.name
  ttl                 = 300
  records             = ["${jsondecode(azapi_resource.containerapp_environment.output).properties.staticIp}"]
 
}