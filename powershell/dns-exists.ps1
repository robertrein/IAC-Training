$file = Get-Content dns-exists.txt
remove-item dns-exists-results.txt
Foreach ($server in $file)
{
    
	$Error.Clear()	
	$host_ip = [System.Net.Dns]::GetHostAddresses($server) | Select IPAddressToString
	if ($Error.Count -ne 0)
	{
		$OutString=$server + " NO"
		$OutString >>dns-exists-results.txt
	}
	else
	{
		$OutString=$server + " YES"
		$OutString >>dns-exists-results.txt
	}	
}