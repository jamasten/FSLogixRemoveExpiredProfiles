param SasToken string
param KeyVaultName string
param Location string
param RoleDefinitionIds object
param UserAssignedIdentityPrincipalId string
@secure()
param VmPassword string
@secure()
param VmUsername string


// The Key Vault stores the secrets to deploy virtual machine and mount the SMB share(s)
resource keyVault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: KeyVaultName
  location: Location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableRbacAuthorization: true
    enableSoftDelete: false
    publicNetworkAccess: 'Enabled'
  }
  dependsOn: []
}

// Key Vault Secret for the SAS token on the container in Azure Blobs
resource secret_SasToken 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = if(!empty(SasToken)) {
  parent: keyVault
  name: 'SasToken'
  properties: {
    value: SasToken
  }
}

// Key Vault Secret for the local admin password on the virtual machine
resource secret_VmPassword 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyVault
  name: 'VmPassword'
  properties: {
    value: VmPassword
  }
}

// Key Vault Secret for the local admin username on the virtual machine
resource secret_VmUsername 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
  parent: keyVault
  name: 'VmUsername'
  properties: {
    value: VmUsername
  }
}

// Gives the User Assigned Identity rights to get key vault secrets
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(UserAssignedIdentityPrincipalId, RoleDefinitionIds.KeyVaultSecretsUser, resourceGroup().id)
  scope: keyVault
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionIds.KeyVaultSecretsUser)
    principalId: UserAssignedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
