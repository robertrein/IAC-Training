$GotRef="NO"
$GotNode="NO"
$GotIM="NO"
$Reference=""
$Node=""
$IM=""
Remove-Item c:\temp\hpovcheck.txt
Get-ChildItem "C:\temp\hpov check" -Filter *.csv | 
Foreach-Object {
	$File = $_.FullName
	foreach($rec in get-content $file)
	{
		if ($rec.contains("Reference5=") -And $GotRef -eq "NO")
		{
			$location=$rec.IndexOf("Reference5=")
			$rec=$rec.substring($location)
			$location2=$rec.IndexOf(")")
			$rec=$rec.substring(0,$location2)
			$rec=$rec.replace("Reference5=","")
			$Reference=$rec
			$GotRef="YES"
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
	echo $Reference"	"$Node"	"$CSAData"	"$IM >>c:\temp\hpovcheck.txt
	$GotRef="NO"
	$GotNode="NO"
	$GotIM="NO"
	$Reference=""
	$Node=""
	$IM=""

}