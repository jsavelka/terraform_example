# Generate a unique id for app name
resource "random_uuid" "server" {
}
# Configure the provider
provider "azurerm" {
  version = "=1.32.0"
}
# Create a new resource group
resource "azurerm_resource_group" "main" {
  name     = "tf_web_app_monitor"
  location = "eastus"
}
# Create an azure app service plan
resource "azurerm_app_service_plan" "main" {
  name                = "tf_web_app_monitor_plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "Linux"
  reserved            = true
  sku {
    tier = "Standard"
    size = "S1"
  }
}
# Create the azure app service resource
resource "azurerm_app_service" "main" {
  name                = random_uuid.server.result
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id
  site_config {
    default_documents = ["index.html"]
  }
}
# Configure an autoscale setting
#
# Hint: You can find sample configurations and the documents of the attributes at:
# https://www.terraform.io/docs/providers/azurerm/r/monitor_autoscale_setting.html
resource "azurerm_monitor_autoscale_setting" "main" {
  name                = "tf_web_app_autoscale_setting"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  # TODO 1:
  # Specify the target_resource_id as the id of the azure App Service plan defined as
  # resource "azurerm_app_service_plan" "main" (NOT azurerm_app_service)
  #
  # Recall the practice in Task 1: an autoscale setting is associated with
  # an App Service plan, not the App Service
  target_resource_id = "azurerm_app_service_plan"
  profile {
    name = "defaultProfile"
    # TODO 2:
    # Add limitations to the capacity block:
    # default as 1,
    # minimum as 1,
    # maximum as 2.
    #
    # Please refer to:
    # https://www.terraform.io/docs/providers/azurerm/r/monitor_autoscale_setting.html#capacity
    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }
    # TODO 3:
    # Complete the scale-out rule which is already outlined in this configuration:
    # * Specify the metric_resource_id as the id of azurerm_app_service (NOT azurerm_app_service_plan).
    # * Configure the operator and the threshold so that the rule would be triggered
    # when the average number of requests is greater than 10,
    # * Set the direction and value parameters in the scale_action block to define
    # the action as increase the count by one.
    # Please refer to:
    # https://www.terraform.io/docs/providers/azurerm/r/monitor_autoscale_setting.html#metric_trigger
    # https://www.terraform.io/docs/providers/azurerm/r/monitor_autoscale_setting.html#scale_action
    rule {
      metric_trigger {
        metric_name        = "Requests"
        metric_resource_id = "azurerm_app_service"
        time_grain         = "PT5M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = "10"
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT3M"
      }
    }
  
    # TODO 4:
    # Add another scale-in rule based on the scale-out rule, which is to decrease
    # the number by one when the average number of requests received by the app
    # service plan is less than 5.
    #
    # Refer to the scale-out rule above as the example
    rule {
      metric_trigger {
        metric_name        = "Requests"
        metric_resource_id = "azurerm_app_service"
        time_grain         = "PT5M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = "10"
      }
      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT3M"
      }
    }
  }
}
# Print the ID of the web app
output "web_app_id" {
  value = "${azurerm_app_service.main.id}"
}
# Print the URL of the web app
output "web_app_url" {
  value = "https://${azurerm_app_service.main.default_site_hostname}"
}
# Print the ID of the autoscale setting
output "autoscale_id" {
  value = "${azurerm_monitor_autoscale_setting.main.id}"
}
