Add-PSSnapin VMware.VimAutomation.Core

Function ConnectVcenter
{
	Connect-ViServer -Server $VCenter -Credential $Creds
}
Function DisconnectVcenter
{
	Disconnect-ViServer -Server $VCenter -Confirm:$false
}
Function OpenExcelFile
{
	$before = @(Get-Process [e]xcel | %{$_.Id})
	# Create an Object Excel.Application using Com interface
	$global:objExcel = New-Object -ComObject Excel.Application
	$global:ExcelId = Get-Process excel | %{$_.Id} | ?{$before -notcontains $_}
	# Disable the 'visible' property so the document won't open in excel
	$objExcel.Visible = $true
	# Open the Excel file and save it in $WorkBook
	$global:WorkBook = $objExcel.Workbooks.Open($FilePath)
	# Load the WorkSheet
	$global:WorkSheet = $WorkBook.sheets.item($SheetName)
}
Function CloseExcelFile
{
	$Workbook.Save()
	$Workbook.Close()
	$objExcel.Quit()
	Stop-Process -Id $ExcelId -Force -ErrorAction SilentlyContinue
}
$global:Creds=Get-Credential

$FilePath="c:\users\rrein\documents\Bobs Scripts\Powershell\arep_vm_info.xlsx"
$SheetName="VCENTERS"
OpenExcelFile

$VRowNo=2
$DRowNo=2
$SRowNo=2
$Column="A"
$Range=$Column + $SRowNo


While (1)
{
	$SheetName="VCENTERS"
	$WorkSheet = $WorkBook.sheets.item($SheetName)
	$WorkSheet.Activate()
	$Server=$WorkSheet.Range($Range).text
	
	$Range
	If ($Server -eq "END")
	{
		Break
	}
	$global:VCenter=$Server
	$Server
	ConnectVcenter
	$DataStores=get-datastore | Select Name,FreeSpaceGB,CapacityGB
	ForEach($DataStore in $DataStores)
	{
		
		

		
		if ($DataStore.Name.Contains("arep"))
		{
			$SheetName="DATASTORES"
			$WorkSheet = $WorkBook.sheets.item($SheetName)
			$WorkSheet.Activate()
			$WorkSheet.Cells.Item($DRowNo,1)=$Server
			$Worksheet.Cells.Item($DRowNo,2)=$DataStore.Name
			$WorkSheet.Cells.Item($DRowNo,3)=$DataStore.CapacityGB
			$WorkSheet.Cells.Item($DRowNo,4)=$DataStore.FreespaceGB
			$DRowNo=$DRowNo + 1
			Write-Host "Getting VMs from Datastore:" $DataStore.Name
			$VMS=get-vm -datastore $DataStore.Name
			$SheetName="VMS"
			$WorkSheet = $WorkBook.sheets.item($SheetName)
			$WorkSheet.Activate()
			ForEach($VM in $VMS)
			{
				$WorkSheet.Cells.item($VRowNo,1)=$Server
				$WorkSheet.Cells.item($VRowNo,2)=$DataStore.Name
				$WorkSheet.Cells.item($VRowNo,3)=$VM.Name
				$WorkSheet.Cells.item($VRowNo,4)="{0:N2}" -f $VM.UsedSpaceGB
				$WorkSheet.Cells.item($VRowNo,5)=$VM.NumCpu
				$WorkSheet.Cells.Item($VRowNo,6)=$VM.MemoryGB
				$VRowNo=$VRowNo+1
			}
		}
	}
	$SRowNo=$SRowNo+1
	$Range=$Column + $SRowNo
	Write-Host "Got to End of VCENTER"
	DisconnectVcenter	
	
	
	
}

CloseExcelFile
