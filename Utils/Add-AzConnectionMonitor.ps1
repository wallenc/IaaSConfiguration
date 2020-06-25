<#
    .SYNOPSIS
    This script configures network watcher connection monitor
    tests from one or multiple VMs to a single destination VM

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

#Set context to source VM subscription
$azContext = Set-AzContext -Subscription $sourceVmSubscriptionID

$sourceVms = @()

#Loop through source VM list to build array of VM objects
foreach ($source in $sourceVmNames)
{

    $sourceVMResource = Get-AzResource -ResourceType 'Microsoft.Compute/virtualMachines' -Name $source -ErrorAction SilentlyContinue    

    if ($sourceVMResource)
    {
        $sourceVMs += Get-AzVM -VMName $sourceVMResource.Name -ResourceGroupName $sourceVMResource.ResourceGroupName
        $sourceVMStatus = (Get-AzVM -ResourceGroupName $sourceVMs[-1].ResourceGroupName -Name $sourceVMs[-1].Name -Status).Statuses.DisplayStatus[-1]
    
        #Ensure VM is running. If it's not, we won't be able to tell if the network watcher extension is installed
        if ($sourceVMStatus -eq 'VM running')
        {
            if ($sourceVMs[-1].StorageProfile.OsDisk.OsType -eq 'Windows')
            {
                $extensions = Get-AzVMExtension -ResourceGroupName $sourceVMs[-1].ResourceGroupName `
                    -VMName $sourceVMs[-1].Name -Name 'AzureNetworkWatcherExtension' -ErrorAction SilentlyContinue

                #Make sure the extension is not already installed before attempting to install it
                if (-not $extensions)
                {
                    Write-Output "Starting to add network watcher extension to $($sourceVMs[-1].Name)"
                    Set-AzVMExtension `
                        -ExtensionName "AzureNetworkWatcherExtension" `
                        -ResourceGroupName $sourceVMs[-1].ResourceGroupName `
                        -VMName $sourceVMs[-1].Name `
                        -Publisher "Microsoft.Azure.NetworkWatcher" `
                        -ExtensionType "NetworkWatcherAgentWindows" `
                        -TypeHandlerVersion 1.4 `
                        -Location $sourceVMs[-1].Location
                }
            }
            elseif ($sourceVms[-1].StorageProfile.OsDisk.OsType -eq 'Linux')
            {
                $extensions = Get-AzVMExtension -ResourceGroupName $sourceVMs[-1].ResourceGroupName `
                    -VMName $sourceVMs[-1].Name -Name 'NetworkWatcherAgentLinux' -ErrorAction SilentlyContinue

                #Make sure the extension is not already installed before attempting to install it
                if (-not $extensions)
                {
                    Write-Output "Starting to add network watcher extension to $($vm.Name)"

                    Set-AzVMExtension `
                        -ExtensionName "NetworkWatcherAgentLinux" `
                        -ResourceGroupName $sourceVMs[-1].ResourceGroupName `
                        -VMName $sourceVMs[-1].Name `
                        -Publisher "Microsoft.Azure.NetworkWatcher" `
                        -ExtensionType "NetworkWatcherAgentLinux" `
                        -TypeHandlerVersion 1.4 `
                        -Location $sourceVMs[-1].Location
                }
            }
        }
        else
        {
            Write-Warning -Message "Skipping VM as it is not currently powered on"
        }        
    }
    else
    {
        Write-Warning "Unable to find VM $source in subscription $($azContext.SubscriptionName)"
    }
}

#Set context to destination VM sub
$azContext = Set-AzContext -Subscription $destinationVmsSubscriptionID
$destinationVms = @{}

