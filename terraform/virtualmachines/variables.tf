variable "azure_subscription_id" {
    type = string
    description = "Subscription id for the deployment"
    default = "d8abb5fd-9d00-48fd-862a-0f778306cce7"
}

variable "azurevm_name" {
    type = string
    description = "Name of the virtual machine to create"
}

variable "azure_region" {
    type = string
    description = "Azure region to use for the deployment"
    default = "usgovvirginia"
}

variable "resource_group_name" {
    type = string
    description = "The name of the resource group to use"
    default = "DEMO-RG"
}

variable "azure_vnet" {
    type = string
    description = "The name of the virtual network that contains the azure_subnet resource"
    default = "EAST-PROD-VNET"
}

variable "azure_vnet_resource_group" {
    type = string
    description = "Name of the resource group for the azure virtual network"
    default = "EAST-PROD-RG"
}

variable "azure_vnet_address_range" {
    type = list
    description = "The address space for the azure virtual network"
    default = ["10.10.0.0/21"]
}

variable "subnet_name" {
    type = string
    description = "The name of the subnet to use for the AKS nodes and pods"
    default = "S-1"
}

variable "subnet_address_range" {
    type = list
    description = "The address space of the azure_subnet resource"
    default = ["10.10.0.0/27"]
}