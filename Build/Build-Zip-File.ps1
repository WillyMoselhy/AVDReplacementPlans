[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $Path = '.\Nightly'
)
$folder = New-Item -Path $Path -ItemType Directory -Force
$zipFilePath = $folder.FullName + "\FunctionApp.zip"
if (Test-Path $zipFilePath) { Remove-Item $zipFilePath -Force }
Compress-Archive -Path .\FunctionApp\* -DestinationPath $folder\FunctionApp.zip -Force -CompressionLevel Optimal