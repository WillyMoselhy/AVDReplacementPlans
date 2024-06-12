$ResourceGroupName = 'rg-us1-prd-avd-session-host-functions'
$params = @{
    SubscriptionId    = '<subscriptionn-id>'
    ResourceGroupName = 'rg-us1-prd-vdi-avd-session-host-functions'
    Location          = 'EastUs'
    AssignPermissions = $false
    BicepParams       = @{
        #Storage Account
        StorageAccountName                  = '<storage-account-name>'

        #Log Analytics Workspace
        LogAnalyticsWorkspaceName           = '<log-anayltics-workspace-name>'
        #FunctionApp
        AppServicePlanName                  = '<app-service-plan-name>'
    }
}

$paramsNewAzResourceGroupDeployment = @{
    # Cmdlet parameters
    TemplateFile            = ".\Build\Bicep\Deploy-App-Plan.bicep"
    AppPlanName             = 'B1'
    AppPlanTier             = 'Basic'
    ResourceGroupName       = $ResourceGroupName
    TemplateParameterObject = $params.BicepParams
}

New-AzResourceGroupDeployment @paramsNewAzResourceGroupDeployment -Verbose