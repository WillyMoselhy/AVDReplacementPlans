function Get-SHRLatestImageVersion {
    [CmdletBinding()]
    param (
        # An Image reference object. Can be from Marketplace or Shared Image Gallery.
        [Parameter()]
        [hashtable] $ImageReference
    )

    # Marketplace image
    if ($ImageReference.publisher) {
        #TODO Do we need to change location here?
        if ($ImageReference.version -ne 'latest') {
            Write-PSFMessage -Level Host -Message "Image version is not set to latest. Returning version {0}" -StringValues $ImageReference.version
            $azImageVersion = $ImageReference.version
        }
        else {
            # Get the Images and select the latest version.
            $paramGetAzVMImage = @{
                Location      = 'WestEurope'
                PublisherName = $ImageReference.publisher
                Offer         = $ImageReference.offer
                Skus          = $ImageReference.sku
            }
            Write-PSFMessage -Level Host -Message "Getting latest version of image {0} {1} {2} {3}" -StringValues $paramGetAzVMImage.Location, $paramGetAzVMImage.PublisherName, $paramGetAzVMImage.Offer, $paramGetAzVMImage.Skus
            $azImageVersion = (Get-AzVMImage @paramGetAzVMImage -Top 1).Version
            Write-PSFMessage -Level Host -Message "Latest version of image is {0}" -StringValues $azImageVersion

            if($azImageVersion -match "\d+\.\d+\.(?<Year>\d{2})(?<Month>\d{2})(?<Day>\d{2})"){
                $azImageDate = Get-Date -Date ("20{0}-{1}-{2}" -f $Matches.Year, $Matches.Month, $Matches.Day)
                Write-PSFMessage -Level Host -Message "Image date is {0}" -StringValues $azImageDate
            }
            else{
                throw "Image version does not match expected format. Could not extract image date."
            }
        }
    }
    else {
        throw "This code does not yet support gallery images."
        #TODO: Add logic for gallery image
    }
    #return output
    [PSCustomObject]@{
        Version = $azImageVersion
        Date    = $azImageDate
    }
}
