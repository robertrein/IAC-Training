$OutArray = @()
Connect-VIServer rz050mn011v2gc.optumfe.com
remove-item .\ckofe.txt
$vms=Get-Content .\temp.txt
foreach($vm in $vms)
{ 
	$myobj="" | select "vm","numcpu","memorygb","capacitygb","filename"
	$info1=get-vm $vm
	$disks=get-harddisk $vm
	foreach($disk in $disks)
	{
		$myobj.vm= $vm
		$myobj.numcpu=$info1.numcpu
		$myobj.memorygb=$info1.memorygb
		$myobj.capacitygb=$disk.capacitygb
		$myobj.filename=$disks.filename
		$outArray += $myobj
		$myobj=$null
	}
}
$OutArray | export-csv ".\ckofe.txt"