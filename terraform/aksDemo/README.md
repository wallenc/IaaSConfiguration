
# AKS sample configuration

Use the terraform configurations in this directory to deploy the following:

- Azure Virtual Network and Subnet
- AKS Cluster with Azure Monitor for containers add on
- Azure Container Registry
- Application Insights resource
- Log Analytics workspace with Container Insights solution

Also included in this configuration is a script to convert the App Insights resource to one backed by a Log Analytics workspace since this ability is not provided through the azurerm_application_insights terraform module. This script is called via a Powershell provisioner in a null_resource.

