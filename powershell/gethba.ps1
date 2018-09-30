$VCenter=Read-Host "Please Enter VCENTER IP or Hostame:"
if ($VCenter -eq "")
{
	exit
}
$Username=Read-Host "Please enter user name:"
if ($Username -eq "")
{
	exit
}
$Password=Read-Host "Please enter password:"
if ($Password -eq "")
{
	exit
}

Echo "Connecting to VCENTER Server "$VCenter

Connect-VIServer -Server $VCenter -Protocol https -User $Username -Password $Password



#Get WWN for cluster 
$Cluster=Read-Host "Please enter Cluster Name:"
if ($Cluster -eq "")
{
	exit
}

$hbas=Get-Cluster $Cluster| Get-VMhost | Get-VMHostHBA -Type FibreChannel
foreach ($hba in $hbas){
	$hostname=$hba.VMHost
	$devicename=$hba.device
	$wwpn="{0:x}" -f $hba.PortWorldWideName
	$wwnn="{0:x}" -f $hba.NodeWorldWideName
	Write-Host $hostname","$devicename","$wwpn","$wwnn
}

disconnect-viserver