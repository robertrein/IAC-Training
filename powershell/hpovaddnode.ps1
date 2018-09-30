$GotRef="NO"
$GotNode="NO"
$GotCSAData="NO"
$GotIM="NO"
$Reference=""
$Node=""
$CSAData=""
$IM=""
Remove-Item c:\temp\hpovaddnode.txt
Get-ChildItem "C:\temp\hpov add node" -Filter *.csv | 
Foreach-Object {
	$File = $_.FullName
	foreach($rec in get-content $file)
	{
		if ($rec.contains("Reference3=") -And $GotRef -eq "NO")
		{
			$location=$rec.IndexOf("Reference3=")
			$rec=$rec.substring($location)
			$location2=$rec.IndexOf(",")
			$rec=$rec.substring(0,$location2)
			$rec=$rec.replace("Reference3=","")
			$Reference=$rec
			$GotRef="YES"
		}

		if ($rec.contains("(USR_ORG_ID=") -eq $True -And $GotCSAData -eq "NO")
		{
			$location=$rec.IndexOf("(USR_ORG_ID=")
			$rec=$rec.substring($location)
			$rec=$rec.replace("""","")
			$CSAData=$rec
			$GotCSAData="YES"
		}



		if ($rec.contains("fqdn=") -eq $True -And $GotNode -eq "NO")
		{
			$location=$rec.indexof("fqdn=")
			$rec=$rec.SubString($location)
			$location=$rec.indexof(")")
			$rec=$rec.SubString(0,$location)
			$Node=$rec.Replace("fqdn=","")
			$GotNode="YES"

		}
		if ($rec.contains("IncidentID=IM") -eq $True -And $GotIM -eq "No")
		{
			$location=$rec.indexof("IncidentID=IM")
			$rec=$rec.SubString($location)
			$location2=$rec.IndexOf(";")
			$rec=$rec.SubString(0,$location2)
			$IM=$rec.Replace("IncidentID=","")
			$GotIM="YES"
		}
	}
	echo $Reference"	"$Node"	"$CSAData"	"$IM >>c:\temp\HPOVADDNODE.txt
	$GotRef="NO"
	$GotNode="NO"
	$GotCSAData="NO"
	$GotIM="NO"
	$Reference=""
	$Node=""
	$CSAData=""
	$IM=""

}