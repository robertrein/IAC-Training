Param (
[string]$path
)

$Global:result = Invoke-RestMethod -Headers @{Authorization=("vRealizeOpsToken {0}" -f $token."auth-token"."token"); "Accept"="application/json"} https://vrops-core-elr.uhc.com/suite-api/api/$path

$result