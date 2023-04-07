[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	[string]
	$_artifactsLocation,

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
		_artifactsLocation = $_artifactsLoction
		DeleteOlderThanDays = $DeleteOlderThanDays.ToInt32()
		DiskName = $DiskName
		FileShareResourceIds = $FileShareResourceIds | ConvertFrom-Json
		HybridUseBenefit = $HybridUseBenefit.ToBoolean()
		KeyVaultName = $KeyVaultName
		Location = $Location
		NicName = $NicName
		ResourceGroupName = $ResourceGroupName
		SubnetName = $SubnetName
		Tags = $Tags | ConvertFrom-Json
		TemplateSpecId = $TemplateSpecId
		UserAssignedIdentityClientId = $UserAssignedIdentityClientId
		UserAssignedIdentityResourceId = $UserAssignedIdentityResourceId
		VirtualNetworkName = $VirtualNetworkName
		VirtualNetworkResourceGroupName = $VirtualNetworkResourceGroupName
		VmName = $VmName
		VmSize = $VmSize
	}


	Connect-AzAccount -Environment $EnvironmentName -Tenant $TenantId -Subscription $SubscriptionId -Identity | Out-Null
	Write-Output 'Connected to Azure'

	# Get secure strings from Key Vault and add the values using the Add method for proper deserialization
	$SasToken = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'SasToken').SecretValue
	if($SasToken)
	{
		$Params.Add('_artifactsLocationSasToken', $SasToken)
	}
	$VmPassword = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'VmPassword').SecretValue
	$Params.Add('VmPassword', $VmPassword)
	$VmUsername = (Get-AzKeyVaultSecret -VaultName $KeyVaultName -Name 'VmUsername').SecretValue
	$Params.Add('VmUsername', $VmUsername)
	Write-Output 'Acquired Key Vault secrets'

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