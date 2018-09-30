Function CreateExcel()
{
	#Create excel COM object
	$global:excel = New-Object -ComObject excel.application

	#Make Visible
	$excel.Visible = $True

	#Add a workbook
	$global:workbook = $excel.Workbooks.Add()

	#Remove other worksheets
	1..2 | ForEach {
	    $Workbook.worksheets.item(2).Delete()
	}

	#Connect to first worksheet to rename and make active
	$global:serverInfoSheet = $workbook.Worksheets.Item(1)
	$serverInfoSheet.Name = 'DiskInformation'
	$serverInfoSheet.Activate() | Out-Null

	#Create a Title for the first worksheet and adjust the font
	$row = 1
	$Column = 1
	$serverInfoSheet.Cells.Item($row,$column)= 'VmName'
	$Column = 2
	$serverInfoSheet.Cells.Item($row,$column)= 'Date'
	$Column = 3
	$serverInfoSheet.Cells.Item($row,$column)= 'Power State'
	$Column = 4
	$serverInfoSheet.Cells.Item($row,$column)= 'Disk Path'
	$Column = 5
	$serverInfoSheet.Cells.Item($row,$column)= 'Capacity GB'
	$Column = 6
	$serverInfoSheet.Cells.Item($row,$column)= 'Free GB'
	$Column = 7
	$serverInfoSheet.Cells.Item($row,$column)= 'Used GB'
	$Column = 8
	$serverInfoSheet.Cells.Item($row,$column)= 'Percent Free'
	$Column = 9
	$serverInfoSheet.Cells.Item($row,$column)= 'OS'
	$Column = 10
	$serverInfoSheet.Cells.Item($row,$column)= 'NOTES'
}
$VCenter=Read-Host "Please Enter VCENTER IP or Hostame:"
if ($VCenter -eq "")
{
	exit
}
$Username=Read-Host "Please enter user name:"
if ($Username -eq "")
{
	exit
}
$Password=Read-Host "Please enter password:"
if ($Password -eq "")
{
	exit
}

Echo "Connecting to VCENTER Server "$VCenter

Connect-VIServer -Server $VCenter -Protocol https -User $Username -Password $Password

$date = get-date -format yyyy-MM-dd
$report = @()
$row=1
echo "Processing Each VM"
ForEach ($VM in (Get-Cluster "spn2 zone" | Get-VM |Get-View) | Where {-not $_.Config.Template}){
	Foreach ($disk in $VM.Guest.Disk){
		if ($row -eq 1) 
		{
			CreateExcel
		}
		echo $vm.name
		$row=$row+1
		$column=1
		$Details = "" | Select VmName, Date, PowerState
		$serverInfoSheet.Cells.Item($row,$column)=$vm.name
		$column=$column + 1
		$serverInfoSheet.Cells.Item($row,$column)=$date
		$column=$column + 1
		$serverInfoSheet.Cells.Item($row,$column)=$vm.Runtime.Powerstate
		$column=$column + 1
		$serverInfoSheet.Cells.Item($row,$column)=$Disk.DiskPath
		$cap = ([math]::Round($disk.Capacity/ 1024MB))
		$column=$column + 1
		$serverInfoSheet.Cells.Item($row,$column)=$cap
		$FreeGB = ([math]::Round($disk.FreeSpace / 1024MB))
		$column=$column + 1
		$serverInfoSheet.Cells.Item($row,$column)=$FreeGB
		$UsedGB = ($cap - $freeGB)
		$column=$column + 1
		$serverInfoSheet.Cells.Item($row,$column)=$UsedGB
		$PercentFree= ([math]::Round(((100 * ($disk.FreeSpace))/ ($disk.Capacity)),0))
		$column=$column + 1
		$serverInfoSheet.Cells.Item($row,$column)=$PercentFree
		
		if ($PercentFree -lt 31)
		{
			$serverInfoSheet.Cells.Item($row,$column).Interior.ColorIndex = 3 
		}
		$column=$column + 1
		$serverInfoSheet.Cells.Item($row,$column).Interior.ColorIndex = 0
		$serverInfoSheet.Cells.Item($row,$column)=$VM.Guest.GuestFullName
		$column=$column + 1
		$serverInfoSheet.Cells.Item($row,$column)=$vm.Summary.Config.Annotation
		#$Details.VmName = $vm.name
		#$details.Date = $date
		#$Details.PowerState = $vm.Runtime.Powerstate
		#$cap = ([math]::Round($disk.Capacity/ 1024MB))
		#$FreeGB = ([math]::Round($disk.FreeSpace / 1024MB))
		#$UsedGB = ($cap - $freeGB)
		#$PercentFree= ([math]::Round(((100 * ($disk.FreeSpace))/ ($disk.Capacity)),0))
		#$Details | Add-Member -Name "Disk Path " -MemberType NoteProperty -Value $Disk.DiskPath
		#$Details | Add-Member -Name "Capacity GB" -MemberType NoteProperty -Value $cap
		#$Details | Add-Member -Name "Free GB" -MemberType NoteProperty -Value $FreeGB
		#$Details | Add-Member -Name "Used GB" -MemberType NoteProperty -Value $UsedGB
		#$Details | Add-Member -Name "PercentFree" -MemberType NoteProperty -Value $PercentFree
		#$Details | Add-Member -Name "OS " -MemberType NoteProperty -Value $VM.Guest.GuestFullName
		#$Details | Add-Member -Name "Notes " -MemberType NoteProperty -Value $vm.Summary.Config.Annotation
	}
}
Disconnect-VIServer
$Excel.Application.DisplayAlerts = $False
$Workbook.SaveAS("DiskReport.xls")
$Workbook.Close()
$Excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Workbook)
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel)