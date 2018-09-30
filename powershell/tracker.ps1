Param (
	[string]$Check,
	[string]$Node
)


$errorActionPreference = "SilentlyContinue"

Function Get-DNS 
{
	[System.Net.DNS]::GetHostByName($FQDN)
}
Function TEST-PING
{
	ping $FQDN
}
Function GET-OASIS
{
	$PeriodIndex=$FQDN.IndexOf(".")
	if ($PeriodIndex -gt 0)
	{
		$SHORTNAME=$FQDN.SubString(0,$PeriodIndex)
	}
	Else
	{
		$SHORTNAME=$FQDN
	}
	$SHORTNAME
	$web = New-Object Net.WebClient
	$webpage="http://oasis.uhc.com:9098/OASISServerInfo.svc/OASISInfoByServerName?DeviceName=" + $SHORTNAME
	$RESULTS=$web.DownloadString($webpage)
	$RESULTS >temp.txt

	# support stage description
	$ResultsLength=($RESULTS.Length)
	$SupportStagePositionBegin=$RESULTS.IndexOf("<a:SupportStageDescription>")
	$SupportStageBeginLength=("<a:SupportStageDescription>".Length)

	$Global:SupportStage=$Results.SubString($SupportStagePositionBegin+$SupportStageBeginLength)
	$SupportStageEnd=$SupportStage.IndexOf("</a:SupportStageDescription>")
	$Global:SupportStage=$SupportStage.SubString(0,$SupportStageEnd)
	if ($SupportStage.Contains("xmlns"))
	{
		$Global:SupportStage="NONE"
	}

}

$Recs=(Get-Content h:\tracker.csv)[1 .. 9999]
ForEach($Rec in $Recs)
{
	$Fields=$Rec.Split(",")
	$FQDN=$Fields[0].ToLower()
	$WhatToCheck=$Fields[1].ToUpper()
	$Project=$Fields[2]
	$Notes=$Fields[3]
	$ShouldBe=$Fields[4]
	$ESD=$Fields[5]
	$ITG=$Fields[6]


	if ($Check -eq "")
	{
		$a=$b #stupid statement so flow continues
	}
	Else
	{
		if ($Check.ToUpper() -ne $WhatToCheck)
		{

			Continue
		}
	}

	if ($Node.ToLower() -eq "")
	{
		$a=$b #stupid statement so flow continues
	}
	Else
	{
		if ($Node.ToLower() -ne $FQDN)
		{
			Continue
		}
	}

	GET-OASIS
	Write-Host -foregroundcolor "magenta" "========================================="
	Write-Host "FQDN IS IN OASIS AS "$SupportStage
	Write-Host "Checking" $WhatToCheck "for" $FQDN "on Project" $Project "Notes on this are" $Notes "and it should be" $ShouldBe

	Switch ($WhatToCheck)
	{
		"DNS" {Get-DNS}
		"PING" {TEST-PING}

		default {"The What to Check is not defined"}
	}
	Write-Host -foregroundcolor "magenta" "========================================="
}