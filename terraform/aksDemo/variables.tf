variable "azure_subscription_id" {
    type = string
    description = "Subscription id for the deployment"
    default = "d8abb5fd-9d00-48fd-862a-0f778306cce7"
}
variable "azure_region" {
    type = string
    description = "Azure region to use for the deployment"
    default = "usgovvirginia"
}

variable "aks_cluster_name" {
    type = string
    description = "Name of the AKS cluster resource"
    default = "demoAKS"
}

variable "aks_resource_group" {
    type = string
    description = "The name of the resource group to deploy AKS"
    default = "demoAKS-RG"
}

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
    default = "AKS-NODE-RG"
}

variable "aks_dns_prefix" {
    type = string
    description = "DNS prefix to use for the AKS deployment"
    default = "demoaks"
}

variable "log_analytics_name" {
    type = string
    description = "The name of the log analytics workspace"
    default = "aksDemoLogA"
}

variable "log_analytics_resource_group" {
    type = string
    description = "The name of the resource group for the log analytics workspace"
    default = "demoAKS-RG"
}

variable "azure_vnet" {
    type = string
    description = "The name of the virtual network that contains the azure_subnet resource"
    default = "aksVnet"
}

variable "azure_vnet_resource_group" {
    type = string
    description = "Name of the resource group for the azure virtual network"
    default = "demoAKS-RG"
}

variable "azure_vnet_address_range" {
    type = list(string)
    description = "The address space for the azure virtual network"
    default = ["172.16.0.0/16"]
}

variable "azure_subnet" {
    type = string
    description = "The name of the subnet to use for the AKS nodes and pods"
    default = "aksSubnet"
}

variable "subnet_address_range" {
    type = list(string)
    description = "The address space of the azure_subnet resource"
    default = ["172.16.1.0/24"]
}

