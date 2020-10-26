<#
    .SYNOPSIS
    This script migrates a classic Azure Application Insights resource to workspace-based

    .PARAMETER AzureSubscriptionId
    The subscription id to use

    .PARAMETER AppInsightsWorkspaceName
    The name of the Application Insights resource to migrate

    .PARAMETER AppInsightsResourceGroupName
    The resource group where the Application Insights resource lives

    .PARAMETER LogAnalyticsWorkspaceName
    The name of the log analytics workspace to use for the application insights resource

    .PARAMETER LogAnalyticsResourceGroupName
    The resource group where the log analytics workspace lives
#>


Param (

    [parameter(mandatory)]
    [string]
    $AzureSubscriptionId,

    [parameter(mandatory)]
    [string]
    $AppInsightsWorkspaceName,

    [parameter(mandatory)]
    [string]
    $AppInsightsResourceGroupName,

    [parameter(mandatory)]
    [string]
    $LogAnalyticsWorkspaceName,

    [parameter(mandatory)]
    [string]
    $LogAnalyticsResourceGroupName

)

$azContext = Set-AzContext -Subscription $AzureSubscriptionId

$LogAnalyticsWorkspace = Get-AzOperationalInsightsWorkspace -Name $LogAnalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroupName

if ($LogAnalyticsWorkspace)
{
    $result = & az monitor app-insights component update --app $AppInsightsWorkspaceName -g $AppInsightsResourceGroupName --workspace $LogAnalyticsWorkspace.ResourceId
}
else
{
    throw "Failed to find log analytics workspace $($LogAnalyticsWorkspaceName) in resource group $($LogAnalyticsResourceGroupName)"
}

