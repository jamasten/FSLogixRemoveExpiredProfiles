param Location string
param TemplateSpecName string

// The Template Spec is deployed by the Automation Runbook to create the virtual machine and run the tool
resource templateSpec 'Microsoft.Resources/templateSpecs@2021-05-01' = {
  name: TemplateSpecName
  location: Location
  properties: {
    description: 'Deploys a virtual machine to run the "FSLogix Disk Shrink" tool against an SMB share containing FSLogix profile containers.'
    displayName: 'Remove Expired FSLogix Containers'
  }
}

resource templateSpecVersion 'Microsoft.Resources/templateSpecs/versions@2021-05-01' = {
  parent: templateSpec
  name: '1.0'
  location: Location
  properties: {
    mainTemplate: loadJsonContent('templateSpecVersion.json')
  }
}

output VersionResourceId string = templateSpecVersion.id
