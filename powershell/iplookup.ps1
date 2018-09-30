del ipinfo.txt
$DB=Get-Content ip.txt
foreach ($Data in $DB)
{
	$Server=""
	$Server=[System.Net.Dns]::GetHostbyAddress($Data) 
	if ($server -ne "")
	{
		$OutRec=$Server.Hostname + "," + $Server.AddressList >>ipinfo.txt
	}
}