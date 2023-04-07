targetScope = 'subscription'


@description('The URL prefix for remote assets.')
param _artifactsLocation string = 'https://raw.githubusercontent.com/jamasten/FSLogixRemoveExpiredProfiles/main/artifacts/'

@secure()
@description('The SAS Token for the scripts if they are stored on an Azure Storage Account.')
param _artifactsLocationSasToken string = ''

@description('The amount of days to keep an unused FSLogix profile before deleting it.')
param DeleteOlderThanDays int

@allowed([
  'd' // Development
  'p' // Production
  's' // Shared Services
  't' // Test
])
@description('The environment short name used for naming resources in the solution.')
param Environment string = 'd'

@description('The resource IDs of the files shares containing the FSLogix profile and / or ODFC containers.')
param FileShareResourceIds array

@allowed([
  'Day'
  'Week'
  'Month'
])
@description('The frequency in which to check for expired VHDs.')
param Frequency string

@description('Choose whether to enable the Hybrid Use Benefit on the virtual machine.  This is only valid you have appropriate licensing with Software Assurance. https://docs.microsoft.com/en-us/windows-server/get-started/azure-hybrid-benefit')
param HybridUseBenefit bool = false

@maxLength(3)
@description('The unique identifier between each business unit or project supporting AVD in your tenant. This is the unique naming component between each AVD stamp.')
param Identifier string = 'avd'

@description('The deployment location for the solution.')
param Location string = deployment().location

@description('The resource ID for the Log Analytics Workspace to collect log data and send alerts.')
param LogAnalyticsWorkspaceResourceId string = ''

@description('The date and time the tool should run weekly. Ideally select a time when most or all users will offline.')
param RecurrenceDateTime string = '2023-01-01T23:00:00'

@description('The subnet for the AVD session hosts.')
param SubnetName string = 'Clients'

@description('Add key / value pairs to include metadata on the Azure resources.')
param Tags object = {}

@description('DO NOT MODIFY THIS VALUE! The timestamp is needed to differentiate deployments for certain Azure resources and must be set using a parameter.')
param Timestamp string = utcNow('yyyyMMddhhmmss')

@description('Virtual network for the virtual machine to run the tool.')
param VirtualNetworkName string

@description('Virtual network resource group for the virtual machine to run the tool.')
param VirtualNetworkResourceGroupName string

@secure()
@description('The local administrator password for the virtual machine.')
param VmPassword string

@description('The size of the virutal machine that will process the Azure Files shares.')
param VmSize string = 'Standard_D4ds_v5'

@secure()
@description('The local administrator username for the virtual machine.')
param VmUsername string


var AutomationAccountName = 'aa-${NamingStandard}'
var DiskName = 'disk-${NamingStandard}'
var KeyVaultName = 'kv-${NamingStandard}'
var LocationShortName = LocationShortNames[Location]
var LocationShortNames = {
  australiacentral: 'ac'
  australiacentral2: 'ac2'
  australiaeast: 'ae'
  australiasoutheast: 'as'
  brazilsouth: 'bs2'
  brazilsoutheast: 'bs'
  canadacentral: 'cc'
  canadaeast: 'ce'
  centralindia: 'ci'
  centralus: 'cu'
  eastasia: 'ea'
  eastus: 'eu'
  eastus2: 'eu2'
  francecentral: 'fc'
  francesouth: 'fs'
  germanynorth: 'gn'
  germanywestcentral: 'gwc'
  japaneast: 'je'
  japanwest: 'jw'
  jioindiacentral: 'jic'
  jioindiawest: 'jiw'
  koreacentral: 'kc'
  koreasouth: 'ks'
  northcentralus: 'ncu'
  northeurope: 'ne'
  norwayeast: 'ne2'
  norwaywest: 'nw'
  southafricanorth: 'san'
  southafricawest: 'saw'
  southcentralus: 'scu'
  southeastasia: 'sa'
  southindia: 'si'
  swedencentral: 'sc'
  switzerlandnorth: 'sn'
  switzerlandwest: 'sw'
  uaecentral: 'uc'
  uaenorth: 'un'
  uksouth: 'us'
  ukwest: 'uw'
  usdodcentral: 'uc'
  usdodeast: 'ue'
  usgovarizona: 'az'
  usgoviowa: 'ia'
  usgovtexas: 'tx'
  usgovvirginia: 'va'
  westcentralus: 'wcu'
  westeurope: 'we'
  westindia: 'wi'
  westus: 'wu'
  westus2: 'wu2'
  westus3: 'wu3'
}
var NamingStandard = '${Identifier}-${Environment}-${LocationShortName}-fslogix'
var NicName = 'nic-${NamingStandard}'
var ResourceGroupName = 'rg-${NamingStandard}'
var RoleAssignmentResourceGroups = [
  ResourceGroupName
  VirtualNetworkResourceGroupName
]
var RoleDefinitionIds = {
  KeyVaultSecretsUser: '4633458b-17de-408a-b874-0445c86b69e6'
  ManagedIdentityOperator: 'f1a07417-d97a-45cb-824c-7a7467783830'
  Reader: 'acdd72a7-3385-48ef-bd42-f606fba81ae7'
  VirtualMachineContributor: '9980e02c-c2be-4d73-94e8-173b1dc7cf3c'
}
var RunbookName = 'FslogixDiskShrink'
var RunbookScriptName = 'Set-FslogixDiskShrinkVirtualMachine.ps1'
var TemplateSpecName = 'ts-${NamingStandard}'
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
var UserAssignedIdentityName = 'uai-${NamingStandard}'
var VmName = 'vm-${NamingStandard}'


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
    FileShareResourceIds: FileShareResourceIds
    Frequency: Frequency
    HybridUseBenefit: HybridUseBenefit
    KeyVaultName: KeyVaultName
    Location: Location
    LogAnalyticsWorkspaceResourceId: LogAnalyticsWorkspaceResourceId
    NicName: NicName
    RecurrenceDateTime: RecurrenceDateTime
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
    KeyVaultName: KeyVaultName
    Location: Location
    RoleDefinitionIds: RoleDefinitionIds
    SasToken: _artifactsLocationSasToken
    UserAssignedIdentityPrincipalId: userAssignedIdentity.outputs.PrincipalId
    VmPassword: VmPassword
    VmUsername: VmUsername
  }
}
