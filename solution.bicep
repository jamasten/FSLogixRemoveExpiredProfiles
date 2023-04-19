targetScope = 'subscription'


@description('The URL prefix for remote assets.')
param _artifactsLocation string = 'https://raw.githubusercontent.com/jamasten/FSLogixRemoveExpiredProfiles/main/artifacts/'

@secure()
@description('The SAS Token for the scripts if they are stored on an Azure Storage Account.')
param _artifactsLocationSasToken string = ''

@maxLength(50)
@minLength(6)
@description('The name of the Azure Automation account.')
param AutomationAccountName string = 'aa-fslogix-mgmt'

@description('The amount of days to keep an unused FSLogix profile before deleting it.')
param DeleteOlderThanDays int = 1

@maxLength(80)
@minLength(1)
@description('The name of the managed disk on the Azure virtual machine')
param DiskName string = 'disk-fslogix-mgmt'

@description('The resource IDs of the files shares containing the FSLogix profile and / or ODFC containers.')
param FileShareResourceId string

@allowed([
  'Daily'
  'Weekly'
  'Monthly'
])
@description('The frequency in which to check for expired VHDs.')
param Frequency string = 'Daily'

@description('Choose whether to enable the Hybrid Use Benefit on the virtual machine.  This is only valid you have appropriate licensing with Software Assurance. https://docs.microsoft.com/en-us/windows-server/get-started/azure-hybrid-benefit')
param HybridUseBenefit bool = false

@maxLength(24)
@minLength(3)
@description('The name of the Azure key vault.')
param KeyVaultName string = 'kv-fslogix-mgmt'

@description('The deployment location for the solution.')
param Location string = deployment().location

@description('The resource ID for the Log Analytics Workspace to collect log data and send alerts.')
param LogAnalyticsWorkspaceResourceId string = ''

@maxLength(80)
@minLength(1)
@description('The name of the network interface on the Azure virtual machine.')
param NicName string = 'nic-fslogix-mgmt'

@maxLength(90)
@minLength(1)
@description('The name of the Azure resource group.')
param ResourceGroupName string = 'rg-fslogix-mgmt'

@description('The name of the subnet for the virtual machine.')
param SubnetName string

@description('Add key / value pairs to include metadata on the Azure resources.')
param Tags object = {}

@maxLength(90)
@minLength(1)
@description('The name of the Azure template spec.')
param TemplateSpecName string = 'ts-fslogix-mgmt'

@description('DO NOT MODIFY THIS VALUE! The timestamp is needed to differentiate deployments for certain Azure resources and must be set using a parameter.')
param Timestamp string = utcNow('yyyyMMddhhmmss')

@maxLength(128)
@minLength(3)
@description('The name of the Azure user assigned managed identity.')
param UserAssignedIdentityName string = 'uai-fslogix-mgmt'

@description('The name of the virtual network for the virtual machine NIC.')
param VirtualNetworkName string

@description('The name of the resource group for the virtual network.')
param VirtualNetworkResourceGroupName string

@maxLength(15)
@minLength(1)
@description('The name of the Azure virtual machine.')
param VmName string = 'vm-fslogix-mgmt'

@secure()
@description('The local administrator password for the virtual machine.')
param VmPassword string

@description('The size of the virutal machine that will process the Azure Files shares.')
param VmSize string = 'Standard_D4ds_v5'

@secure()
@description('The local administrator username for the virtual machine.')
param VmUsername string


