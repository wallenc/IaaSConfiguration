
<#
    .SYNOPSIS
        Enables Secure Transfer Required for Storage Accounts

    .DESCRIPTION
        This script will set secure transfer required to true for all storage accounts in
        specified resource groups or for an entire subscription

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

    .PARAMETER VMNames
        List of VMs to install OMS extension to
        Specified in the format ['vmname1','vmname2']

    .NOTES
        Version:        1.0
        Author:         Chris Wallen
        Creation Date:  05/11/2020
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
            $dbResource += Get-AzResource -ResourceType 'Microsoft.Sql/servers/databases' | where { $_.Name -match "$database" }

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
                foreach ($resource in $dbResource)
                {
                    $azSqlDatabases += Get-AzSqlDatabase -ServerName $server -ResourceGroupName $azSqlServers[-1].ResourceGroupName
                }

            }
        }
    }
}
elseif ($AzureSqlServerNames -and -not $AzureSqlDbNames)
{
    foreach ($server in $AzureSqlServerNames)
    {
        $azSqlServers += Get-AzResource -ResourceType 'Microsoft.Sql/servers' -Name $server
        $azSqlDatabases += Get-AzSqlDatabase -ServerName $server -ResourceGroupName $azSqlServers[-1].ResourceGroupName
    }
}
elseif ($ResourceGroupNames -and -not $AzureSqlServerNames -and -not $AzureSqlDbNames)
{
    foreach ($resourceGroup in $ResourceGroupNames)
    {
        $azSqlDatabases += Get-AzResource -ResourceType 'Microsoft.Sql/servers/databases' -ResourceGroupName $resourceGroup
    }
}
else
{
    Write-Output "Collecting all databases"
    $azSqlServers = Get-AzResource -ResourceType 'Microsoft.Sql/servers'

    foreach ($sqlServer in $azSqlServers)
    {
        $azSqlDatabases += Get-AzSqlDatabase -ServerName $sqlServer.Name -ResourceGroupName $sqlServer.ResourceGroupName
    }
}


foreach ($sqlDatabase in $azSqlDatabases)
{
    $tdeEnabledState = (Get-AzSqlDatabaseTransparentDataEncryption -ServerName $sqlDatabase.ServerName -ResourceGroupName $sqlDatabase.ResourceGroupName -DatabaseName $sqlDatabase.DatabaseName).State

    if ($tdeEnabledState -eq 'Disabled')
    {
        Set-AzSqlDatabaseTransparentDataEncryption -ServerName $sqlDatabase.ServerName -ResourceGroupName $sqlDatabase.ResourceGroupName -DatabaseName $sqlDatabase.DatabaseName -State 'Enabled'
    }
}