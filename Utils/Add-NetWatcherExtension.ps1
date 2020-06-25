<#
    .SYNOPSIS
    This script deploys the Network Watcher extension to one or more virtual machines
    in the same resource group

    .PARAMETER VMNames
    List of VMs to deploy the network watcher extension to

    .PARAMETER ResourceGroupName
    The name of the resource group that contains the list of VMs

    .NOTES
        Version:        1.0
        Author:         Chris Wallen
        Creation Date:  06/18/2020
#>

param
(
    [parameter(Mandatory)]
    [string[]]
    $VMNames,

    [parameter(Mandatory)]
    [string]
    $ResourceGroupName
)

$vms = @()

foreach ($VMName in $VMNames)
{
    $azureResource = Get-AzureRmResource -Name $VMName -ResourceType 'Microsoft.Compute/virtualMachines'

    if ($azureResource.Count -lt 1)
    {
        Write-Error -Message "Failed to find $VMName"
    }
    elseif ($azureResource.Count -gt 1)
    {
        Write-Error -Message "Found multiple VMs with the name $VMName. Unable to configure extension"
    }

    $vms += Get-AzureRmVM -Name $VMName -ResourceGroupName $ResourceGroupName
}

foreach ($vm in $vms)
{
    $currentNetWatcherExtension = $vm.Extensions.Where{ $_.VirtualMachineExtensionType -eq "NetworkWatcherAgentLinux" }[0]

    if (-not $currentNetWatcherExtension)
    {
        Write-Output "Starting to add network watcher extension to $($vm.Name)"                   
    
        Set-AzureRmVMExtension `
            -ExtensionName "NetworkWatcherAgentLinux" `
            -ResourceGroupName $vm.ResourceGroupName `
            -VMName $vm.Name `
            -Publisher "Microsoft.Azure.NetworkWatcher" `
            -ExtensionType "NetworkWatcherAgentLinux" `
            -TypeHandlerVersion 1.4 `
            -Location $vm.Location 
    }
}