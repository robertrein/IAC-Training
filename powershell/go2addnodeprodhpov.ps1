
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

$node = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a computer name", "Computer", "$env:computername") 
if ($node -eq "") 
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
	
	$webpage="http://openview.uhc.com/cgi-oo/deviceadd.pl?devices=" + $node + "&type=server&abbr=unk"

}
else
{
	
	$webpage="http://openview.uhc.com/cgi-oo/deviceadd.pl?devices="+ $node + "." + $DomainName + "&type=server&abbr=unk"
}
$IE.navigate2($webpage)
$IE.visible=$true
$node
$webpage