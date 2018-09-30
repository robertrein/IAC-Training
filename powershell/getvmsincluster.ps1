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
	$serverInfoSheet.Cells.Item($row,$column)= 'Vm Name'
	$column=$column+1
	$serverInfoSheet.Cells.Item($row,$column)= 'Cluster'
	
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

$row=1
echo "Processing Each VM"
ForEach ($VM in (Get-Cluster "OBM_DEVNet 192.168.95.x" | Get-VM |Get-View) | Where {-not $_.Config.Template}){
	if ($row -eq 1) 
	{
		CreateExcel
	}
	echo $vm.name
	$row=$row+1
	$column=1
	$serverInfoSheet.Cells.Item($row,$column)=$vm.name
	$column=$column + 1
	$serverInfoSheet.Cells.Item($row,$column)="DEVNET"
}
Disconnect-VIServer
$Excel.Application.DisplayAlerts = $False
$Workbook.SaveAS("vmincluster.xls")
$Workbook.Close()
$Excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Workbook)
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel)