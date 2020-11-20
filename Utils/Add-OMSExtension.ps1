<#
    .SYNOPSIS
        Installs the OMS Agent to Azure VMs with the Guest Agent

    .DESCRIPTION
        Traverses an entire subscription / resource group/ or list of VMs to
        install and configure the Log Analytics extension. If no ResourceGroupNames
        or VMNames are provided, all VMs will have the extension installed.
        Otherwise a superset of the 2 parameters is used to determine VM list.

    .PARAMETER azureSubscriptionID
        ID of Azure subscription to use

    .PARAMETER azureEnvironment
        The Azure Cloud environment to use, i.e. AzureCloud, AzureUSGovernment

    .PARAMETER LogAnalyticsWorkspaceName
        Log Analytic workspace name

    .PARAMETER LAResourceGroup
        Resource Group of Log Analytics workspace

    .PARAMETER ResourceGroupNames
        List of Resource Groups. VMs within these RGs will have the extension installed
        Should be specified in format ['rg1','rg2']

    .PARAMETER VMNames
        List of VMs to install OMS extension to
        Specified in the format ['vmname1','vmname2']

    .NOTES
        Version:        1.0
        Author:         Chris Wallen
        Creation Date:  09/10/2019
#>
Param
(
    #[parameter(mandatory)]
    [string]
    $azureSubscriptionID = 'd8abb5fd-9d00-48fd-862a-0f778306cce7',

    #[parameter(mandatory)]
    [string]
    $azureEnvironment = 'AzureUSGovernment',

    #[parameter(mandatory)]
    [string]
    $WorkspaceName = 'PROD-LA',

    #[parameter(mandatory)]
    [string]
    $LAResourceGroup = 'LA-AA',

    [string[]]
    $ResourceGroupNames,

    [string[]]
    $VMNames = 'devbox'
)

