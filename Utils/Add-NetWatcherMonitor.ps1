<#
    .SYNOPSIS
    This script configures network watcher connection monitor
    tests from one or multiple VMs to a single destination VM

    .PARAMETER azureSubscriptionID
    Id of the subscription to use

    .PARAMETER sourceVMNames
    List of VMs to use as sources for the connection monitor test

    .PARAMETER destinationVmName
    Name of the VM to use as the destination for the test

    .PARAMETER testPort
    The port to use for the connection monitor test

    .PARAMETER testInterval
    The interval at which to run the test. If this value is omitted,
    the default setting of 60 seconds will be used.

    .NOTES
        Version:        1.0
        Author:         Chris Wallen
        Creation Date:  06/22/2020
#>

Param(

    [parameter(mandatory)]
    [string]
    $azureSubscriptionID,

    [parameter(Mandatory)]
    [string[]]
    $sourceVMNames,

    [parameter(Mandatory)]
    [string]
    $destinationVmName,

    [parameter(Mandatory)]
    [int]
    $testPort,
    
    [string]
    $testInterval
)

$azContext = Set-AzContext -Subscription $azureSubscriptionID

$sourceVms = @()

$destinationVMResource = Get-AzResource -ResourceType 'Microsoft.Compute/virtualMachines' -Name $destinationVMName
$destinationVM = Get-AzVM -VMName $destinationVMResource.Name -ResourceGroupName $destinationVMResource.ResourceGroupName
$destinationVmNicResource = Get-AzResource -Id $destinationVM.NetworkProfile.NetworkInterfaces.Id

$destinationVmIp = (Get-AzNetworkInterface -ResourceGroupName $destinationVmNicResource.ResourceGroupName `
        -Name $destinationVmNicResource.Name).IpConfigurations.PrivateIpAddress

$destinationVmStatus = (Get-AzVM -ResourceGroupName $destinationVM.ResourceGroupName -Name $destinationVM.Name -Status).Statuses.DisplayStatus[-1]

if ($destinationVmStatus -eq 'VM running')
{
    if ($destinationVM.StorageProfile.OsDisk.OsType -eq 'Windows')
    {
        $extensions = Get-AzVMExtension -ResourceGroupName $destinationVM.ResourceGroupName `
            -VMName $destinationVM.Name -Name 'NetworkWatcherAgentWindows' -ErrorAction SilentlyContinue

        #Make sure the extension is not already installed before attempting to install it
        if (-not $extensions)
        {
            Write-Output "Starting to add network watcher extension to $($destinationVM.Name)"
            Set-AzVMExtension `
                -ExtensionName "NetworkWatcherAgentWindows" `
                -ResourceGroupName $destinationVM.ResourceGroupName `
                -VMName $destinationVM.Name `
                -Publisher "Microsoft.Azure.NetworkWatcher" `
                -ExtensionType "NetworkWatcherAgentWindows" `
                -TypeHandlerVersion 1.4 `
                -Location $destinationVM.Location
        }
    }
    elseif ($vm.StorageProfile.OsDisk.OsType -eq 'Linux')
    {
        $extensions = Get-AzVMExtension -ResourceGroupName $destinationVM.ResourceGroupName `
            -VMName $destinationVM.Name -Name 'NetworkWatcherAgentLinux' -ErrorAction SilentlyContinue

        #Make sure the extension is not already installed before attempting to install it
        if (-not $extensions)
        {
            Write-Output "Starting to add network watcher extension to $($vm.Name)"

            Set-AzVMExtension `
                -ExtensionName "NetworkWatcherAgentLinux" `
                -ResourceGroupName $destinationVM.ResourceGroupName `
                -VMName $destinationVM.Name `
                -Publisher "Microsoft.Azure.NetworkWatcher" `
                -ExtensionType "NetworkWatcherAgentLinux" `
                -TypeHandlerVersion 1.4 `
                -Location $destinationVM.Location
        }
    }
}

foreach ($source in $sourceVMNames)
{
    $sourceVMResource = Get-AzResource -ResourceType 'Microsoft.Compute/virtualMachines' -Name $source -ErrorAction SilentlyContinue

    if ($sourceVMResource)
    {
        $sourceVm = Get-AzVM -VMName $sourceVMResource.Name -ResourceGroupName $sourceVMResource.ResourceGroupName

        $vmStatus = (Get-AzVM -ResourceGroupName $sourceVm.ResourceGroupName -Name $sourceVm.Name -Status).Statuses.DisplayStatus[-1]

        if ($vmStatus -eq 'VM running')
        {

            if ($sourceVm.StorageProfile.OsDisk.OsType -eq 'Windows')
            {
                $extensions = Get-AzVMExtension -ResourceGroupName $sourceVm.ResourceGroupName `
                    -VMName $sourceVm.Name -Name 'NetworkWatcherAgentWindows' -ErrorAction SilentlyContinue

                #Make sure the extension is not already installed before attempting to install it
                if (-not $extensions)
                {
                    Write-Output "Starting to add network watcher extension to $($vm.Name)"
                    Set-AzVMExtension `
                        -ExtensionName "NetworkWatcherAgentWindows" `
                        -ResourceGroupName $sourceVm.ResourceGroupName `
                        -VMName $sourceVm.Name `
                        -Publisher "Microsoft.Azure.NetworkWatcher" `
                        -ExtensionType "NetworkWatcherAgentWindows" `
                        -TypeHandlerVersion 1.4 `
                        -Location $sourceVm.Location
                }
            }
            elseif ($sourceVm.StorageProfile.OsDisk.OsType -eq 'Linux')
            {
                $extensions = Get-AzVMExtension -ResourceGroupName $sourceVm.ResourceGroupName `
                    -VMName $sourceVm.Name -Name 'NetworkWatcherAgentLinux' -ErrorAction SilentlyContinue

                #Make sure the extension is not already installed before attempting to install it
                if (-not $extensions)
                {
                    Write-Output "Starting to add network watcher extension to $($sourceVm.Name)"

                    Set-AzVMExtension `
                        -ExtensionName "NetworkWatcherAgentLinux" `
                        -ResourceGroupName $sourceVm.ResourceGroupName `
                        -VMName $sourceVm.Name `
                        -Publisher "Microsoft.Azure.NetworkWatcher" `
                        -ExtensionType "NetworkWatcherAgentLinux" `
                        -TypeHandlerVersion 1.4 `
                        -Location $sourceVm.Location
                }
            }

            $sourceNw = Get-AzNetworkWatcher -Location $sourceVm.Location
            $nwExists = Get-AzNetworkWatcherConnectionMonitor -NetworkWatcherName $sourceNw.Name -ResourceGroupName $sourceNw.ResourceGroupName `
                -Name ($sourceVm.Name + "-" + $destinationVM.Name) -ErrorAction SilentlyContinue

            if (-not $nwExists)
            {
                Write-Host "Connection monitor for $($sourceVm.Name + "-" + $destinationVM.Name) does not exist. Creating it" -ForegroundColor Yellow

                $result = New-AzNetworkWatcherConnectionMonitor -NetworkWatcher $sourceNw -Name ($sourceVm.Name + "-" + $destinationVM.Name) `
                    -SourceResourceId $sourceVm.Id -DestinationAddress $destinationVmIp -DestinationPort $testPort -MonitoringIntervalInSeconds $testInterval

                Start-AzNetworkWatcherConnectionMonitor -NetworkWatcherName $sourceNw.Name -ResourceGroupName $sourceNw.ResourceGroupName -Name $result.Name
            }
            else
            {
                Write-Warning "Connection monitor $($nwExists.Name) already exists"
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