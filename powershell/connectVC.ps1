$VCenter=Read-Host "Please Enter VCENTER IP or Hostame:"
if ($VCenter -eq "")
{
	exit
}
$Username=Get-Credential
if ($Username -eq "")
{
	exit
}


Echo "Connecting to VCENTER Server "$VCenter

Connect-VIServer -Server $VCenter -Protocol https -Credential $Username