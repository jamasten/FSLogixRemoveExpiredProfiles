param DeleteOlderThanDays int
param DiskName string
param FileShareResourceId string
param HybridUseBenefit bool
param Location string
param NicName string
@secure()
param SasToken string
param ScriptUri string
param SubnetName string
param Tags object
param Timestamp string
param UserAssignedIdentityClientId string
param UserAssignedIdentityResourceId string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string
param VmName string
@secure()
param VmPassword string
param VmSize string
@secure()
param VmUsername string


var StorageAccountSuffix = environment().suffixes.storage


resource networkInterface 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: NicName
  location: Location
  tags: Tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(VirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', VirtualNetworkName, SubnetName)
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: true
    enableIPForwarding: false
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: VmName
  location: Location
  tags: Tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${UserAssignedIdentityResourceId}' : {}
    }
}
  properties: {
    hardwareProfile: {
      vmSize: VmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        deleteOption: 'Delete'
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
        name: DiskName
      }
      dataDisks: []
    }
    osProfile: {
      computerName: VmName
      adminUsername: VmUsername
      adminPassword: VmPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: false
      }
      secrets: []
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
          properties: {
            deleteOption: 'Delete'
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    licenseType: HybridUseBenefit ? 'Windows_Server' : null
  }
}

resource extension_CustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: virtualMachine
  name: 'CustomScriptExtension'
  location: Location
  tags: Tags
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${ScriptUri}Remove-ExpiredFslogixDisks.ps1${SasToken}'
      ]
      timestamp: Timestamp
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File Remove-ExpiredFslogixDisks.ps1 -DeleteOlderThanDays ${DeleteOlderThanDays} -Environment ${environment().name} -FileShareResourceId ${FileShareResourceId} -StorageAccountSuffix ${StorageAccountSuffix} -SubscriptionId ${subscription().subscriptionId} -TenantId ${subscription().tenantId} -UserAssignedIdentityClientId ${UserAssignedIdentityClientId}'
    }
  }
}
