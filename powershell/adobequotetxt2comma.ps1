remove-item adobequotetxt2comma.xls
$recs=get-content adobequotetxt2comma.txt
foreach($rec in $recs)
{
	if ($rec -eq "OPEN MARKET")
	{
		
		$outrec >>adobequotetxt2comma.xls
		$outrec = ""
		continue
	}
	$rec=$rec -replace ',',''
	$outrec=$outrec + $rec + ","
}