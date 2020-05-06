
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

    .PARAMETER azureStorageAccounts
        List of one or more storage accounts to set secure transfered required

    .PARAMETER ResourceGroupNames
        List of Resource Groups. Storage accounts in the listed resource groups
        will have secure transfer required enabled

    .PARAMETER VMNames
        List of VMs to install OMS extension to
        Specified in the format ['vmname1','vmname2']

    .NOTES
        Version:        1.0
        Author:         Chris Wallen
        Creation Date:  04/30/2020
#>

Param
(
    #[parameter(mandatory)]
    [string]
    $AzureSubscriptionId = 'd8abb5fd-9d00-48fd-862a-0f778306cce7',

    #[parameter(mandatory)]
    [string]
    $AzureEnvironment = 'AzureUSGovernment',

    [string[]]
    $SqlServerNames,

    [string[]]
    $SqlDbNames,

    [string[]]
    $ResourceGroupNames
)

Clear-Variable -Name SqlServerNames
Clear-Variable -Name SqlDBNames
Clear-Variable -Name ResourceGroupNames
Clear-Variable -Name azSqlDatabases

$SqlServerNames = "prodsqlserver"

$ResourceGroupNames = "dynatrace-poc"

$SqlDbNames = 'proddb', 'master'

$azSqlServers = @()
$azSqlDatabases = @()

if ($SqlDbNames)
{    
    $dbResource = @()
    foreach ($database in $SqlDbNames)
    {
        $dbResource += Get-AzResource -ResourceType 'Microsoft.Sql/servers/databases' | where { $_.Name -match "$database" }

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
            foreach($resource in $dbResource)
            {
                $azSqlDatabases += Get-AzSqlDatabase -ServerName $server -ResourceGroupName $azSqlServers[-1].ResourceGroupName
            }
            
        }
    }
}
elseif ($SqlServerNames -and -not $SqlDbNames)
{
    foreach ($server in $SqlServerNames)
    {
        $azSqlServers += Get-AzResource -ResourceType 'Microsoft.Sql/servers' -Name $server
        $azSqlDatabases += Get-AzSqlDatabase -ServerName $server -ResourceGroupName $azSqlServers[-1].ResourceGroupName
    }
}
elseif (($ResourceGroupNames) -and -not $SqlServernames -and -not $SqlDBNames)
{
    foreach ($resourceGroup in $ResourceGroupNames)
    {
        $azSqlDatabases += Get-AzResource -ResourceType 'Microsoft.Sql/servers/databases' -ResourceGroupName $resourceGroup
    }
}
else
{
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