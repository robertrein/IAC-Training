$file = Get-Content dns-find_domain.txt
remove-item dns-find_domain-out.txt
Foreach ($server in $file)
{
    
	$NSString=nslookup $server
	$NonExistant=$NSString | select-String "Non-existent"
	if ($NonExistant -eq $NULL)
	{
		$NSString | Select-String "Name:" >>dns-find_domain-out.txt
	}
}