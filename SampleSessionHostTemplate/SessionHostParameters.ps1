
@{
    VMSize                = 'Standard_D4ds_v5'
    TimeZone              = 'GMT Standard Time	'
    AdminUsername         = 'AVDAdmin'

    AvailabilityZone      = '1' #TODO Distribute on AZs if supported

    AcceleratedNetworking = $true

    Tags                  = @{}

    imageReference        = @{
        publisher = 'MicrosoftWindowsDesktop'
        offer     = 'Windows-11'
        sku       = 'win11-22h2-avd'
        version   = 'latest'
    }

    WVDArtifactsURL       = 'https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip'

    #Domain Join
    DomainJoinObject      = @{
        DomainType = 'ActiveDirectory' # ActiveDirectory or AzureActiveDirectory
        DomainName = 'contoso.com'
        OUPath     = $env:_ADOrganizationalUnitPath
        UserName   = 'AVDDomainJoin'
    }
    DomainJoinPassword    = @{
        reference = @{
            keyVault = @{
                id         = 'KEYVAULT RESOURCE ID'
                secretName = 'AVDDomainJoin'
            }
        }
    }
}