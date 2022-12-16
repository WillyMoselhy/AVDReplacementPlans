param VMName string
param VMSize string
param TimeZone string
param Location string = resourceGroup().location
param SubnetID string
param AdminUsername string
@secure()
param AdminPassword string

param AvailabilityZone string

param AcceleratedNetworking bool

param Tags object = {}

param imageReference object

//HostPool join
param HostPoolName string
@secure()
param HostPoolToken string
param WVDArtifactsURL string

// RunCommands
param PreJoinRunCommand array

//Domain Join
param DomainJoinObject object

@secure()
param DomainJoinPassword string = ''

resource vNIC 'Microsoft.Network/networkInterfaces@2022-07-01' = {
  name: '${VMName}-vNIC'
  location: Location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: SubnetID
          }
        }
      }
    ]
    enableAcceleratedNetworking: AcceleratedNetworking
  }
  tags: Tags
}

resource VM 'Microsoft.Compute/virtualMachines@2022-08-01' = {
  name: VMName
  location: Location
  identity: (DomainJoinObject.DomainType == 'AzureActiveDirectory') ? { type: 'SystemAssigned' } : null
  zones: empty(AvailabilityZone) ? [] : [ '${AvailabilityZone}' ]
  properties: {
    osProfile: {
      computerName: VMName
      adminUsername: AdminUsername
      adminPassword: AdminPassword
      windowsConfiguration: {
        timeZone: TimeZone
      }
    }
    hardwareProfile: {
      vmSize: VMSize
    }
    storageProfile: {
      osDisk: {
        name: '${VMName}-OSDisk'
        createOption: 'FromImage'
        deleteOption: 'Delete'
      }
      imageReference: imageReference
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vNIC.id
          properties:{
            deleteOption: 'Delete'
          }
        }
      ]
    }
    licenseType: 'Windows_Client'

  }
  // PreJoin Commands //
  resource PreJoinCommand 'runCommands@2022-08-01' = [for (item, index) in PreJoinRunCommand: {
    name: 'PreJoinCommand${index+1}-${item.Name}'
    location: Location
    properties: {
      source: {
        scriptUri: item.ScriptURL
      }
    }
  }]

  // Domain Join //
  resource AADJoin 'extensions@2022-08-01' = if (DomainJoinObject.DomainType == 'AzureActiveDirectory') {
    name: 'AADLoginForWindows'
    location: Location
    properties: {
      publisher: 'Microsoft.Azure.ActiveDirectory'
      type: 'AADLoginForWindows'
      typeHandlerVersion: '1.0'
      autoUpgradeMinorVersion: true
      settings: json('null') // TODO: Add support for intune managed. string in template is -  "settings": "[if(parameters('intune'), createObject('mdmId','0000000a-0000-0000-c000-000000000000'), json('null'))]"
    }
    dependsOn: PreJoinCommand
  }
  resource DomainJoin 'extensions@2022-08-01' = if (DomainJoinObject.DomainType == 'ActiveDirectory') {
    // Documentation is available here: https://docs.microsoft.com/en-us/azure/active-directory-domain-services/join-windows-vm-template#azure-resource-manager-template-overview
    name: 'DomainJoin'
    location: Location
    properties: {
      publisher: 'Microsoft.Compute'
      type: 'JSonADDomainExtension'
      typeHandlerVersion: '1.3'
      autoUpgradeMinorVersion: true
      settings: {
        Name: DomainJoinObject.DomainName
        OUPath: DomainJoinObject.OUPath
        User: '${DomainJoinObject.DomainName}\\${DomainJoinObject.UserName}'
        Restart: 'true'

        //will join the domain and create the account on the domain. For more information see https://msdn.microsoft.com/en-us/library/aa392154(v=vs.85).aspx'
        Options: 3
      }
      protectedSettings: {
        Password: DomainJoinPassword //TODO: Test domain join from keyvault option
      }
    }
    dependsOn: PreJoinCommand
  }

  // HostPool join //
  resource AddWVDHost 'extensions@2022-08-01' = if (HostPoolName != '') {
    // Documentation is available here: https://docs.microsoft.com/en-us/azure/virtual-machines/extensions/dsc-template
    // TODO: Update to the new format for DSC extension, see documentation above.
    name: 'dscextension'
    location: Location
    properties: {
      publisher: 'Microsoft.PowerShell'
      type: 'DSC'
      typeHandlerVersion: '2.77'
      autoUpgradeMinorVersion: true
      settings: {
        modulesUrl: WVDArtifactsURL
        configurationFunction: 'Configuration.ps1\\AddSessionHost'
        properties: {
          hostPoolName: HostPoolName
          registrationInfoToken: HostPoolToken
          aadJoin: DomainJoinObject.DomainType == 'AzureActiveDirectory' ? true : false
          useAgentDownloadEndpoint: true

        }
      }
    }
    dependsOn: DomainJoinObject.DomainType == 'AzureActiveDirectory' ? [AADJoin] : [DomainJoin]

  }

  tags: Tags
}
