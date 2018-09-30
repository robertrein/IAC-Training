$web = New-Object Net.WebClient
#$webpage="http://openview.uhc.com/oo/agentstatus/detail.php?node=" + $node + "&mode=external"
$webpage="http://openview.uhc.com/oo/agentstatus/detail.php?node=apsrs2272.uhc.com&mode=external"
$RESULTS=$web.DownloadString($webpage)
$Results
