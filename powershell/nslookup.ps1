Param(
  [string]$computerName
)

$results = nslookup $computerName
$results = $results -match "Name:"
$results = $results -replace "Name:",""
$results = $results -replace " ",""
write-host $computerName,$results