param(
    $SubscriptionId ,
    $ResourceGroupName ,
    $Location ,

    $BicepParams,

    [switch] $AssignPermissions
)
# Validate inputs
if ($StorageAccountName.Length -gt 24) { Throw "StorageAccount name too long" }

# Login in to Azure using the right subscription
$azContext = Set-AzContext -SubscriptionId $SubscriptionId

#region: Create Azure Resource Group
$null = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -Force -ErrorAction Stop
Write-PSFMessage -Level Host -Message "Resource group created or already exists"
#endregion

#region: Create ZIP file of the FunctionApp
# I am only testing the zip file functionality, later this should be from GitHub Actions and the file should be stored as part of the release.
$tempFolderPath = '.\temp'
$tempFolder = New-Item -Path $tempFolderPath -ItemType Directory -Force
$zipFilePath = $tempFolder.FullName + "\FunctionApp.zip"
if (Test-Path $zipFilePath) { Remove-Item $zipFilePath -Force }
Compress-Archive -Path .\FunctionApp\* -DestinationPath $tempFolder\FunctionApp.zip -Force -CompressionLevel Optimal
#endregion


#region: Deploy Azure resources using Bicep template

Write-PSFMessage -Level Host -Message "Deploying Azure resources from Bicep template"

$timestamp = Get-Date -Format FileDateTime
$deployParams = @{
    # Cmdlet parameters
    TemplateFile      = ".\Build\Bicep\FunctionApps.bicep"
    Name              = "DeployFunctionApp-$timestamp"
    ResourceGroupName = $ResourceGroupName
}
$deploy = New-AzResourceGroupDeployment @deployParams @BicepParams -Verbose -ErrorAction Stop

Write-PSFMessage -Level Host -Message "Azure resources deployed."

#endregion

if ($AssignPermissions) {
    #region: Assign permissions
    $permissionsToAssign = @(

        @{
            # FunctionApp MSI should have Desktop Virtualization VM Contributor to Manage HostPools and Session Hosts
            NameForLog         = "FunctionApp MSI Desktop Virtualization Contributor"
            ServicePrincipalId = $deploy.Outputs['functionAppSP'].Value
            RoleName           = 'Desktop Virtualization Virtual Machine Contributor'
            Scope              = "/subscriptions/$SubscriptionId" #TODO: This should be limited to one resource group where the HostPool and VMs are.
        }
        @{
            # FunctionApp MSI should have Table Data Contributor to manage table entries
            NameForLog         = "FunctionApp MSI"
            ServicePrincipalId = $deploy.Outputs['functionAppSP'].Value
            RoleName           = 'Storage Table Data Contributor'
            Scope              = "/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Storage/storageAccounts/{2}/tableServices/default/tables/{3}" -f $SubscriptionId, $ResourceGroupName, $bicepParams.StorageAccountName, $bicepParams.SessionHostDeploymentsTableName
        }

    )
    foreach ($permission in $permissionsToAssign) {
        Write-PSFMessage -Level Host -Message "Checking if {0} has role {1} against {2}" -StringValues $permission['NameForLog'], $permission['RoleName'], $permission['Scope']
        if (-Not (Get-AzRoleAssignment -Scope $permission['Scope'] -RoleDefinitionName $permission['RoleName'] -ObjectId $permission['ServicePrincipalId'] -WarningAction SilentlyContinue)) {
            $null = New-AzRoleAssignment -Scope $permission['Scope'] -RoleDefinitionName $permission['RoleName'] -ObjectId $permission['ServicePrincipalId'] -WarningAction SilentlyContinue
            Write-PSFMessage -Level Host "Assigned permissions for managed identity"
        }
        else {
            Write-PSFMessage -Level Host "Permission already granted!"
        }
    }
    #endregion
}
