function Remove-SHRSessionHost {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        $SessionHostsPendingDelete,

        [Parameter()]
        [string] $ResourceGroupName = $env:_HostPoolResourceGroupName,

        [Parameter()]
        [string] $HostPoolName = $env:_HostPoolName,

        [Parameter()]
        [int] $DrainGracePeriodHours = $env:_DrainGracePeriodHours,

        [Parameter()]
        [string] $tagPendingDrainTimeStamp = $env:_Tag_PendingDrainTimestamp
    )

    foreach($sessionHost in $SessionHostsPendingDelete){
        # Does the session host currently have sessions?
            # No sessions => Delete + Remove from host pool
        # Is the session host in drain mode?
            # Yes => Is the drain grace period tag old? => Delete + Remove from host pool
            # NO => Set drain mode + Message users + Set tag


        if($sessionHost.Session -eq 0){ #Does the session host currently have sessions?
             # No sessions => Delete + Remove from host pool
            Write-PSFMessage -Level Host -Message 'Session host {0} has no sessions.' -StringValues $sessionHost.FQDN
            $deleteSessionHost = $true
        }
        else{
            if(-Not $sessionHost.AllowNewSession){ # Is the session host in drain mode?
                Write-PSFMessage -Level Host -Message 'Session host {0} is in drain mode.' -StringValues $sessionHost.FQDN

                if($sessionHost.PendingDrainTimeStamp){ #Session host has a drain timestamp
                    Write-PSFMessage -Level Host -Message 'Session Host {0} drain timestamp is {1}' -StringValues $sessionHost.FQDN, $sessionHost.PendingDrainTimeStamp
                    $maxDrainGracePeriodDate = $sessionHost.PendingDrainTimeStamp.AddHours($DrainGracePeriodHours)
                    Write-PSFMessage -Level Host -Message 'Session Host {0} can stay in grace period until {1}' -StringValues $sessionHost.FQDN, $maxDrainGracePeriodDate.ToUniversalTime().ToString('o')
                    if($maxDrainGracePeriodDate -lt (Get-Date)){
                        Write-PSFMessage -Level Host -Message 'Session Host {0} has exceeded the drain grace period.' -StringValues $sessionHost.NFQDNme
                        $deleteSessionHost = $true
                    }
                    else{
                        Write-PSFMessage -Level Host -Message 'Session Host {0} has not exceeded the drain grace period.' -StringValues $sessionHost.FQDN
                    }
                }
                else{
                    Write-PSFMessage -Level Host -Message 'Session Host {0} does not have a drain timestamp.' -StringValues $sessionHost.FQDN
                    $drainSessionHost = $true
                }
            }
            else{
                Write-PSFMessage -Level Host -Message 'Session host {0} in not in drain mode. Turning on drain mode.' -StringValues $sessionHost.Name
                $drainSessionHost = $true
            }
        }


        if($drainSessionHost){
            Write-PSFMessage -Level Host -Message 'Turning on drain mode.'
            Update-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName $HostPoolName -Name $sessionHost.FQDN -AllowNewSession:$false -ErrorAction Stop

            $drainTimestamp = (Get-Date).ToUniversalTime().ToString('o')
            Write-PSFMessage -Level Host -Message 'Setting drain timestamp on tag {0} to {1}.' -StringValues $tagPendingDrainTimeStamp,$drainTimestamp
            Update-AzTag -ResourceId $sessionHost.ResourceId -Tag @{$tagPendingDrainTimeStamp = $drainTimestamp} -Operation Merge

            Write-PSFMessage -Level Host -Message 'Notifying Users'
            Send-SHRDrainNotification -SessionHostName ($sessionHost.FQDN)
        }

        if($deleteSessionHost){
            Write-PSFMessage -Level Host -Message 'Deleting session host {0}...' -StringValues $sessionHost.Name

            Write-PSFMessage -Level Host -Message 'Removing Session Host from Host Pool {0}' -StringValues $HostPoolName
            Remove-AzWvdSessionHost -ResourceGroupName $ResourceGroupName -HostPoolName  $HostPoolName -Name $sessionHost.FQDN -Force -ErrorAction Stop

            Write-PSFMessage -Level Host -Message "Deleting VM: {0}..." -StringValues $sessionHost.ResourceId
            Remove-AzVM -Id $sessionHost.ResourceId -ForceDeletion $true -Force -NoWait -ErrorAction Stop
                # We are not deleting Disk and NIC as the template should mark the delete option for these resources.
        }
    }
}