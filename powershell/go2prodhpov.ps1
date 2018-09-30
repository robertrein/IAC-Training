
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

$node = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a computer name", "Computer", "$env:computername") 
if ($node -eq "") 
{
	exit

}
$wenv = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a evironment Code (D-DEV, T-TEST, S-STAGE P-PROD)") 
if ($wenv -eq "") 
{
	exit

}
$webpage=""
Switch($wenv)
{
	"d" {$webpage="http://apsld0024.uhc.com/oo/agentstatus/detail.php?node="}
	"t" {$webpage="http://apslt0053.uhc.com/oo/agentstatus/detail.php?node="}
	"s" {$webpage="http://apsls0063.uhc.com/oo/agentstatus/detail.php?node="}
	"p" {$webpage="http://openview.uhc.com/oo/agentstatus/detail.php?node="}
}
if ($webpage -eq "")
{
	exit
}
if ($node.Contains("."))
{
	Write-Host "Domain Given"
	$DomainName="NONE"

}
else
{
	$DomainName=.\ListBox.ps1 -CommaList "uhc.com,ds3ext.corpdirsvcs.com,ms.ds.uhc.com,NONE" -FormText "Domain Name"
}

$IE=new-object -com internetexplorer.application
if ($DomainName -eq "NONE")
{
	$webpage=$webpage + $node + "&mode=external"
}
else
{
	$webpage=$webpage + $node + "." + $DomainName + "&mode=external"
}
$IE.navigate2($webpage)
$IE.visible=$true
$node
$webpage