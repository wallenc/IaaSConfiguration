variable "azure_subscription_id" {
    type = string
    description = "Subscription id for the deployment"        
}

variable "azure_region" {
    type = string
    description = "Azure region to use for the deployment"
    default = "usgovvirginia"
}

variable "app_gateway_name" {
    type = string
    description = "The name of the application gateway"
    default = "aks-demo-appgw"
}

variable "aks_cluster_name" {
    type = string
    description = "Name of the AKS cluster resource"
    default = "demoAKS"
}

# variable "resource_group_name" {
#     type = string
#     description = "The name of the resource group to use"
#     default = "AKS-DEMO-SOUTH"
# }

variable "aks_node_pool_name" {
    type = string
    description = "Name of the node pool for the AKS nodes"
    default = "default"
}

variable "aks_node_count" {
    type = number
    description = "Number of nodes in the default node pool"
    default = 2
}

variable "aks_node_size" {
    type = string
    description = "The Azure VM size to use for the nodes"
    default = "Standard_B2ms"
}

variable "aks_node_resource_group" {
    type = string
    description = "Name of the resource group to create for the nodes. This RG must not currently exist"
    default = "DEMOAKS-NODE-RG"
}

variable "aks_dns_prefix" {
    type = string
    description = "DNS prefix to use for the AKS deployment"
    default = "demoaks"
}

variable "log_analytics_name" {
    type = string
    description = "The name of the log analytics workspace"
    default = "demoAksLogA"
}

variable "azure_vnet" {
    type = string
    description = "The name of the virtual network that contains the azure_subnet resource"
    default = "demoAksVnet"
}

variable "azure_vnet_resource_group" {
    type = string
    description = "Name of the resource group for the azure virtual network"
    default = "demoAKS-RG"
}

variable "azure_vnet_address_range" {
    type = list(string)
    description = "The address space for the azure virtual network"
    default = ["10.4.0.0/16"]
}

variable "aks_subnet" {
    type = string
    description = "The name of the subnet to use for the AKS nodes and pods"
    default = "aks-subnet"
}

variable "appgw_subnet" {
    type = string
    description = "The name of the subnet to use for the AKS nodes and pods"
    default = "appgw-subnet"
}

variable "aks_subnet_address_range" {
    type = list(string)
    description = "The address space of the azure_subnet resource"
    default = ["10.4.0.0/25"]
}

variable "appgw_subnet_address_range" {
    type = list(string)
    description = "The address space of the azure_subnet resource"
    default = ["10.4.1.0/27"]
}

variable "container_registry_name" {
    type = string
    description = "Name of the container registry to use"
    default = "demoAksRegistry"
}

