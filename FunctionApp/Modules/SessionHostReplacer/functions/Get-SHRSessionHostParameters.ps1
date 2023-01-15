function Get-SHRSessionHostParameters {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string] $SessionHostTemplateParametersPS1Uri = $env:_SessionHostTemplateParametersPS1Uri
    )

    Write-PSFMessage -Level Host -Message "Downloading template parameter PS1 file from {0} (SAS redacted)" -StringValues ($SessionHostTemplateParametersPS1Uri -replace '\?.+','')
    $sessionHostParametersPS1 = Invoke-RestMethod -Uri $SessionHostTemplateParametersPS1Uri -ErrorAction Stop

    Invoke-Expression $sessionHostParametersPS1
}