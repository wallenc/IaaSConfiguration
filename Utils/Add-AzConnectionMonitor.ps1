<#
    .SYNOPSIS
    This script configures network watcher connection monitor
    tests from one or more VMs to one or more destination VM

    .PARAMETER sourceVmSubscriptionID
    Id of the subscription where the source VM(s) reside

    .PARAMETER destinationVmsSubscriptionID
    Id of the subscription where the destination VM(s) reside

    .PARAMETER sourceVMNames
    List of VMs to use as sources for the connection monitor

    .PARAMETER destinationVmNames
    List of VMs to use as the destination for the monitor

    .PARAMETER monitorPort
    The port to use for the connection monitor

    .NOTES
        Version:        1.0
        Author:         Chris Wallen
        Creation Date:  06/22/2020
#>

Param(

    [parameter(mandatory)]
    [string]
    $sourceVmSubscriptionID,

    [parameter(mandatory)]
    [string]
    $destinationVmsSubscriptionID,

    [parameter(Mandatory)]
    [string[]]
    $sourceVMNames,

    [parameter(Mandatory)]
    [string[]]
    $destinationVmNames,

    [parameter(Mandatory)]
    [int]
    $monitorPort
)

# Function to add net watcher extension
function Add-AzNetworkWatcherExtension
{
    Param (

        [parameter(mandatory)]
        [Object]
        $VirtualMachine
    )

    $vmStatus = (Get-AzVM `
            -ResourceGroupName $VirtualMachine.ResourceGroupName `
            -Name $VirtualMachine.Name `
            -Status).Statuses.DisplayStatus[-1]

    # Ensure VM is running. If it's not, we won't
    # be able to tell if the network watcher extension is installed
    if ($vmStatus -eq 'VM running')
    {
        if ($VirtualMachine.StorageProfile.OsDisk.OsType -eq 'Windows')
        {
            $extensions = Get-AzVMExtension `
                -ResourceGroupName $VirtualMachine.ResourceGroupName `
                -VMName $VirtualMachine.Name | where { $_.ExtensionType -eq 'NetworkWatcherAgentWindows' } `
                -ErrorAction SilentlyContinue

            #Make sure the extension is not already installed before attempting to install it
            if (!($extensions))
            {
                Write-Output "Network watcher extension not installed on $($VirtualMachine.Name)"

                Write-Output "Adding the extension"
                $null = Set-AzVMExtension `
                    -ExtensionName "AzureNetworkWatcherExtension" `
                    -ResourceGroupName $VirtualMachine.ResourceGroupName `
                    -VMName $VirtualMachine.Name `
                    -Publisher "Microsoft.Azure.NetworkWatcher" `
                    -ExtensionType "NetworkWatcherAgentWindows" `
                    -TypeHandlerVersion 1.4 `
                    -Location $VirtualMachine.Location
            }
        }
        elseif ($VirtualMachine.StorageProfile.OsDisk.OsType -eq 'Linux')
        {
            # Make sure the extension is not already installed before attempting to install it
            $extensions = Get-AzVMExtension `
                -ResourceGroupName $VirtualMachine.ResourceGroupName `
                -VMName $VirtualMachine.Name | where { $_.ExtensionType -eq 'NetworkWatcherAgentLinux' } `
                -ErrorAction SilentlyContinue

            if (!($extensions))
            {
                Write-Output "Network watcher extension not installed on $($VirtualMachine.Name)"

                Write-Output "Adding the extension"

                $null = Set-AzVMExtension `
                    -ExtensionName "NetworkWatcherAgentLinux" `
                    -ResourceGroupName $VirtualMachine.ResourceGroupName `
                    -VMName $VirtualMachine.Name `
                    -Publisher "Microsoft.Azure.NetworkWatcher" `
                    -ExtensionType "NetworkWatcherAgentLinux" `
                    -TypeHandlerVersion 1.4 `
                    -Location $VirtualMachine.Location
            }
        }
    }
    else
    {
        Write-Warning -Message "Skipping VM as it is not currently powered on"
    }
}

# Make sure Az module is installed as script depends on it
Import-Module -Name Az -ErrorAction Stop

#Set context to source VM subscription
$null = Set-AzContext -Subscription $sourceVmSubscriptionID

$sourceVms = @()

#Loop through source VM list to build array of VM objects
foreach ($sourceVmName in $sourceVmNames)
{
    $sourceVm = Get-AzVM -Name $sourceVmName
    Write-Output "Checking for Network Watcher extension on $($sourceVm.Name)"
    if ($null -ne $sourceVm)
    {
        Add-AzNetworkWatcherExtension -VirtualMachine $sourceVm
        $sourceVms += $sourceVm
    }
    else
    {
        Write-Warning "Unable to find VM $sourceVmName in subscription $($azContext.SubscriptionName)"
    }
}

#Set context to destination VM sub
$azContext = Set-AzContext -Subscription $destinationVmsSubscriptionID
$destinationVms = @{}

#Loop through list of destination VMs to build hash table of VMs and their IPs
foreach ($destinationVMName in $destinationVMNames)
{
    $destinationVm = Get-AzVM -Name $destinationVMName

    if ($null -ne $destinationVM)
    {
        $destinationVmNicResource = Get-AzResource `
            -Id $destinationVM.NetworkProfile.NetworkInterfaces.Id

        $destinationVmIp = (Get-AzNetworkInterface `
                -ResourceGroupName $destinationVmNicResource.ResourceGroupName `
                -Name $destinationVmNicResource.Name).IpConfigurations.PrivateIpAddress | where { $_.IpConfigurations.Primary -eq 'True' }

        $destinationVms.Add($destinationVm.Name, $destinationVmIp)

        Add-AzNetworkWatcherExtension -VirtualMachine $destinationVM
    }
    else
    {
        Write-Warning "Unable to find VM $destinationVMName in subscription $($azContext.SubscriptionName)"
    }
}

#Set context back to source VM
$azContext = Set-AzContext -Subscription $sourceVmSubscriptionID
$sourceNw = Get-AzNetworkWatcher -Location $vm.Location

foreach ($source in $sourceVms)
{
    Write-Output "Source VM $($source.Name)"
    foreach ($destinationVm in $destinationVms.GetEnumerator())
    {
        Write-Output "Destination VM $($destinationVm.Name)"
        $nwExists = Get-AzNetworkWatcherConnectionMonitor `
            -NetworkWatcherName $sourceNw.Name `
            -ResourceGroupName $sourceNw.ResourceGroupName `
            -Name ($source.Name + "-" + $destinationVm.Name) `
            -ErrorAction SilentlyContinue

        if (!($nwExists))
        {
            Write-Warning "Connection monitor for $($source.Name + "-" + $destinationVm.Name) does not exist. Creating it"

            $null = New-AzNetworkWatcherConnectionMonitor `
                -NetworkWatcher $sourceNw `
                -Name ($source.Name + "-" + $destinationVm.Name) `
                -SourceResourceId $source.Id `
                -DestinationAddress $destinationVm.Value `
                -DestinationPort $monitorPort
        }
        else
        {
            Write-Warning "Connection monitor $($nwExists.Name) already exists"
        }
        $monitorStarted = (Get-AzNetworkWatcherConnectionMonitor `
                -NetworkWatcherName $sourceNw.Name `
                -ResourceGroupName $sourceNw.ResourceGroupName `
                -Name ("$($source.Name) - $($destinationVm.Name)") `
                -ErrorAction SilentlyContinue ).MonitoringStatus

        if ($monitorStarted -eq 'NotStarted')
        {
            $null = Start-AzNetworkWatcherConnectionMonitor `
                -NetworkWatcherName $sourceNw.Name `
                -ResourceGroupName $sourceNw.ResourceGroupName `
                -Name ($source.Name + "-" + $destinationVm.Name)

            Write-Output "Started connection monitor $($source.Name + "-" + $destinationVm.Name)"
        }
    }

}
