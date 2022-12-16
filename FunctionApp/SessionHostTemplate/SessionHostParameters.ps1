
@{
    #VMName                = 'A1VDIKIPIC-3'
    VMSize                = 'Standard_D4ds_v5'
    TimeZone              = 'Arab Standard Time'
    #Location              = 'westeurope'
    SubnetID              = '/subscriptions/3499fb03-2a71-4296-ba87-6e140b0540f6/resourceGroups/A1Production_vNet/providers/Microsoft.Network/virtualNetworks/A1Production_vNet/subnets/default'
    AdminUsername         = 'KIPICAdmin'

    AvailabilityZone      = '1' #TODO Distribute on AZs if supported

    AcceleratedNetworking = $true

    Tags                  = @{}

    imageReference        = @{
        publisher = 'MicrosoftWindowsDesktop'
        offer     = 'Windows-10'
        sku       = 'win10-21h2-avd-g2'
        version   = 'latest'
    }

    #HostPool join
    #HostPoolName = $HostPoolName
    #HostPoolToken = $HostPoolToken.Token
    WVDArtifactsURL = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip'

    #RunCommands
    PreJoinRunCommand = @(
        @{
            Name = 'DeployApps'
            ScriptURL = 'https://stavdweusourceskipic.blob.core.windows.net/aibcustomization/deployApps.ps1'
        }
    )

    #Domain Join
    DomainJoinObject = @{
        DomainType = 'ActiveDirectory' # ActiveDirectory or AzureActiveDirectory
        DomainName = 'kipic.local'
        OUPath     = 'OU=VDI,OU=Computers,OU=IT,OU=Olympia,OU=KIPIC,DC=kipic,DC=local'
        UserName   = 'AVD.DomainJoin'
    }
    DomainJoinPassword = @{
        reference = @{
            keyVault = @{
                id = '/subscriptions/3499fb03-2a71-4296-ba87-6e140b0540f6/resourceGroups/rg-avd-weu-shared-services/providers/Microsoft.KeyVault/vaults/kv-avd-weu-tjuypz'
            }
            secretName = 'AVDDomainJoin'
        }
    }#'BdE%8ma7zJz?R$u??zGXe5A8QAN5cPuH'

}