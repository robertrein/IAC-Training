$Threads=Read-Host How many threads to want to run
$inputFile=Read-Host Path to input file
if (Test-Path $inputFile) 
{
	$vmsToBuild=get-content $inputFile
	foreach($vm in $vmsToBuild)
	{
		$vmsToBuildCtr=$vmsToBuildCtr + 1
	}
}
else
{
	Write-Host Input file $inputFile does not exist
	exit
}
Write-Host $vmsToBuildCtr VMs to process
$loopCtr=0
foreach($vm in $vmsToBuild)
{
	$loopCtr=$loopCtr + 1
	$outputFile=$inputFile+"_"+$loopCtr+".txt"
	echo "Name,Template,DestinationHost,CustomSpec,NumCpu,MemoryMB" >.\$outputFile

	if($loopCtr -eq $Threads)
	{
		$loopCtr=0
	}
}
foreach($vm in $vmsToBuild)
{
	$loopCtr=$loopCtr + 1
	$outputFile=$inputFile+"_"+$loopCtr+".txt"
	$vm >>.\$outputFile
	if($loopCtr -eq $Threads)
	{
		$loopCtr=0
	}
}

$loopCtr=0
while($loopCtr -lt $Threads)
{
	$loopCtr=$loopCtr+1
	$inFile=$inputFile+"_"+$loopCtr+".txt"
	start-process powershell -Argumentlist ".\brutebuild.ps1 -inputFile $inFile"
	
}

while(1)
{
	Write-Host "Keep this window open so the server does not time you out after 15 minutes"
	sleep 60
}