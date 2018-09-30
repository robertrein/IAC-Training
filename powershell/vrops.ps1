$msid = Read-Host "Secondary MSID: "
$securepw = Read-Host "Password " -AsSecureString
$server = Read-Host "Server "

$pw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepw))

$body = '{ "username": "' + $msid + '@ms.ds.uhc.com",  "password": "' + $pw + '" }'

$token = Invoke-RestMethod 'https://vrops-core-elr.uhc.com/suite-api/api/auth/token/acquire' -Method Post -Body $body -ContentType 'application/json'
$tokenelr = $token."auth-token".token

token = Invoke-RestMethod 'https://vrops-core-ctc.uhc.com/suite-api/api/auth/token/acquire' -Method Post -Body $body -ContentType 'application/json'
$tokenctc = $token."auth-token".token


$resource = Invoke-RestMethod -Headers @{Authorization=("vRealizeOpsToken {0}" -f $tokenelr)} https://vrops-core-elr.uhc.com/suite-api/api/resources?name=$server
#$resource."identifier"

$identifier = $resource.resources.resource.identifier

#$result = Invoke-RestMethod -Headers @{Authorization=("vRealizeOpsToken {0}" -f $tokenelr)} https://vrops-core-elr.uhc.com/suite-api/api/resources/$identifier/properties
$result = Invoke-RestMethod -Headers @{Authorization=("vRealizeOpsToken {0}" -f $tokenelr); "Accept"="application/json"} https://vrops-core-elr.uhc.com/suite-api/api/resources/$identifier/properties

$result.property
