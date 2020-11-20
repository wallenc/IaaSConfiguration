
<#
    .SYNOPSIS
        Enables transparent data encryption for Azure SQL Databases

    .DESCRIPTION
        This script will enable transparent data encryption for Azure SQL Databases in
        specified Azure SQL Servers, resource groups, or an entire subscription

    .PARAMETER azureSubscriptionID
        ID of Azure subscription to use

    .PARAMETER azureEnvironment
        The Azure Cloud environment to use, i.e. AzureCloud, AzureUSGovernment

    .PARAMETER AzureSqlServerNames
        List of one or more Azure SQL Servers for which to enable TDE on owned databases

    .PARAMETER AzureSqlDbNames
        List of one or more Azure SQL databases for which to enable TDE

    .PARAMETER ResourceGroupNames
        List of Resource Groups. Storage accounts in the listed resource groups
        will have secure transfer required enabled

    .NOTES
        Version:        1.1
        Author:         Chris Wallen
        Creation Date:  05/19/2020
#>

Param
(
    [parameter(mandatory)]
    [string]
    $AzureSubscriptionId,

    [parameter(mandatory)]
    [string]
    $AzureEnvironment,

    [string[]]
    $AzureSqlServerNames,

    [string[]]
    $AzureSqlDbNames,

    [string[]]
    $ResourceGroupNames
)

$azContext = Set-AzContext -subscription $AzureSubscriptionId

$azSqlServers = @()
$azSqlDatabases = @()

if ($AzureSqlDbNames)
{
    $dbResource = @()
    foreach ($database in $AzureSqlDbNames)
    {
        if ($database -notlike '*master')
        {
            Write-Output "Collecting database: $($database)"
            $dbResource += Get-AzResource -ResourceType 'Microsoft.Sql/servers/databases' | where { $_.Name -match "$($database)" }

            #Check to make sure we found a database and there aren't any duplicates
            if ($dbResource.Count -lt 1)
            {
                Write-Error -Message "Failed to find $database"
            }
            elseif ($dbResource.Count -gt 1)
            {
                Write-Error -Message "Found multiple databases with the name $database. Unable to configure TDE"
            }
            else
            {
                $azSqlDatabases += Get-AzSqlDatabase -ServerName $dbResource.name.Substring(0, $dbResource.Name.IndexOf('/')) `
                    -ResourceGroupName $dbResource.ResourceGroupName | where { $_.DatabaseName -ne 'master' }
            }
        }
    }
}
elseif ($AzureSqlServerNames -and -not $AzureSqlDbNames)
{
    foreach ($server in $AzureSqlServerNames)
    {
        Write-Output "Collecting databases from server: $server"

        $azSqlServers += Get-AzResource -ResourceType 'Microsoft.Sql/servers' -Name $server
        $azSqlDatabases += Get-AzSqlDatabase -ServerName $server -ResourceGroupName $azSqlServers[-1].ResourceGroupName `
        | where { $_.DatabaseName -ne 'master' }
    }
}
elseif ($ResourceGroupNames -and -not $AzureSqlServerNames -and -not $AzureSqlDbNames)
{
    $dbResource = @()

    foreach ($resourceGroup in $ResourceGroupNames)
    {
        Write-Output "Finding databases in resource group: $($resourceGroup)"

        $dbresource += Get-AzResource -ResourceType 'Microsoft.Sql/servers/databases' `
            -ResourceGroupName $resourceGroup | where { $_.Name -notlike '*master' }
    }

    foreach ($resource in $dbresource)
    {
        Write-Output "Collecting database: $($resource.name.Substring(0, $resource.Name.IndexOf('/')))"
        $azSqlDatabases += Get-AzSqlDatabase -ServerName $resource.name.Substring(0, $resource.Name.IndexOf('/')) `
            -ResourceGroupName $resource.ResourceGroupName | where { $_.DatabaseName -ne 'master' }
    }
}
else
{
    Write-Output "Collecting all databases"
    $azSqlServers = Get-AzResource -ResourceType 'Microsoft.Sql/servers'

    foreach ($sqlServer in $azSqlServers)
    {
        $azSqlDatabases += Get-AzSqlDatabase -ServerName $sqlServer.Name -ResourceGroupName $sqlServer.ResourceGroupName `
        | where { $_.DatabaseName -ne 'master' }
    }
}

foreach ($sqlDatabase in $azSqlDatabases)
{
    #Check to see if TDE is enabled
    $tdeEnabledState = (Get-AzSqlDatabaseTransparentDataEncryption -ServerName $sqlDatabase.ServerName `
            -ResourceGroupName $sqlDatabase.ResourceGroupName -DatabaseName $sqlDatabase.DatabaseName).State

    #Enable TDE if it's disabled
    if ($tdeEnabledState -eq 'Disabled')
    {
        Write-Output "Enabling TDE on: $($sqlDatabase.DatabaseName)"
        Set-AzSqlDatabaseTransparentDataEncryption -ServerName $sqlDatabase.ServerName `
            -ResourceGroupName $sqlDatabase.ResourceGroupName -DatabaseName $sqlDatabase.DatabaseName -State 'Enabled'
    }
}