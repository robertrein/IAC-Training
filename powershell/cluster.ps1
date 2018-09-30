Function CreateExcel()
{
	#Create excel COM object
	$global:excel = New-Object -ComObject excel.application

	#Make Visible
	$excel.Visible = $True
	echo $XPath

	if (Test-Path($XPath + "\cluster.xls"))
	{
		$xlCellTypeLastCell = 11 
		$global:Workbook = $Excel.Workbooks.Open($XPath + "\cluster.xls") 
		$global:serverinfosheet = $Workbook.Worksheets.Item(1) 
 
		$a = $serverinfosheet.Activate() 
		$objRange = $serverinfosheet.UsedRange 
		$a = $objRange.SpecialCells($xlCellTypeLastCell).Activate() 
		$intNewRow = $Excel.ActiveCell.Row + 1 
		$strNewCell = "A" + $intNewRow 
		$a = $Excel.Range($strNewCell).Activate() 
		$intNewRow
		$global:row=$intNewRow
	}
	else
	{ 	 
		#Add a workbook
		$global:workbook = $excel.Workbooks.Add()

		#Remove other worksheets
		1..2 | ForEach {
		    $Workbook.worksheets.item(2).Delete()
		}

		#Connect to first worksheet to rename and make active
		$global:serverInfoSheet = $workbook.Worksheets.Item(1)
		$serverInfoSheet.Name = 'Cluster Information'
		$serverInfoSheet.Activate() | Out-Null
		$global:row=1
		#Create a Title for the first worksheet and adjust the font
		$Column = 1
		$serverInfoSheet.Cells.Item($row,$column)= 'Cluster Name'
		$Column = 2
		$serverInfoSheet.Cells.Item($row,$column)= 'Total Hosts'
		$Column = 3
		$serverInfoSheet.Cells.Item($row,$column)= 'Total VMS'
		$Column = 4
		$serverInfoSheet.Cells.Item($row,$column)= 'Total Memory'
		$Column = 5
		$serverInfoSheet.Cells.Item($row,$column)= 'Total CPUmhz'
		$Column = 6
		$serverInfoSheet.Cells.Item($row,$column)= 'AVG CPU %'
		$Column = 7
		$serverInfoSheet.Cells.Item($row,$column)= 'MAX CPU %'
		$Column = 8
		$serverInfoSheet.Cells.Item($row,$column)= 'MIN CPU %'
		$Column = 9
		$serverInfoSheet.Cells.Item($row,$column)= 'AVG MEM %'
		$Column = 10
		$serverInfoSheet.Cells.Item($row,$column)= 'MAX MEM %'
		$Column = 11
		$serverInfoSheet.Cells.Item($row,$column)= 'MIN MEM %'
		$Column = 12
		$serverInfoSheet.Cells.Item($row,$column)= 'Total CPUs Alloc'
		$Column = 13
		$serverInfoSheet.Cells.Item($row,$column)= 'Total Virutal CPU % Over-Commit'
		$Column = 14
		$serverInfoSheet.Cells.Item($row,$column)= 'Total Virtual Memory MB Overcommit for Cluster'
		$Column = 15
		$serverInfoSheet.Cells.Item($row,$column)= 'Total Virtual CPUs Allocated for Cluster'
		$Column = 16
		$serverInfoSheet.Cells.Item($row,$column)= 'Total Physical Memory % OverCommit for cluster'
		$Column = 17
		$serverInfoSheet.Cells.Item($row,$column)= 'Total Physical CPU % OverCommit for cluster'
		$Column = 18
		$serverInfoSheet.Cells.Item($row,$column)= 'Total Physical Memory % OverCommit'
		$global:row=$row+1
	}
}
$global:XPath="C:\clusterrpt"
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

$Cluster=Read-Host "Please enter Cluster Name:"
if ($Cluster -eq "")
{
	exit
}

Echo "Connecting to VCENTER Server "$VCenter

Connect-VIServer -Server $VCenter -Protocol https -User $Username -Password $Password

