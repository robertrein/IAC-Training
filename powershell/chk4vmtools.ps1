Function ConnectToVCServer {
    $VCenter=Read-Host "Please Enter VCENTER IP or Hostame:"
    if ($VCenter -eq "")
    {
        Exit
    }

    Write-Host "Connecting to VCENTER Server "$VCenter
    Write-Host "Get the vCenter server credentials"
    $vcCred = Get-Credential
    Connect-VIServer -Server $VCenter -Credential $vcCred -Protocol https
}

Remove-Item VMToolsUptodate.txt
Remove-Item VMToolsNeeded.txt
Remove-Item Chk4VMtools.csv
Remove-Item vmstates.txt

$VMs = Get-Content servers.txt

ConnectToVCServer

#Write column headers to csv file
$strOut = "VM,Guest Info,VM Exists,Method,Login Ok,Label Match,Hostname"
$strOut >>Chk4VMtools.csv

#Get the VM admin credentials
Write-Host "Get the VM admin credentials"
$vmCred = Get-Credential

Foreach ($VM in $VMs)
    {
    $VM=$VM.Replace(" ","")
    Write-Host $VM
    $vmState = Get-Vm $VM 
    $OutFile = $vmState >>vmstates.txt

    $GuestInfo = ""
    $useMethod = ""
    $vmLoginOk = ""
    $labelMatch = ""
    $vmHostname = ""
    $VMTools = Get-Vm $VM | % { Get-View $_.id } | Select Name, @{ Name="ToolsVersion"; Expression={$_.config.tools.toolsVersion}},@{ Name="ToolStatus"; Expression={$_.Guest.ToolsVersionStatus}}
    IF (!$VMTools)
        {
        $vmExists = "False"
        Write-Host "No VM named $VM exists" 
        }
    ELSE 
        {
        $vmExists = "True"
        Write-Host "VMExists = $VMExists"

        IF ($VMTools -imatch "guestToolsCurrent")
            {
            $OutFile = $VMTools >>VMToolsUptodate.txt
            }
        ELSE 
            {
            $OutFile = $VMTools >>VMToolsNeeded.txt
            }
    
        $GuestInfo = Get-VMGuest -VM $VM
        Write-Host $GuestInfo

        #Use WMI or VMTools
        $useMethod = Test-Path -path "\\$VM\C$"
        IF ($useMethod)
            {
		$WMIObjOutput=Get-WmiObject -Class Win32_PnPEntity -Namespace "root\cimv2" -Computer $VM -ErrorVariable myerror -ErrorAction SilentlyContinue
		if ($myerror.count -eq 0)
		{
			$useMethod = "WMI"
		}
		else
		{
			$myerror.clear()
			$useMethod="VMTools"
		}
            }
        ELSE
            {
            $useMethod = "VMTools"
            }

        Write-Host "Method: $useMethod"

        #Does login with aspadmin\<pwd> work?
        $vmLoginOk = Invoke-VMScript -GuestCredential $vmCred -ScriptText hostname -VM $VM 
	if ($vmLoginOk -ieq $Null)
	{
		$vmLoginOk = "False"
	}
	Else
	{
		$vmLoginOk = "True"
	}

        Write-Host "LoginOk: $vmLoginOk"
 
        #Does $VM label match the guest host name?
        $vmview = Get-VM $VM | Get-View
        $vmHostname = $vmview.Guest.HostName
        Write-Host "Hostname: $vmHostname"
        $vmMatch = "^" + $VM + "\b"
        IF ($vmHostname -match $vmMatch)
            {
            $labelMatch = "True"
            }
        ELSE
            {
            $labelMatch = "False"
            }

        Write-Host "labelMatch: $labelMatch"
        }

    # Write the output to the comma delimited file
    $strOut = $VM + ',' + $GuestInfo + ',' + $vmExists + ',' + $useMethod + ',' + $vmLoginOk + ',' + $labelMatch + ',' + $vmHostname 
    $strOut >>Chk4VMtools.csv
    }