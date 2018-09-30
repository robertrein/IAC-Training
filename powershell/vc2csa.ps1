Param(
  [string]$VCenterName,
  [string]$user,
  [string]$pass,
  [string]$fileName
)


$String2Compare="""" + "VCenter" + """" + "," + """" + "hostname" + """" + "," + """" + "notes" + """"

$WarningPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"
add-PSSnapin VMware.VimAutomation.Core
Write-Host "Processing VCenter:"$VCenterName
$Nothing=Connect-VIServer $VCenterName -User $user -Password $pass
#Change the above line to include any of the vcenters you wish to inventory.
#Example of multiple connections -- Connect-VIServer 'apsed1471','apsed1475'
$date = Get-Date -UFormat %y%m%d
$path = "E:\TEMP\" + $VCenterName + $date + ".csv"
$finalpath="E:\TEMP\" + $fileName
$report = @()
$pattern = "Requesting user: (.*)`n"
$pattern2 = "Subscription ID: (.*)`n"
$pattern3 = "CSA server: (.*)`n?"
$pattern4 = "Created on (.*)`n?"
$pattern5 = "Service Offering: (.*)`n?"

#$vmx = get-vm | sort name | Where-Object { $_.notes -match "Self Service" -and $_.notes -notlike "*DND*" } 
$vmx = get-vm | sort name
CD e:\temp
ForEach ($vm in $vmx){
    $line = "" | select VCenter,hostname,notes,folder,primaryIP,priDNS,backupIP,buDNS,user,cUUID,srcCSA,srcDate,offering,BuildEnv
    $line.VCenter=$VCenterName
    $line.hostname = $vm.name
	$line.folder = $vm.folder.name
    $primaryIP = ''
    $backupIP = ''
			
            $line.backupIP = $vm.guest.IPAddress[1]
			$buDNS = [System.Net.dns]::GetHostEntry($vm.guest.IPAddress[1])
			$line.buDNS = $buDNS.HostName

			
            $line.primaryIP = $vm.guest.IPAddress[0]
			$priDNS = [System.Net.dns]::GetHostEntry($vm.guest.IPAddress[0])
			$line.priDNS = $priDNS.hostname
      
    if ($vm.notes -match $pattern)
	{
        $line.user = $matches[1]
	}
    if ($vm.notes -match $pattern2){
		$line.cUUID = $matches[1]
		if ($line.cUUID -eq "")
		{
			continue
		}
    }
	$CSAServer=""
	$ENVBuild="n"
	if ($vm.notes -match $pattern3)
	{
    		$line.srcCSA = $matches[1]
			$CSAServer=$line.srcCSA
			$ENVBuild=$CSAServer.Substring(4,1)
	}
	else
	{
			$line.srcCSA=""
			$CSAServer=""
			$ENVBuild="n"
	}
	
	if ($vm.notes -match $pattern4){
		$notes = $matches[1]
		$str = $notes -replace "Created on "
		$str1 = $str -replace " via Self Service"
    $line.srcDate = $str1
    }
    if ($vm.notes -match $pattern5){
        $line.offering = $matches[1]
    }
	Write-Host $line.srcCSA $ENVBuild
	$line.BuildEnv=$ENVBuild
    $report += $line
}

$report | Export-Csv -NoTypeInformation -Path $path


Write-Host "Appending "$path "to" $finalpath
$records=Get-Content $path
foreach($record in $records)
{
	if ( -NOT $record.contains($String2Compare))
	{
		$OutRec=$record
		$OutRec >>$finalPath
	}
}
	Write-Host "Removing File "$path
	Remove-Item $path

$Nothing=Disconnect-VIServer * -Confirm:$false
$error.clear()
exit