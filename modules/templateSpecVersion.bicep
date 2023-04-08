param DeleteOlderThanDays int
param DiskName string
param FileShareResourceIds array
param HybridUseBenefit bool
param KeyVaultName string
param Location string = resourceGroup().location
param NicName string
param SasToken bool
param ScriptUri string
param SubnetName string
param Tags object = {}
param Timestamp string = utcNow('yyyyMMddhhmmss')
param UserAssignedIdentityClientId string
param UserAssignedIdentityResourceId string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string
param VmName string
param VmSize string


resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: KeyVaultName
}

module virtualMachine 'virtualMachine.bicep' = {
  name: 'VirtualMachine_${Timestamp}'
  params: {
    SasToken: SasToken ? keyVault.getSecret('SasToken') : ''
    DeleteOlderThanDays: DeleteOlderThanDays
    DiskName: DiskName
    FileShareResourceIds: FileShareResourceIds
    HybridUseBenefit: HybridUseBenefit
    Location: Location
    NicName: NicName
    ScriptUri: ScriptUri
    SubnetName: SubnetName
    Tags: Tags
    Timestamp: Timestamp
    UserAssignedIdentityClientId: UserAssignedIdentityClientId
    UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
    VirtualNetworkName: VirtualNetworkName
    VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
    VmName: VmName
    VmPassword: keyVault.getSecret('VmPassword')
    VmSize: VmSize
    VmUsername: keyVault.getSecret('VmUsername')

  }
}
