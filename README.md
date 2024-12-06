# Salesforce Lightning Scheduler for Microsoft 365

Implementation of the `lxscheduler.ServiceResourceScheduleHandler` interface from Salesforce Scheduler to allow using the busytime information coming directly from Microsoft 365 when booking meetings through Salesforce Scheduler. 

## Installation

## Configuration

```
USER_ID=`sfdx force:org:display --json | jq ".result.username" -r`

```

https://help.salesforce.com/articleView?id=sf.ls_ext_cal_integration_troubleshooting.htm&type=5

https://docs.microsoft.com/en-us/graph/auth-limit-mailbox-access