var RoleAssignmentResourceGroups = [
  ResourceGroupName
  VirtualNetworkResourceGroupName
]
var RoleDefinitionIds = {
  ManagedIdentityOperator: 'f1a07417-d97a-45cb-824c-7a7467783830'
  Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  ReaderAndDataAccess: 'c12c1c16-33a1-487b-954d-41c89c60f349'
  VirtualMachineContributor: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
}
var RunbookName = 'Remove-ExpiredFslogixContainers'
var RunbookScriptName = 'New-VirtualMachineDeployment.ps1'
var TimeZone = TimeZones[Location]
var TimeZones = {
  australiacentral: 'AUS Eastern Standard Time'
  australiacentral2: 'AUS Eastern Standard Time'
  australiaeast: 'AUS Eastern Standard Time'
  australiasoutheast: 'AUS Eastern Standard Time'
  brazilsouth: 'E. South America Standard Time'
  brazilsoutheast: 'E. South America Standard Time'
  canadacentral: 'Eastern Standard Time'
  canadaeast: 'Eastern Standard Time'
  centralindia: 'India Standard Time'
  centralus: 'Central Standard Time'
  chinaeast: 'China Standard Time'
  chinaeast2: 'China Standard Time'
  chinanorth: 'China Standard Time'
  chinanorth2: 'China Standard Time'
  eastasia: 'China Standard Time'
  eastus: 'Eastern Standard Time'
  eastus2: 'Eastern Standard Time'
  francecentral: 'Central Europe Standard Time'
  francesouth: 'Central Europe Standard Time'
  germanynorth: 'Central Europe Standard Time'
  germanywestcentral: 'Central Europe Standard Time'
  japaneast: 'Tokyo Standard Time'
  japanwest: 'Tokyo Standard Time'
  jioindiacentral: 'India Standard Time'
  jioindiawest: 'India Standard Time'
  koreacentral: 'Korea Standard Time'
  koreasouth: 'Korea Standard Time'
  northcentralus: 'Central Standard Time'
  northeurope: 'GMT Standard Time'
  norwayeast: 'Central Europe Standard Time'
  norwaywest: 'Central Europe Standard Time'
  southafricanorth: 'South Africa Standard Time'
  southafricawest: 'South Africa Standard Time'
  southcentralus: 'Central Standard Time'
  southindia: 'India Standard Time'
  southeastasia: 'Singapore Standard Time'
  swedencentral: 'Central Europe Standard Time'
  switzerlandnorth: 'Central Europe Standard Time'
  switzerlandwest: 'Central Europe Standard Time'
  uaecentral: 'Arabian Standard Time'
  uaenorth: 'Arabian Standard Time'
  uksouth: 'GMT Standard Time'
  ukwest: 'GMT Standard Time'
  usdodcentral: 'Central Standard Time'
  usdodeast: 'Eastern Standard Time'
  usgovarizona: 'Mountain Standard Time'
  usgoviowa: 'Central Standard Time'
  usgovtexas: 'Central Standard Time'
  usgovvirginia: 'Eastern Standard Time'
  westcentralus: 'Mountain Standard Time'
  westeurope: 'Central Europe Standard Time'
  westindia: 'India Standard Time'
  westus: 'Pacific Standard Time'
  westus2: 'Pacific Standard Time'
  westus3: 'Mountain Standard Time'
}


resource roleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, 'CaseWorkerDeploy')
  properties: {
    roleName: 'KeyVaultDeployAction_${subscription().subscriptionId}'
    description: 'Allows a principal to get but not view Key Vault secrets for an ARM template deployment.'
    assignableScopes: [
      subscription().id
    ]
    permissions: [
      {
        actions: [
          'Microsoft.KeyVault/vaults/deploy/action'
        ]
      }
    ]
  }
}

resource rg 'Microsoft.Resources/resourceGroups@2019-10-01' = {
  name: ResourceGroupName
  location: Location
  tags: Tags
  properties: {}
}


// The User Assigned Identity is attached to the virtual machine when its deployed so it has access to grab Key Vault secrets
module userAssignedIdentity 'modules/userAssignedIdentity.bicep' = {
  name: 'UserAssignedIdentityName_${Timestamp}'
  scope: rg
  params: {
    Location: Location
    UserAssignedIdentityName: UserAssignedIdentityName
  }
}

module templateSpec 'modules/templateSpec.bicep' = {
  scope: rg
  name: 'TemplateSpec_${Timestamp}'
  params: {
    Location: Location
    TemplateSpecName: TemplateSpecName
  }
}

module automationAccount 'modules/automationAccount.bicep' = {
  scope: rg
  name: 'AutomationAccount_${Timestamp}'
  params: {
    _artifactsLocation: _artifactsLocation
    _artifactsLocationSasToken: _artifactsLocationSasToken
    AutomationAccountName: AutomationAccountName
    DeleteOlderThanDays: DeleteOlderThanDays
    DiskName: DiskName
    FileShareResourceId: FileShareResourceId
    Frequency: Frequency
    HybridUseBenefit: HybridUseBenefit
    KeyVaultName: KeyVaultName
    Location: Location
    LogAnalyticsWorkspaceResourceId: LogAnalyticsWorkspaceResourceId
    NicName: NicName
    RoleAssignmentResourceGroups: RoleAssignmentResourceGroups
    RoleDefinitionIds: RoleDefinitionIds
    RunbookName: RunbookName
    RunbookScriptName: RunbookScriptName
    SubnetName: SubnetName
    Tags: Tags
    TemplateSpecVersionResourceId: templateSpec.outputs.VersionResourceId
    TimeZone: TimeZone
    UserAssignedIdentityClientId: userAssignedIdentity.outputs.ClientId
    UserAssignedIdentityResourceId: userAssignedIdentity.outputs.ResourceId
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
    VmName: VmName
    VmSize: VmSize
  }
}

module keyVault 'modules/keyVault.bicep' = {
  scope: rg
  name: 'KeyVault_${Timestamp}'
  params: {
    AutomationAccountPrincipalId: automationAccount.outputs.PrincipalId
    KeyVaultName: KeyVaultName
    Location: Location
    RoleDefinitionId: roleDefinition.name
    SasToken: _artifactsLocationSasToken
    VmPassword: VmPassword
    VmUsername: VmUsername
  }
}

module storageRoleAssignments 'modules/roleAssignments.bicep' = {
  scope: resourceGroup(split(FileShareResourceId, '/')[4])
  name: 'RoleAssignment_${split(FileShareResourceId, '/')[4]}'
  params: {
    PrincipalId: userAssignedIdentity.outputs.PrincipalId
    RoleDefinitionId: RoleDefinitionIds.ReaderAndDataAccess
  }
}
