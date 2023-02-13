$GraphAppId = "00000003-0000-0000-c000-000000000000"
$graphSP = Get-MgServicePrincipal -Search "AppId:$GraphAppId" -ConsistencyLevel eventual
$msGraphPermissions = @(
    'Device.Read.All' #Used to read user and group permissions
)
$msGraphAppRoles = $graphSP.AppRoles | Where-Object { $_.Value -in $msGraphPermissions }
$FunctionSP = '0339546a-7b93-481b-a011-5d6d91302ce5'
$msGraphAppRoles | ForEach-Object {
    $params = @{
        PrincipalId = $FunctionSP
        ResourceId  = $graphSP.Id
        AppRoleId   = $_.Id
    }
    New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $FunctionSP -BodyParameter $params
}