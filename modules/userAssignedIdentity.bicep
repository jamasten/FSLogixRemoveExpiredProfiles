param Location string
param UserAssignedIdentityName string

// The User Assigned Identity is attached to the virtual machine when its deployed so it has access to grab Key Vault secrets
resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: UserAssignedIdentityName
  location: Location
}

output ClientId string = userAssignedIdentity.properties.clientId
output PrincipalId string = userAssignedIdentity.properties.principalId
output ResourceId string = userAssignedIdentity.id
