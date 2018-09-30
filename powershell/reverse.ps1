Param(
  [string]$computerName,
  [string]$outputFile
)
if ($outputFile -eq "")
{
	Write-Output "No Output file given"
	exit
}
$results = nslookup $computerName
$results = $results -match "Name:"
$results = $results -replace "Name:",""
$results = $results -replace " ",""
$outputString=$computerName + "," + $results
$outputString >>$outputFile