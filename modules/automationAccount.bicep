param _artifactsLocation string
@secure()
param _artifactsLocationSasToken string
param AutomationAccountName string
param DeleteOlderThanDays int
param DiskName string
param FileShareResourceIds array
param Frequency string
param HybridUseBenefit bool
param JobScheduleName string = newGuid()
param KeyVaultName string
param Location string
param LogAnalyticsWorkspaceResourceId string
param NicName string
param RoleAssignmentResourceGroups array
param RoleDefinitionIds object
param RunbookName string
param RunbookScriptName string
param SubnetName string
param Tags object
param TemplateSpecVersionResourceId string
param Time string = utcNow()
param TimeZone string
param UserAssignedIdentityClientId string
param UserAssignedIdentityResourceId string
param VirtualNetworkName string
param VirtualNetworkResourceGroupName string
param VmName string
param VmSize string


// The Automation Account stores the runbook that kicks off the tool
resource automationAccount 'Microsoft.Automation/automationAccounts@2021-06-22' = {
  name: AutomationAccountName
  location: Location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    sku: {
      name: 'Free'
    }
  }
}

// The Runbook orchestrates the deployment and manages the resources to run the tool
resource runbook 'Microsoft.Automation/automationAccounts/runbooks@2019-06-01' = {
  parent: automationAccount
  name: RunbookName
  location: Location
  properties: {
    description: 'FSLogix Disk Shrink Automation'
    runbookType: 'PowerShell'
    logProgress: false
    logVerbose: false
    logActivityTrace: 0
    publishContentLink: {
      uri: '${_artifactsLocation}${RunbookScriptName}${_artifactsLocationSasToken}'
      version: '1.0.0.0'
    }
  }
}

resource schedule 'Microsoft.Automation/automationAccounts/schedules@2022-08-08' = {
  parent: automationAccount
  name: '${RunbookName}_${Frequency}'
  properties: {
    frequency: 'Day'
    interval: 1
    startTime: dateTimeAdd(Time, 'PT15M')
    timeZone: TimeZone
  }
}

resource jobSchedule 'Microsoft.Automation/automationAccounts/jobSchedules@2022-08-08' = {
  parent: automationAccount
  #disable-next-line use-stable-resource-identifiers
  name: JobScheduleName
  properties: {
    parameters: {
      _artifactsLoction: _artifactsLocation
      DeleteOlderThanDays: string(DeleteOlderThanDays)
      DiskName: DiskName
      EnvironmentName: environment().name
      FileShareResourceIds: string(FileShareResourceIds)
      HybridUseBenefit: string(HybridUseBenefit)
      KeyVaultName: KeyVaultName
      Location: Location
      NicName: NicName
      ResourceGroupName: resourceGroup().name
      SubnetName: SubnetName
      SubscriptionId: subscription().subscriptionId
      Tags: empty(Tags) ? 'None' : string(Tags)
      TemplateSpecId: TemplateSpecVersionResourceId
      TenantId: subscription().tenantId
      UserAssignedIdentityClientId: UserAssignedIdentityClientId
      UserAssignedIdentityResourceId: UserAssignedIdentityResourceId
      VirtualNetworkName: VirtualNetworkName
      VirtualNetworkResourceGroupName: VirtualNetworkResourceGroupName
      VmName: VmName
      VmSize: VmSize
    }
    runbook: {
      name: runbook.name
    }
    schedule: {
      name: schedule.name
    }
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticsettings@2017-05-01-preview' = if (!empty(LogAnalyticsWorkspaceResourceId)) {
  scope: automationAccount
  name: 'diag-${automationAccount.name}'
  properties: {
    logs: [
      {
        category: 'JobLogs'
        enabled: true
      }
      {
        category: 'JobStreams'
        enabled: true
      }
    ]
    workspaceId: LogAnalyticsWorkspaceResourceId
  }
}

// Gives the Managed Identity for the Automation Account rights to deploy the VM to remove expired FSLogix disks
@batchSize(1)
module roleAssignments_VirtualMachineContributor 'roleAssignments.bicep' = [for i in range(0, length(RoleAssignmentResourceGroups)): {
  name: 'RoleAssignment_${RoleAssignmentResourceGroups[i]}'
  scope: resourceGroup(RoleAssignmentResourceGroups[i])
  params: {
    PrincipalId: automationAccount.identity.principalId
    RoleDefinitionId: RoleDefinitionIds.VirtualMachineContributor
  }
}]

// Gives the Managed Identity for the Automation Account rights to deploy the Template Spec
resource roleAssignment_Reader 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(automationAccount.id, RoleDefinitionIds.Reader, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionIds.Reader)
    principalId: automationAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// Gives the Managed Identity for the Automation Account rights to add the User Assigned Idenity to the virtual machine
resource roleAssignment_ManagedIdentityOperator 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(automationAccount.id, RoleDefinitionIds.ManagedIdentityOperator, resourceGroup().id)
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', RoleDefinitionIds.ManagedIdentityOperator)
    principalId: automationAccount.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
