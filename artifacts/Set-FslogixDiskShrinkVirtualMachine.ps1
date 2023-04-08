[CmdletBinding(SupportsShouldProcess)]
param(
    [parameter(Mandatory)]
    [string]
    $DeleteOlderThanDays,

	[parameter(Mandatory)]
    [string]
    $DiskName,

	[Parameter(Mandatory)]
	[string]
	$EnvironmentName,

	[Parameter(Mandatory)]
	[string]
	$FileShareResourceIds,

	[Parameter(Mandatory)]
	[string]
	$HybridUseBenefit,

	[Parameter(Mandatory)]
	[string]
	$KeyVaultName,

	[Parameter(Mandatory)]
	[string]
	$Location,

	[Parameter(Mandatory)]
	[string]
	$NicName,

	[Parameter(Mandatory)]
	[string]
	$ResourceGroupName,

	[Parameter(Mandatory)]
	[string]
	$ScriptUri,
	
	[Parameter(Mandatory)]
	[string]
	$SubnetName,

	[Parameter(Mandatory)]
	[string]
	$SubscriptionId,

	[Parameter(Mandatory)]
	[string]
	$Tags,

	[Parameter(Mandatory)]
	[string]
	$TemplateSpecId,

	[Parameter(Mandatory)]
	[string]
	$TenantId,

	[Parameter(Mandatory)]
	[string]
	$UserAssignedIdentityClientId,

	[Parameter(Mandatory)]
	[string]
	$UserAssignedIdentityResourceId,

	[Parameter(Mandatory)]
	[string]
	$VirtualNetworkName,

	[Parameter(Mandatory)]
	[string]
	$VirtualNetworkResourceGroupName,

	[Parameter(Mandatory)]
	[string]
	$VmName,

	[Parameter(Mandatory)]
	[string]
	$VmSize
)

$ErrorActionPreference = 'Stop'

try 
{
	# Import required modules
	Import-Module -Name 'Az.Accounts'
	Import-Module -Name 'Az.KeyVault'
	Import-Module -Name 'Az.Resources'
	Write-Output 'Imported modules successfully'

	$Params = @{		
		DeleteOlderThanDays = $DeleteOlderThanDays.ToInt32()
		DiskName = $DiskName
		FileShareResourceIds = $FileShareResourceIds | ConvertFrom-Json
		HybridUseBenefit = $HybridUseBenefit.ToBoolean()
		KeyVaultName = $KeyVaultName
		Location = $Location
		NicName = $NicName
		ResourceGroupName = $ResourceGroupName
		ScriptUri = $ScriptUri
		SubnetName = $SubnetName
		TemplateSpecId = $TemplateSpecId
		UserAssignedIdentityClientId = $UserAssignedIdentityClientId
		UserAssignedIdentityResourceId = $UserAssignedIdentityResourceId
		VirtualNetworkName = $VirtualNetworkName
		VirtualNetworkResourceGroupName = $VirtualNetworkResourceGroupName
		VmName = $VmName
		VmSize = $VmSize
	}

	# Add conditional params
	if(!($Tags -eq 'None'))
	{
		$Tags = $Tags | ConvertFrom-Json
		$Params.Add('Tags', $Tags)
	}

	# Connect to Azure
	Connect-AzAccount -Environment $EnvironmentName -Tenant $TenantId -Subscription $SubscriptionId -Identity | Out-Null
	Write-Output 'Connected to Azure'

	# Deploy the virtual machine & run the tool
	New-AzResourceGroupDeployment @Params
	Write-Output 'Removed expired FSLogix profiles'

	# Delete the virtual machine
	Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $VmName -Force
	Write-Output 'Removed virtual machine successfully'
}
catch
{
	Write-Output 'Failed to remove expired FSLogix profiles'
	Write-Output $_.Exception
	throw
}