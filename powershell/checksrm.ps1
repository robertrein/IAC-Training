$User="ms\psslfsvc"
$Password="vYrN51Nm"
add-pssnapin VMware.VimAutomation.Core
$content = Get-Content .\vcenterssrm.txt
foreach ($line in $content)
{
	$CommaLoc=$line.Indexof(",")
	$VCenter=$line.Substring(0,$Commaloc)
	$SRM=$line.Substring($Commaloc + 1)
	$Vcenter=Connect-VIServer -Server $VCenter -User $User -Password $Password
	$Srm=Connect-SrmServer -RemoteUser $user -RemotePassword $Password

}