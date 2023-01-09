$TemplateFilePath = '.\Build\Bicep\FunctionApps.bicep'

# Get the template file
$templateFile = Get-Content -Path $TemplateFilePath

# Extract @description lines
$descriptionLines = $TemplateFile | Where-Object { $_ -like "@description(*" }

# for each description, get its index and extract info
$templateParameters = foreach ($line in $descriptionLines) {
    # get the location of this description
    $index = $TemplateFile.IndexOf($line)

    # get parameter details

    if ($line -match "Required:\s*(?<Required>\w+)\s*\|\s*(?<Description>.+)(?:'\)|\s*\|\s*)Default:\s*(?<Default>.+)'\)") {
        $paramRequired = $matches['Required']
        $paramDescription = $matches['Description']
    }
    else{
        Write-Error "Failed to extract parameter description details from line ($index): $line"
    }

    $paramLine = $templateFile[$index + 1]
    if ($paramLine -match '^param\s+(?<Name>\w+)\s+(?<Type>\w+)(?:\s*=\s*(?<DefaultValue>.+))?$') {
        [PSCustomObject]@{
            Name         = $matches['Name']
            Type         = $matches['Type']
            Required     = $paramRequired
            Description  = $paramDescription
            DefaultValue = $matches['DefaultValue']
        }
    }
    else {
        Write-Error "Failed to extract parameter details from line ($index): $line"
    }
}
$templateParameters | ft