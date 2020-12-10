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

# Check to make sure Az module is installed as script depends on it
if (!(Get-InstalledModule -Name Az))
{
    throw "Azure Az powershell module is not installed. Please install and try again."
}

#Set context to source VM subscription
$null = Set-AzContext -Subscription $sourceVmSubscriptionID

$sourceVms = @()

#Loop through source VM list to build array of VM objects
foreach ($vmName in $sourceVmNames)
{
    $vm = Get-AzVM -Name $vmName

    if ($null -ne $vm)
    {
        $vmStatus = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status).Statuses.DisplayStatus[-1]

        #Ensure VM is running. If it's not, we won't be able to tell if the network watcher extension is installed
        if ($vmStatus -eq 'VM running')
        {
            if ($vm.StorageProfile.OsDisk.OsType -eq 'Windows')
            {
                $extensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName `
                    -VMName $vm.Name -Name 'AzureNetworkWatcherExtension' -ErrorAction SilentlyContinue

                #Make sure the extension is not already installed before attempting to install it
                if (-not $extensions)
                {
                    Write-Output "Starting to add network watcher extension to $($vm.Name)"
                    Set-AzVMExtension `
                        -ExtensionName "AzureNetworkWatcherExtension" `
                        -ResourceGroupName $vm.ResourceGroupName `
                        -VMName $vm.Name `
                        -Publisher "Microsoft.Azure.NetworkWatcher" `
                        -ExtensionType "NetworkWatcherAgentWindows" `
                        -TypeHandlerVersion 1.4 `
                        -Location $vm.Location
                }
            }
            elseif ($vm.StorageProfile.OsDisk.OsType -eq 'Linux')
            {
                $extensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName `
                    -VMName $vm.Name -Name 'NetworkWatcherAgentLinux' -ErrorAction SilentlyContinue

                #Make sure the extension is not already installed before attempting to install it
                if (-not $extensions)
                {
                    Write-Output "Starting to add network watcher extension to $($vm.Name)"

                    Set-AzVMExtension `
                        -ExtensionName "NetworkWatcherAgentLinux" `
                        -ResourceGroupName $vm.ResourceGroupName `
                        -VMName $vm.Name `
                        -Publisher "Microsoft.Azure.NetworkWatcher" `
                        -ExtensionType "NetworkWatcherAgentLinux" `
                        -TypeHandlerVersion 1.4 `
                        -Location $vm.Location
                }
            }

            $sourceVms += $vm
        }
        else
        {
            Write-Warning -Message "Skipping VM as it is not currently powered on"
        }
    }
    else
    {
        Write-Warning "Unable to find VM $vmName in subscription $($azContext.SubscriptionName)"
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
                    -VMName $destinationVm.Name -Name 'AzureNetworkWatcherExtension' -ErrorAction SilentlyContinue

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
        Write-Warning "Unable to find VM $destinationVMNamein subscription $($azContext.SubscriptionName)"
    }
}

#Set context back to source VM
$azContext = Set-AzContext -Subscription $sourceVmSubscriptionID
$sourceNw = Get-AzNetworkWatcher -Location $vm.Location

foreach ($sourceVm in $sourceVms)
{
    foreach ($vm in $destinationVms.GetEnumerator())
    {
        $nwExists = Get-AzNetworkWatcherConnectionMonitor -NetworkWatcherName $sourceNw.Name -ResourceGroupName $sourceNw.ResourceGroupName `
            -Name ($sourceVm.Name + "-" + $vm.Name) -ErrorAction SilentlyContinue

        if (-not $nwExists)
        {
            Write-Host "Connection monitor for $($sourceVm.Name + "-" + $vm.Name) does not exist. Creating it" -ForegroundColor Yellow

            $null = New-AzNetworkWatcherConnectionMonitor -NetworkWatcher $sourceNw -Name ($sourceVm.Name + "-" + $vm.Name.ToUpper()) `
                -SourceResourceId $sourceVm.Id -DestinationAddress $vm.Value -DestinationPort $monitorPort

            $isStarted = (Get-AzNetworkWatcherConnectionMonitor -NetworkWatcherName $sourceNw.Name -ResourceGroupName $sourceNw.ResourceGroupName `
                    -Name ($sourceVm.Name + "-" + $vm.Name)).MonitoringStatus

            if ($isStarted -eq 'NotStarted')
            {
                $null = Start-AzNetworkWatcherConnectionMonitor `
                    -NetworkWatcherName $sourceNw.Name `
                    -ResourceGroupName $sourceNw.ResourceGroupName `
                    -Name ($sourceVm.Name + "-" + $vm.Name.ToUpper())
                
                Write-Output "Started connection monitor $($source.Name + "-" + $vm.Name)"
            }
        }
        else
        {
            Write-Warning "Connection monitor $($nwExists.Name) already exists"
        }
    }
}
