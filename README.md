# Welcome to Azure Virtual Desktop (AVD) Replacement Plans
## Overview
This tool automates the deployment and replacement of session hosts in an Azure Virtual Desktop host pool.
The best practice for AVD recommends replacing the session hosts instead of maintaining them, the AVD Replacement Plans helps you automate the task of replacing old session hosts with new ones automatically.

# Getting started
You can deploy using Bicep. This will create,

1. **Function App**
2. **App Service Plan:** Consumption tier. Used to host the function.
3. **Storage Account:** Utilized by the function App
4. **Log Analytics Workspace:** Used to store Logs and AppService insights


| Deployment Type    | Link                                                                          |
| :----------------- | :---------------------------------------------------------------------------- |
| PowerShell (Bicep) | [![Powershell/Azure CLI](./docs/icons/powershell.png)](./docs/bicepDeploy.md) |

## How it works?
It follows a very simple logic,
- Query the host pool for existing session hosts
- How many session hosts are newer than X number of days?
    - Greater than X => Remove the old ones.
    - Less than X => Deploy new ones.

The core of an AVD Replacement Plan is an Azure Function App built using PowerShell.

When deploying, the function uses a template and a parameters PowerShell file for the session host. A sample is available [here](SampleSessionHostTemplate).

When deleting an old session host, the function will check if it has existing sessions and,
1. Place the session host drain mode.
2. Send a notification to all sessions.
3. Add a tag to the session host with a timestamp
4. Delete the session host once there are no sessions or the grace period has passed.

## Parameters
| Name                                         | required                                  | Description                                                                                                                                                                                                             | Type   | Default                                      |
| -------------------------------------------- | ----------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------ | -------------------------------------------- |
| ADOrganizationalUnitPath                     | Yes, for Active Directory Domain Services | Distinguished Name of the OU to join session hosts to.                                                                                                                                                                  | string |
| AllowDownsizing                              | No                                        | Allow deleting session hosts if count exceeds target.                                                                                                                                                                   | bool   | true                                         |
| AppPlanName                                  | No                                        | App Service Plan Name                                                                                                                                                                                                   | string | Y1 for consumption based plan                |
| AppPlanTier                                  | No                                        | App Service Plan Tier                                                                                                                                                                                                   | string | Dynamic for consumption based plan           |
| DrainGracePeriodHours                        | No                                        | Grace period in hours for session hosts to drain before deletion.                                                                                                                                                       | int    | 24 hours.                                    |
| FixSessionHostTags                           | No                                        | If true, will apply tags for Include In Auto Replace and Deployment Timestamp to existing session hosts. This will not enable automatic deletion of existing session hosts.                                             | bool   | True.                                        |
| FunctionAppName                              | Yes                                       | Name of the Function App.                                                                                                                                                                                               | string |
| FunctionAppZipUrl                            | No                                        | URL of the FunctionApp.zip file. This is the zip file containing the Function App code.                                                                                                                                 | string | The latest release of the Function App code. |
| HostPoolName                                 | Yes                                       | Name of the Azure Virtual Desktop Host Pool.                                                                                                                                                                            | string |
| HostPoolResourceGroupName                    | No                                        | Name of the resource group containing the Azure Virtual Desktop Host Pool.                                                                                                                                              | string | The resource group of the Function App.      |
| Location                                     | No                                        | Region of the Function App. This does not need to be the same as the location of the Azure Virtual Desktop Host Pool.                                                                                                   | string | Location of the resource group.              |
| LogAnalyticsWorkspaceName                    | Yes                                       | Name of the Log Analytics Workspace used by the Function App Insights.                                                                                                                                                  | string |
| MaxSimultaneousDeployments                   | No                                        | Maximum number of session hosts to deploy at the same time.                                                                                                                                                             | int    | 20                                           |
| ReplaceSessionHostOnNewImageVersion          | No                                        | If true, will replace session hosts when a new image version is detected.                                                                                                                                               | bool   | true                                         |
| ReplaceSessionHostOnNewImageVersionDelayDays | No                                        | Delay in days before replacing session hosts when a new image version is detected.                                                                                                                                      | int    | 0 (no delay).                                |
| SessionHostInstanceNumberPadding             | No                                        | Number of digits to use for the instance number of the session hosts (eg. AVDVM-01).                                                                                                                                    | int    | 2                                            |
| SessionHostNamePrefix                        | Yes                                       | Prefix used for the name of the session hosts.                                                                                                                                                                          | string |
| SessionHostParameters                        | Yes                                       | A compressed (one line) json string containing the parameters of the template used to deploy the session hosts.                                                                                                         | string |
| SessionHostTemplateUri                       | Yes                                       | URI of the arm template used to deploy the session hosts.                                                                                                                                                               | string |
| SHRDeploymentPrefix                          | No                                        | Prefix used for the deployment name of the session hosts.                                                                                                                                                               | string | AVDSessionHostReplacer                       |
| StorageAccountName                           | Yes                                       | Name of the storage account used by the Function App. This name must be unique across all existing storage account names in Azure. It must be 3 to 24 characters in length and use numbers and lower-case letters only. | string |
| SubnetId                                     | Yes                                       | Resource ID of the subnet to deploy session hosts to.                                                                                                                                                                   | string |
| SubscriptionId                               | No                                        | Subscription ID of the Azure Virtual Desktop Host Pool.                                                                                                                                                                 | string | The subscription ID of the resource group.   |
| TagDeployTimestamp                           | No                                        | Tag name used to indicate the timestamp of the last deployment of a session host.                                                                                                                                       | string | AutoReplaceDeployTimestamp.                  |
| TagIncludeInAutomation                       | No                                        | Tag name used to indicate that a session host should be included in the automatic replacement process.                                                                                                                  | string | IncludeInAutoReplace.                        |
| TagPendingDrainTimestamp                     | No                                        | Tag name used to indicate drain timestamp of session host pending deletion.                                                                                                                                             | string | AutoReplacePendingDrainTimestamp.            |
| TagScalingPlanExclusionTag                   | No                                        | Tag name used to exclude session host from Scaling Plan activities.                                                                                                                                                     | string | ScalingPlanExclusion                         |
| TargetSessionHostCount                       | Yes                                       | Number of session hosts to maintain in the host pool.                                                                                                                                                                   | int    |
| TargetVMAgeDays                              | No                                        | Target age of session hosts in days.                                                                                                                                                                                    | int    | 45 days.                                     |