#Loop through list of destination VMs to build hash table of VMs and their IPs
foreach ($destination in $destinationVMNames)
{
    $destinationVmResource = Get-AzResource -ResourceType 'Microsoft.Compute/virtualMachines' -Name $destination -ErrorAction SilentlyContinue    

    if ($destinationVmResource)
    {       
        $destinationVm = Get-AzVM -VMName $destinationVmResource.Name -ResourceGroupName $destinationVmResource.ResourceGroupName
        $destinationVmNicResource = Get-AzResource -Id $destinationVM.NetworkProfile.NetworkInterfaces.Id

        $destinationVmIp = (Get-AzNetworkInterface -ResourceGroupName $destinationVmNicResource.ResourceGroupName `
                -Name $destinationVmNicResource.Name).IpConfigurations.PrivateIpAddress

        $destinationVms.Add($destinationVm.Name, $destinationVmIp)

        $vmStatus = (Get-AzVM -ResourceGroupName $destinationVm.ResourceGroupName -Name $destinationVm.Name -Status).Statuses.DisplayStatus[-1]

        if ($vmStatus -eq 'VM running')
        {

            if ($destinationVm.StorageProfile.OsDisk.OsType -eq 'Windows')
            {
                $extensions = Get-AzVMExtension -ResourceGroupName $destinationVm.ResourceGroupName `
                    -VMName $destinationVm.Name -Name 'AzureNetworkWatcherExtension' -ErrorAction SilentlyContinue

                #Make sure the extension is not already installed before attempting to install it
                if (-not $extensions)
                {
                    Write-Output "Starting to add network watcher extension to $($destinationVm.Name)"
                    Set-AzVMExtension `
                        -ExtensionName "AzureNetworkWatcherExtension" `
                        -ResourceGroupName $destinationVm.ResourceGroupName `
                        -VMName $destinationVm.Name `
                        -Publisher "Microsoft.Azure.NetworkWatcher" `
                        -ExtensionType "NetworkWatcherAgentWindows" `
                        -TypeHandlerVersion 1.4 `
                        -Location $destinationVm.Location
                }
            }
            elseif ($destinationVm.StorageProfile.OsDisk.OsType -eq 'Linux')
            {
                $extensions = Get-AzVMExtension -ResourceGroupName $destinationVm.ResourceGroupName `
                    -VMName $destinationVm.Name -Name 'NetworkWatcherAgentLinux' -ErrorAction SilentlyContinue

                #Make sure the extension is not already installed before attempting to install it
                if (-not $extensions)
                {
                    Write-Output "Starting to add network watcher extension to $($destinationVm.Name)"

                    Set-AzVMExtension `
                        -ExtensionName "NetworkWatcherAgentLinux" `
                        -ResourceGroupName $destinationVm.ResourceGroupName `
                        -VMName $destinationVm.Name `
                        -Publisher "Microsoft.Azure.NetworkWatcher" `
                        -ExtensionType "NetworkWatcherAgentLinux" `
                        -TypeHandlerVersion 1.4 `
                        -Location $destinationVm.Location
                }
            }            
        }
        else
        {
            Write-Warning -Message "Skipping VM as it is not currently powered on"
        }        
    }
    else
    {
        Write-Warning "Unable to find VM $destination in subscription $($azContext.SubscriptionName)"
    }
}

#Set context back to source VM 
$azContext = Set-AzContext -Subscription $sourceVmSubscriptionID
$sourceNw = Get-AzNetworkWatcher -Location $sourceVms[-1].Location

foreach ($source in $sourceVms)
{
    foreach ($vm in $destinationVms.GetEnumerator())
    {
        $nwExists = Get-AzNetworkWatcherConnectionMonitor -NetworkWatcherName $sourceNw.Name -ResourceGroupName $sourceNw.ResourceGroupName `
            -Name ($source.Name + "-" + $vm.Name) -ErrorAction SilentlyContinue

        if (-not $nwExists)
        {
            Write-Host "Connection monitor for $($source.Name + "-" + $vm.Name) does not exist. Creating it" -ForegroundColor Yellow

            $result = New-AzNetworkWatcherConnectionMonitor -NetworkWatcher $sourceNw -Name ($source.Name + "-" + $vm.Name.ToUpper()) `
                -SourceResourceId $source.Id -DestinationAddress $vm.Value -DestinationPort $monitorPort

            $isStarted = (Get-AzNetworkWatcherConnectionMonitor -NetworkWatcherName $sourceNw.Name -ResourceGroupName $sourceNw.ResourceGroupName `
                    -Name ($source.Name + "-" + $vm.Name)).MonitoringStatus

            if ($isStarted -eq 'NotStarted')
            {
                $startWatcher = Start-AzNetworkWatcherConnectionMonitor -NetworkWatcherName $sourceNw.Name -ResourceGroupName $sourceNw.ResourceGroupName -Name ($source.Name + "-" + $vm.Name.ToUpper())
                Write-Output "Started connection monitor $($source.Name + "-" + $vm.Name)"
            }            
        }
        else
        {
            Write-Warning "Connection monitor $($nwExists.Name) already exists"
        }
    }
}
