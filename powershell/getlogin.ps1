$web = New-Object Net.WebClient
$webpage="http://oasis.uhc.com:9098/OASISServerInfo.svc/OASISInfoByServerName?DeviceName=" + $node




#
#  OK WE EXPECT TO FIND A FILE CALLED getlogin.txt
#
if (test-path .\getlogin.txt)
{
	WRITE-HOST "File getlogin.txt found"
}
else
{
	WRITE-HOST "File getlogin.txt NOT FOUND, EXITING"
	exit
}

# 
#Lets read the file sequentially and start processing
#
$Stream=Get-Content .\getlogin.txt
ForEach($Rec in $Stream)
{
	$RecArray=$Rec.Split(",")
	$node=$RecArray[0]
	$ip=$RecArray[1]
	$domain=$RecArray[2]
	$fqdn=$node + "." + $domain
	WRITE-HOST "Processing Node "$node
	#	
	#Is the machine alive
	#
	Write-Host "Pinging FQDN"
	if ($TestShort=Test-Connection($node) -ErrorAction SilentlyContinue) 
	{
		WRITE-HOST "Response from FQDN for "$node
	}
	else
	{
		WRITE-HOST "No Response from "$fqdn
		continue
	}
	#
	#Now lets get the OASIS server type
	#
	$webpage="http://oasis.uhc.com:9098/OASISServerInfo.svc/OASISInfoByServerName?DeviceName=" + $node
	$RESULTS=$web.DownloadString($webpage)
	$ResultsLength=($RESULTS.Length)
	$OSTypePositionBegin=$RESULTS.IndexOf("<a:OSType>")
	$OSTypeBeginLength=("<a:OSType>".Length)
	$OSType=$Results.SubString($OSTypePositionBegin+$OSTypeBeginLength)
	$OSTypeEnd=$OSType.IndexOf("</a:OSType>")
	$OSType=$OSType.SubString(0,$OSTypeEnd)

	

	$OSType.ToLower()
	Switch ($OSType.ToLower())
	{
		"microsoft"
		{
			Write-Host "OS Type is" $OSTYPE
		}
		"linux"
		{	
			WRITE-hOST "OS Type is" $OSTYPE
		}
	}



}