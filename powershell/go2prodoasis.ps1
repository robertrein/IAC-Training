
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

$node = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a computer name", "Computer", "$env:computername") 
if ($node -eq "") 
{
	exit

}
$PeriodIndex=$node.IndexOf(".")
if ($PeriodIndex -gt 0)
{
	$node=$node.SubString(0,$PeriodIndex)
}
$node

$web = New-Object Net.WebClient
$webpage="http://oasis.uhc.com:9098/OASISServerInfo.svc/OASISInfoByServerName?DeviceName=" + $node
$RESULTS=$web.DownloadString($WEBPAGE)

$webpage

# support stage description
$ResultsLength=($RESULTS.Length)
$SupportStagePositionBegin=$RESULTS.IndexOf("<a:SupportStageDescription>")
$SupportStageBeginLength=("<a:SupportStageDescription>".Length)

$SupportStage=$Results.SubString($SupportStagePositionBegin+$SupportStageBeginLength)
$SupportStageEnd=$SupportStage.IndexOf("</a:SupportStageDescription>")
$SupportStage=$SupportStage.SubString(0,$SupportStageEnd)

# dr code
$ResultsLength=($RESULTS.Length)
$DrCodePositionBegin=$RESULTS.IndexOf("<a:DrCode>")
$DrCodeBeginLength=("<a:DrCode>".Length)

$DrCode=$Results.SubString($DrCodePositionBegin+$DrCodeBeginLength)
$DrCodeEnd=$DrCode.IndexOf("</a:DrCode>")
$DrCode=$DrCode.SubString(0,$DrCodeEnd)
$SupportStage
$DrCode


