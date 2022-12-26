# AVDReplacementPlans
This tool automates the deployment and replacement of session hosts in an Azure Virtual Desktop host pool.
It follows a very simple logic,
- Query the host pool for existing session hosts
- How many session hosts are newer than X number of days?
    - More than X => Remove the old ones.
    - Less than X => Deploy new ones.

The core of an AVD Replacement Plan is an Azure Function App built using PowerShell.

When deploying, the function uses a template and a parameters PowerShell file for the session host. A sample is available [here](SampleSessionHostTemplate).
When deleting an old session host, the function will check if it has existing sessions and,
1. Place the session host drain mode.
2. Send a notification to all sessions.
3. Add a tag to the session host with a timestamp
4. Delete the session host once there are no sessions or the grace period has passed.
