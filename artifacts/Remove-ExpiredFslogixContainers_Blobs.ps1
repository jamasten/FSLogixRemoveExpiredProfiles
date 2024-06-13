param($Timer)

try
{
	##############################################################
    #  Variables
	##############################################################
    # [int]$ExpirationInNumberOfDays = $env:ExpirationInNumberOfDays
	# [string]$StorageAccountName = $env:StorageAccountName
    # [string]$StorageEndpoint = $env:StorageBlobEndpoint

	[int]$ExpirationInNumberOfDays = 90
	[string]$StorageAccountName = ''
	[string]$StorageAccountResourceGroupName = ''


    ##############################################################
    #  Functions
	##############################################################
	function Write-Log 
    {
		[CmdletBinding()]
		param (
			[Parameter(Mandatory = $false)]
			[switch]$Err,

			[Parameter(Mandatory = $true)]
			[string]$Message,

            [Parameter(Mandatory = $true)]
            [string]$StorageAccountName,

			[Parameter(Mandatory = $false)]
			[switch]$Warn
		)

		[string]$MessageTimeStamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss' -AsUTC
		$Message = "[$($MyInvocation.ScriptLineNumber)] [$($StorageAccountName)] $Message"
		[string]$WriteMessage = "[$($MessageTimeStamp)] $Message"

		if ($Err)
        {
			Write-Error $WriteMessage
			$Message = "ERROR: $Message"
		}
		elseif ($Warn)
        {
			Write-Warning $WriteMessage
			$Message = "WARN: $Message"
		}
		else 
        {
			Write-Output $WriteMessage
		}
	}
	

    ##############################################################
    # Set TLS Version
	##############################################################
	# Note: https://stackoverflow.com/questions/41674518/powershell-setting-security-protocol-to-tls-1-2
	# [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


    ##############################################################
    #  Connect to Azure
	##############################################################
    # $AccessToken = $null
    # try
    # {
	# 	$TokenAuthURI = $env:IDENTITY_ENDPOINT + '?resource=https://storage.azure.com&api-version=2019-08-01'
	# 	$TokenResponse = Invoke-RestMethod -Method 'Get' -Headers @{"X-IDENTITY-HEADER"="$env:IDENTITY_HEADER"} -Uri $TokenAuthURI
	# 	$AccessToken = $TokenResponse.access_token
	# 	$Header = @{
	# 		'Authorization'='Bearer ' + $AccessToken
	# 		'x-ms-version'='2020-04-08'
	# 		'x-ms-date'=(Get-Date).ToUniversalTime().ToString('R')
	# 	}
    # }
    # catch
    # {
    #     throw [System.Exception]::new('Failed to authenticate Azure with application ID, tenant ID, subscription ID', $PSItem.Exception)
    # }
    # Write-Log -StorageAccountName $StorageAccountName -Message "Successfully authenticated with Azure using a managed identity"


    ##############################################################
    #  List Containers
	##############################################################
	# $ContainersList = $null
	# try 
	# {
	# 	Write-Log -StorageAccountName $StorageAccountName -Message "List containers for '$StorageAccountName'"
	# 	$Uri = 	'https://' + $StorageAccountName + '.blob.' + $StorageEndpoint + '/?comp=list'
	# 	$ContainersList = Invoke-RestMethod -Headers $Header -Method 'Get' -Uri $Uri

	# 	if (!$ContainersList) 
	# 	{
	# 		throw $ContainersList
	# 	}
	# }
	# catch 
	# {
	# 	throw [System.Exception]::new("Failed to list containers for '$StorageAccountName'. Ensure that you have entered the correct values", $PSItem.Exception)
	# }

	# $xmlObject = [xml]$ContainersList
	# $elementValue = $xmlObject.root.elementName
	# Write-Output $elementValue


	$Context = (Get-AzStorageAccount -ResourceGroupName $StorageAccountResourceGroupName -Name $StorageAccountName).Context

	Write-Log -StorageAccountName $StorageAccountName -Message "Get context for '$StorageAccountName'"

	[array]$Containers = (Get-AzStorageContainer -Context $Context).Name

	foreach ($Container in $Containers)
	{
		Write-Log -StorageAccountName $StorageAccountName -Message "Get containers for '$StorageAccountName/$Container'"

		$VHD = Get-AzStorageBlob -Container $Container -Context $Context | Where-Object {$_.Name -like '*.vhdx' -or $_.Name -like '*.vhd'}

		Write-Log -StorageAccountName $StorageAccountName -Message "Get VHD(X) for '$StorageAccountName/$Container'"

		if($VHD.LastModified.DateTime -lt (Get-Date -AsUTC).AddDays(-$ExpirationInNumberOfDays))
		{
			Write-Log -StorageAccountName $StorageAccountName -Message "'$StorageAccountName/$Container' has expired"

			Remove-AzStorageContainer -Name $Container -Context $Context -Force

			Write-Log -StorageAccountName $StorageAccountName -Message "'$StorageAccountName/$Container' has been removed"
		}
		else {
			Write-Log -StorageAccountName $StorageAccountName -Message "'$StorageAccountName/$Container' has not expired"
		}
	}

}
catch 
{
	$ErrContainer = $PSItem

	[string]$ErrMsg = $ErrContainer | Format-List -Force | Out-String
	$ErrMsg += "Version: $Version`n"

	if (Get-Command 'Write-Log' -ErrorAction:SilentlyContinue)
    {
		Write-Log -StorageAccountName $StorageAccountName -Err -Message $ErrMsg -ErrorAction:Continue
	}
	else
    {
		Write-Error $ErrMsg -ErrorAction:Continue
	}

	throw [System.Exception]::new($ErrMsg, $ErrContainer.Exception)
}