function Set-AzureConnection
{
    Param
    (
        [parameter(mandatory = $true)]
        $SubscriptionID,

        $AutomationConnection,

        $AzureEnvironment
    )

    $context = Get-AzContext

    if ($null -eq $context.Account)
    {
        $envARM = Get-AzEnvironment -Name $AzureEnvironment

        if ($null -ne $AutomationConnection)
        {
            $context = Add-AzAccount `
                -ServicePrincipal `
                -Tenant $Conn.TenantID `
                -ApplicationId $Conn.ApplicationID `
                -CertificateThumbprint $Conn.CertificateThumbprint `
                -Environment $envARM
        }
        else # if no connection info, log in using the web prompts
        {
            $context = Add-AzAccount -Environment $envARM -ErrorAction Stop
        }
    }

    $null = Set-AzContext -Subscription $azureSubscriptionID -ErrorAction Stop
}


if ($PSPrivateMetadata.JobId)
{
    # in Azure Automation
    # connect to Azure using AzureRunAs account
    $conn = Get-AutomationConnection -Name AzureRunAsConnection -ErrorAction Stop

    Set-AzureConnection -SubscriptionId $azureSubscriptionID -AutomationConnection $conn -AzureEnvironment $azureEnvironment -ErrorAction Stop
}
else
{
    # not in Azure Automation
    # connect to Azure using standard method
    Set-AzureConnection -SubscriptionId $azureSubscriptionID -AutomationConnection $conn -ErrorAction Stop
}


$azContext = Select-AzSubscription -subscriptionId $azureSubscriptionID -ErrorAction Stop

$vms = @()

if (-not $ResourceGroupNames -and -not $VMNames)
{
    Write-Output "No resource groups or VMs specified. Collecting all VMs"
    $vms = Get-AzVM
}
elseif ($ResourceGroupNames -and -not $VMNames)
{
    foreach ($rg in $ResourceGroupNames)
    {
        Write-Output "Collecting VM facts from resource group $rg"
        $vms += Get-AzVM -ResourceGroupName $rg
    }
}
else
{
    foreach ($VMName in $VMNames)
    {
        $azureResource = Get-AzResource -Name $VMName -ResourceType 'Microsoft.Compute/virtualMachines'

        if ($azureResource.Count -lt 1)
        {
            Write-Error -Message "Failed to find $VMName"
        }
        elseif ($azureResource.Count -gt 1)
        {
            Write-Error -Message "Found multiple VMs with the name $VMName. Unable to configure extension"
        }

        $vms += Get-AzVM -Name $VMName -ResourceGroupName $azureResource.ResourceGroupName
    }
}

$workspace = Get-AzOperationalInsightsWorkspace -Name $WorkspaceName -ResourceGroupName $LAResourceGroup -ErrorAction Stop
$key = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $LAResourceGroup -Name $WorkspaceName).PrimarySharedKey

$PublicSettings = @{"workspaceId" = $workspace.CustomerId }
$ProtectedSettings = @{"workspaceKey" = $key }

#Loop through each VM in the array and deploy the extension
foreach ($vm in $vms)
{
  <#  Start-Job -ArgumentList $azContext, $vm, $workspace, $key, $PublicSettings, $ProtectedSettings -ScriptBlock {

        Param
        (
            $azContext,
            $vm,
            $workspace,
            $key,
            $PublicSettings,
            $ProtectedSettings
        )
#>
        $vmStatus = (Get-AzVM -ResourceGroupName $vm.ResourceGroupName -Name $vm.Name -Status).Statuses.DisplayStatus[-1]

        Write-Output "Processing VM: $($vm.Name)"

        if ($vmStatus -ne 'VM running')
        {
            Write-Warning -Message "Skipping VM as it is not currently powered on"
        }

        #Check to see if Linux or Windows
        if ($vm.StorageProfile.OsDisk.OsType -eq 'Windows')
        {
            $extensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name 'Microsoft.EnterpriseCloud.Monitoring' -ErrorAction SilentlyContinue
            #Make sure the extension is not already installed before attempting to install it
            if (-not $extensions)
            {
                Write-Output "Adding MicrosoftMonitoringAgent extension to VM: $($vm.Name)"
                $result = Set-AzVMExtension -ExtensionName "Microsoft.EnterpriseCloud.Monitoring" `
                    -ResourceGroupName $vm.ResourceGroupName `
                    -VMName $vm.Name `
                    -Publisher "Microsoft.EnterpriseCloud.Monitoring" `
                    -ExtensionType "MicrosoftMonitoringAgent" `
                    -TypeHandlerVersion 1.0 `
                    -Settings $PublicSettings `
                    -ProtectedSettings $ProtectedSettings `
                    -Location $vm.Location
            }
            else
            {
                Write-Output "Skipping VM - Extension already installed"
            }
        }
        elseif ($vm.StorageProfile.OsDisk.OsType -eq 'Linux')
        {
            $extensions = Get-AzVMExtension -ResourceGroupName $vm.ResourceGroupName -VMName $vm.Name -Name 'OmsAgentForLinux' -ErrorAction SilentlyContinue

            if($extensions)
            {
                Write-Output "Extensions found"
                Write-Output "================"

                Write-Output $extensions.name
            }
            #Make sure the extension is not already installed before attempting to install it
            if (-not $extensions)
            {
                Write-Output "Adding OmsAgentForLinux extension to VM: $($vm.Name)"
                $result = Set-AzVMExtension -ExtensionName "OmsAgentForLinux" `
                    -ResourceGroupName $vm.ResourceGroupName `
                    -VMName $vm.Name `
                    -Publisher "Microsoft.EnterpriseCloud.Monitoring" `
                    -ExtensionType "OmsAgentForLinux" `
                    -Settings $PublicSettings `
                    -ProtectedSettings $ProtectedSettings `
                    -Location $vm.Location `
                    -TypeHandlerVersion 1.0                    
            }
            else
            {
                Write-Output "Skipping VM - Extension already installed"
            }
        }
    }
#}

$runningJobs = Get-Job -State Running
While ($runningJobs.Count -gt 0)
{
    foreach ($job in $runningJobs)
    {
        Receive-Job $job.Id
    }
    $runningJobs = Get-Job -State Running
}
