<#
    .SYNOPSIS
    Enables Transparent Data Encryption on an Azure SQL Database

    .PARAMETER ResourceGroupName
    The name of the resource group where the Azure SQL Database resides

    .PAR
#>

Param(

    #[parameter(Mandatory)]
    [string]
    $ResourceGroupName,

    #[parameter(Mandatory)]
    [string]
    $AzSqlServerName,

    #[parameter(Mandatory)]
    [string]
    $AzSqlDatabaseName,

    #[parameter(mandatory)]
    [string]
    $State
)

$tdeConfig = (Get-AzSqlDatabaseTransparentDataEncryption -ServerName $AzSqlServerName -DatabaseName $AzSqlDatabaseName -ResourceGroupName $ResourceGroupName).State

if ($tdeConfig -ne $State)
{
    Write-Output "Current TDE setting does not match desired state. Setting TDE to $state"
    $result = Set-AzSqlDatabaseTransparentDataEncryption -ServerName $AzSqlServerName -DatabaseName $AzSqlDatabaseName -ResourceGroupName $ResourceGroupName -State $State
} else 
{
    Write-Output "Current TDE setting already matches desired state"
}

