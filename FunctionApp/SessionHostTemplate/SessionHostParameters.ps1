
@{
    VMSize                = 'Standard_D4ds_v5'
    TimeZone              = 'Arab Standard Time'
    SubnetID              = '/subscriptions/3499fb03-2a71-4296-ba87-6e140b0540f6/resourceGroups/A1Production_vNet/providers/Microsoft.Network/virtualNetworks/A1Production_vNet/subnets/default'
    AdminUsername         = 'AVDAdmin'

    AvailabilityZone      = '1' #TODO Distribute on AZs if supported

    AcceleratedNetworking = $true

    Tags                  = @{}

    imageReference        = @{
        publisher = 'MicrosoftWindowsDesktop'
        offer     = 'Windows-10'
        sku       = 'win10-21h2-avd-g2'
        version   = 'latest'
    }

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
        OUPath     = 'OU=HostPool1,OU=AVD,DC=Contoso,DC=com'
        UserName   = 'AVD.DomainJoin'
    }
    DomainJoinPassword = @{
        reference = @{
            keyVault = @{
                id = 'THIS SHOULD INCLUDE THE RESOURCE ID OF THE KEYVAULT'
            }
            secretName = 'AVDDomainJoin'
        }
    }

}