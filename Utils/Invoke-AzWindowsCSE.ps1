<#
    .SYNOPSIS
        Run a Custom Script Extension on a list of Windows VMs.

    .NOTES
        - Since only 1 CSE is allowed on a VM at one time, previous existing CSEs found will be removed
        - CSEs are deployed to VMs in parallel after prep is complete

    .PARAMETER SubscriptionId
        Azure subscription ID

    .PARAMETER VmNames
        string array of VM names to run CSE on

    .PARAMETER ResourceGroupName
        Resource group name of all VMs (All VMs but be in the same RG at this time)

    .PARAMETER ScriptFilePath
        Path to bash script to run. Must end in .sh

    .PARAMETER ScriptExtensionName
        Name for the script extension in Azure

    .PARAMETER Parameters
        String array of parameters to pass to bash script when called on target VM

    .PARAMETER StorageAccountName
        Name of storage account to store CSE script on

    .PARAMETER StorageAccountResourceGroupName
        Storage account resource group name

    .PARAMETER ContainerName
        Storage account container name
#>

param
(
    [parameter(mandatory)]
    [string]
    $SubscriptionId, 
 
    [parameter(mandatory)]
    [string[]]
    $VmNames,
 
    [parameter(mandatory)]
    [string]
    $ResourceGroupName,

    [parameter(mandatory)]
    [string]
    $ScriptFilePath,

    [parameter(mandatory)]
    [string]
    $ScriptExtensionName,

    [string[]]
    $Parameters = @(),
 
    [parameter(mandatory)]
    [string]
    $StorageAccountName,
 
    [parameter(mandatory)]
    [string]
    $StorageAccountResourceGroupName,
 
    [parameter(mandatory)]
    [string]
    $ContainerName
)
 
Set-AzContext -Subscription $SubscriptionId

#region
function Copy-ToStorageAccount
{
    param
    (
        [parameter(Mandatory)]
        [string]
        $ResourceGroupName,

        [parameter(Mandatory)]
        [string]
        $StorageAccountName,

        [parameter(Mandatory)]
        [string]
        $ScriptFilePath,

        [parameter(Mandatory)]
        [string]
        $ContainerName,

        [parameter(Mandatory)]
        [string]
        $BlobFileName
    )

    $storageAccount = Get-AzStorageAccount `
        -ResourceGroupName $ResourceGroupName `
        -Name $StorageAccountName `
        -ErrorAction 'Stop'

    $container = Get-AzStorageContainer `
        -Name $ContainerName `
        -Context $storageAccount.Context `
        -ErrorAction SilentlyContinue

    if(!$container)
    {
        $null = New-AzStorageContainer -Name $ContainerName -Context $storageAccount.Context
    }

    $null = Set-AzStorageBlobContent `
        -File $ScriptFilePath `
        -Container $ContainerName `
        -Blob $BlobFileName `
        -Context $storageAccount.Context `
        -ErrorAction Stop `
        -Force
}

function Set-WindowsCustomScriptExtension
{
    [cmdletBinding()]
    param
    (
        [parameter(Mandatory)]
        [string]
        $VMName,

        [parameter(Mandatory)]
        [string]
        $ResourceGroupName,

        [parameter(Mandatory)]
        [string]
        $StorageAccountName,

        [parameter(Mandatory)]
        [string]
        $ContainerName,

        [parameter(Mandatory)]
        [string]
        $StorageAccountResourceGroupName,

        [parameter(Mandatory)]
        [string]
        $ScriptFilePath,

        [string[]]
        $Parameters,

        [parameter(Mandatory)]
        [string]
        $ScriptExtensionName
    )

    $ScriptItem = Get-Item -Path $ScriptFilePath

    # Get location on the VM
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction Stop
    
    # build uri to script location in storage account
    $fileUri = "https://$StorageAccountName.blob.core.usgovcloudapi.net/$ContainerName/$($ScriptItem.Name)"

    $saKey = Get-AzStorageAccountKey -ResourceGroupName $StorageAccountResourceGroupName -AccountName $StorageAccountName -ErrorAction Stop

    # remove any current CSE's on the VM. There can only be one
    $vm = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VMName -ErrorAction Stop 

    $currentCSE = $vm.Extensions.Where{$_.VirtualMachineExtensionType -eq "CustomScriptExtension"}

    if($currentCSE.Length -ge 1)
    {
        Write-Verbose "Removing CSE $($currentCSE[0].Name) on VM $VMName before deploying new CSE."

        $null = Remove-AzVMCustomScriptExtension `
            -ResourceGroupName $ResourceGroupName `
            -VMName $VMName `
            -Name $currentCSE[0].Name `
            -ErrorAction Stop `
            -Force
    }

    $command = "powershell.exe -command .\$($ScriptItem.Name)"
    foreach($param in $Parameters)
    {
        $command += " " + $param
    }

    Write-Verbose "Starting deployment of new CSE"

    # Deploy the CSE
    return Set-AzVMExtension `
        -ResourceGroupName $ResourceGroupName `
        -VMName $VMName `
        -Location $rg.Location `
        -Name $ScriptExtensionName `
        -Publisher "Microsoft.Compute" `
        -ExtensionType "CustomScriptExtension" `
        -TypeHandlerVersion "1.5" `
        -Settings @{
            "fileUris" = [Object[]]$fileUri
        } `
        -ProtectedSettings @{
            "commandToExecute" = $command
            "storageAccountName" = $StorageAccountName
            "storageAccountKey" = $saKey.Value[0]
        } `
        -AsJob
}
#endregion
 
# Upload the CSE script to a storage account
$ScriptItem = Get-Item -Path $ScriptFilePath

Write-Output "Uploading script to SA"
Copy-ToStorageAccount `
    -ResourceGroupName $StorageAccountResourceGroupName `
    -StorageAccountName $StorageAccountName `
    -ScriptFilePath $ScriptFilePath `
    -ContainerName $ContainerName `
    -BlobFileName $ScriptItem.Name

$jobs = @()
foreach($VmName in $VmNames)
{
    Write-Output "Starting job on VM $VmName"
    $jobs += Set-WindowsCustomScriptExtension `
        -VMName $VmName `
        -ScriptExtensionName $ScriptExtensionName `
        -ScriptFilePath $ScriptFilePath `
        -ResourceGroupName $ResourceGroupName `
        -StorageAccountName $StorageAccountName `
        -StorageAccountResourceGroupName $StorageAccountResourceGroupName `
        -ContainerName $ContainerName `
        -Parameters $Parameters `
        -Verbose
}

do
{
    $jobsStillRunning = $false
    foreach($deploymentJob in $jobs)
    {
        $currentStatus = Get-Job -Id $deploymentJob.Id

        if(@("NotStarted", "Running") -contains $currentStatus.State)
        {
            $jobsStillRunning = $true
        }

        Receive-Job -Job $deploymentJob
    }
}
while($jobsStillRunning)

foreach($VmName in $VmNames)
{
    $out = Get-AzVMExtension `
        -ResourceGroupName $ResourceGroupName `
        -VMName $VmName `
        -Name $ScriptExtensionName `
        -Status

    Write-Output "Resultant output for VM $VmName"
    $out.Statuses.Message
}
