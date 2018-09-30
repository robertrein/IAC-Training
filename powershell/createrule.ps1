$SOURCE=READ-HOST -PROMPT "SOURCE"
$DEST=READ-HOST -PROMPT "DEST"
$PORTS=READ-HOST -PROMPT "PORT(S)"
if ($SOURCE.CONTAINS(","))
{
	$sourceArray=$SOURCE.split(",")
}
else
{
	$sourceArray=$SOURCE
}
if ($DEST.CONTAINS(","))
{
	$destArray=$DEST.split(",")
}
else
{
	$destArray=$DEST
}
if ($PORTS.CONTAINS(","))
{
	$portsArray=$PORTS.split(",")
}
else
{
	$portsArray=$PORTS
}
$sourceCount=$sourceArray | measure
$destCount=$destArray | measure
$portsCount=$portsArray | measure

$totalRecords=$sourceCount.count * $destCount.count * $portsCount.count

Write-Host $sourceCount.count, $destCount.count, $portsCount.count, $totalRecords
exit

$outRecord=""
$counter=0

while($counter -lt $totalRecords)
{
	if($counter -lt $sourceCount.count)
	{
		$outSource=$sourceArray[$counter]
		$outDest=$destArray[$counter]
		$outPorts=$portsArray[$counter]
		$counter=$counter + 1
		write-host $outSource,$outDest,$outPorts
		
	}
	else
	{
		$sourceMaxed=1
	}
	if($counter -lt $destCount.count -And $sourceMaxed) 
	{
		$outDest=$destArray[$counter]
		$outPorts=$portsArray[$counter]
		$counter=$counter + 1
		write-host $outSource,$outDest,$outPorts
		continue
	}


	$counter=$counter+1	

}

