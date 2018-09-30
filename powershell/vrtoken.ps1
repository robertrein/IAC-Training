Param (
  [string]$dataCenter
)

switch ($dataCenter.toupper())
{
  "ELR" {$vrops="vrops-core-elr.uhc.com"}
  "CTC" {$vrops="vrops-core-ctc.uhc.com"}
  default {Write-host "Datacenter has to be ELR or CTC"
           exit
          }
}
$Global:token = Invoke-RestMethod https://$vrops/suite-api/api/auth/token/acquire -Method Post -Body '{ "username": "rrein1@ms.ds.uhc.com",  "password": "Aunt13579" }' -ContentType 'application/json'

$Global:auth_token=$token."auth-token"."token"

Write-Host "In the variable named auth_token for the VROPS "$vrops "has been issued and is as follows:"$auth_token