$TotalHosts=(Get-VMHost -Location $Cluster).Count 
Write-Host $("Total Hosts for Cluster " + $Cluster + " is:" + $TotalHosts)

$TotalVMs=Get-Cluster $Cluster | `Select-Object -Property @{N="Cluster Name";E={$_.Name}},@{N="VMCount";E={@($_ | Get-VM).Count}}
$TotalVMs=$TotalVMs.VMCount
Write-host $("Total VM Servers for Cluster " + $Cluster + " is:" + $TotalVMs)

$TotalMemory=((GET-CLUSTER $Cluster | GET-VMHOST | Measure-Object -Property MemoryTotalMB -Sum).Sum)/1024
Write-host $("Total Memory GB for all VM Hosts for Cluster " + $Cluster + " is:" + [decimal]::round($TotalMemory))

$TotalCPUMhz=(GET-CLUSTER $Cluster | GET-VMHOST | Measure-Object -Property CpuTotalMhz -Sum).Sum
Write-Host $("Total CPU MegaHertz for Cluster " + $Cluster + " is:" + $TotalCPUMhz)

$cpu=Get-Stat -Entity ($Cluster) -start (get-date).AddDays(-30) -Finish (get-date) -stat cpu.usage.average | Measure-Object -Property value -Average -Maximum -Minimum
$CPUMax=[decimal]::round($cpu.Maximum)
$CPUAvg=[decimal]::round($cpu.Average)
$CPUMin=[decimal]::round($cpu.minimum)

Write-Host $("Average CPU % Used for Cluster " + $Cluster + " is:" + $CPUAvg)
write-host $("Maximum CPU % Used for Cluster " + $Cluster + " is:" + $CPUMax)
write-host $("Minimum CPU % Used for Cluster " + $Cluster + " is:" + $CPUMin)


$mem=Get-Stat -Entity ($Cluster) -start (get-date).AddDays(-30) -Finish (get-date) -stat mem.usage.average | Measure-Object -Property value -Average -Maximum -Minimum
$MEMMax=[decimal]::round($mem.Maximum)
$MEMAvg=[decimal]::round($mem.Average)
$MEMMin=[decimal]::round($mem.minimum)

Write-Host $("Average MEM % Used for Cluster " + $Cluster + " is:" + $MEMAvg)
write-host $("Maximum MEM % Used for Cluster " + $Cluster + " is:" + $MEMMax)
write-host $("Minimum MEM % Used for Cluster " + $Cluster + " is:" + $MEMMin)

foreach ($ESX in (GET-CLUSTER $Cluster | GET-VMHOST))
{
	$TotalCPUs=$ESX.NumCpu + $TotalCPUs
	$HostCPUMhz=$HostCPUMhz + ($TotalCPUMhz / $ESX.NumCPU)

}

Write-Host $("Total CPUS allocated for cluster " + $Cluster + " is:" + $TotalCPUs)
#write-Host $("Cpu Megahertz per CPU (Total Cluster Megahertz divided by Total allocated CPU's is:" + $HostCPUMhz)

$TotalVMsEvaluated=0
ForEach ($VM_Server in (GET-CLUSTER $Cluster | GET-VMHOST | Get-VM))
{
	$VMName=$VM_Server
	$VMConfiguredMemMB      = $VMname.MemoryMB
	$VMCPUConfiguredCPU	= $VMname."NumCpu"
	$TotalVMConfiguredCPU=$TotalVMConfiguredCPU + $VMname.NumCpu
	$TotalVMConfiguredMemMB=$TotalVMConfiguredMemMB + $VMConfiguredMemMB
	
	if ($VMName.PowerState -eq "PoweredOn")
	{
		$CPUReadySummation=get-stat -entity $VMname -start (get-date).AddDays(-30) -Finish (get-date) -stat cpu.ready.summation -IntervalMins 120
		$CPUReady=[system.math]::round(($CPUReadySummation | Measure-Object -Property Value -Maximum).maximum,2)
		$CPUReadyPerc=($CPUReady / (7200*1000))*100
		$TotalCPUReadyPerc=$TotalCpuReadyPerc + $CPUReadyPerc
		$TotalVMsEvaluated=$TotalVMsEvaluated + 1
		$MonthlyMemUsageStats=get-stat -entity $VMname -start (get-date).AddDays(-30) -Finish (get-date) -stat mem.usage.average -IntervalMins 120
		$MaxAvgMemUsedPct = [system.math]::round(($MonthlyMemUsageStats | Measure-Object -Property Value -Maximum).maximum,2)
		$MaxAvgMemUsedMB = [system.math]::round(($MaxAvgMemUsedPct / 100.00) * $VMConfiguredMemMB,0)
		$MemOverCommitMB = [system.math]::round(($VMConfiguredMemMB / $MaxAvgMemUsedMB),2)
	}
	


}


$CPUOverCommitMHz=[system.math]::round($TotalCPUReadyPerc/$TotalVMsEvaluated,0)
$TotalVMMem=[system.math]::round($TotalVMConfiguredMemMB / 1024,2)
$TotalPhysicalMemOverCommit=[system.math]::round((($TotalVMMem / $TotalMemory) * 100),2)
$TotalPhysicalCPUOverCommit=($TotalVMConfiguredCPU / $TotalCPUs) * 100
Write-Host $("Total Virtual CPU % Overcommit for Cluster " + $Cluster + " is:" + $CPUOverCommitMHz)
Write-Host $("Total Virtual Memory MB Overcommit for Cluster " + $Cluster + " is:" + $MemOverCommitMB)
Write-Host $("Total Virtual CPU'S Allocated for Cluster " + $Cluster + " is:" + $TotalVMConfiguredCPU)
Write-Host $("Total Memory GB Allocated for Cluster " + $Cluster + " is:" + $TotalVMMem)
Write-Host $("Total Physical CPU % Overcommit for Cluster " + $Cluster + " is:" + $TotalPhysicalCPUOverCommit)
Write-Host $("Total Physical Memory % OverCommit for cluster " + $Cluster + " is:" + $TotalPhysicalMemOverCommit)
CreateExcel
$Column = 1
$serverInfoSheet.Cells.Item($row,$column)= $Cluster
$Column = 2
$serverInfoSheet.Cells.Item($row,$column)= $TotalHosts
$Column = 3
$serverInfoSheet.Cells.Item($row,$column)= $TotalVMs
$Column = 4
$serverInfoSheet.Cells.Item($row,$column)= $TotalMemory
$Column = 5
$serverInfoSheet.Cells.Item($row,$column)= $TotalCPUMhz
$Column = 6
$serverInfoSheet.Cells.Item($row,$column)= $CPUAvg
$Column = 7
$serverInfoSheet.Cells.Item($row,$column)= $CPUMax
$Column = 8
$serverInfoSheet.Cells.Item($row,$column)= $CPUMin
$Column = 9
$serverInfoSheet.Cells.Item($row,$column)= $MEMAvg
$Column = 10
$serverInfoSheet.Cells.Item($row,$column)= $MEMMax
$Column = 11
$serverInfoSheet.Cells.Item($row,$column)= $MEMMin
$Column = 12
$serverInfoSheet.Cells.Item($row,$column)= $TotalCPUs
$Column = 13
$serverInfoSheet.Cells.Item($row,$column)= $CPUOverCommitMHz
$Column = 14
$serverInfoSheet.Cells.Item($row,$column)= $MemOverCommitMB
$Column = 15
$serverInfoSheet.Cells.Item($row,$column)= $TotalVMConfiguredCPU
$Column = 16
$serverInfoSheet.Cells.Item($row,$column)= $TotalVMMem
$Column = 17
$serverInfoSheet.Cells.Item($row,$column)= $TotalPhysicalCPUOverCommit
$Column = 18
$serverInfoSheet.Cells.Item($row,$column)= $TotalPhysicalMemOverCommit
$Excel.Application.DisplayAlerts = $False
$Workbook.SaveAS($XPath + "\Cluster.xls")
$Workbook.Close()
$Excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Workbook)
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Excel)

