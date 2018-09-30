Function FilterPing()
{
	echo "Looking for servers that are accessible"
	echo "Files:  alive.txt and notalive.txt"
	del alive.txt -ErrorAction SilentlyContinue
	del notalive.txt -ErrorAction SilentlyContinue
	$FileIn=Get-Content Servers.txt
	foreach ($Computer in $FileIn)
	{
		$Computer=$Computer.replace(' ','')

		if(!(Test-Connection -Cn $Computer -BufferSize 16 -Count 1 -ea 0 -quiet))
		{
			$Computer >>notalive.txt
		}
		else
		{
			$Computer >>alive.txt
		}
	}
}
Function FilterWMI()
{
	echo "Seperating alive.txt file for servers that are WMI accessible"
	echo "Files:  wmi.txt and nonwmi.txt"
	$searcher = [WMISearcher]''

	$searcher.Options.timeout = '0:0:1'
	
	del wmi.txt -ErrorAction SilentlyContinue
	del nonwmi.txt -ErrorAction SilentlyContinue
	$FileIn=Get-Content alive.txt
	foreach($Computer in $FileIn)
	{
		$Computer
		$ColItems=Get-WmiObject -Class Win32_PnPEntity -Namespace "root\cimv2" -Computer $Computer -ErrorVariable myerror -ErrorAction SilentlyContinue
		if ($myerror.Count -eq 0)
		{
			$Computer >>wmi.txt
		}
		else
		{
			$Computer >>nonwmi.txt
			$myerror.clear()
		}
	}
}
Function GetIPInfo
{
	echo "Processing wmi.txt file for ip information"
	echo "File:  ipinfo.txt"
	del ipinfo.txt -ErrorAction SilentlyContinue
	$FileIn=Get-Content wmi.txt
	foreach($Computer in $FileIn)
	{
		$NICS=Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE -ComputerName $Computer
		foreach($NIC in $NICS)
		{
			$ip=($NIC.IPAddress[0])
			if ($ip -eq "" ) 
			{
				$ip = "0.0.0.0"
			}
			$gateway=$NIC.DefaultIPGateway
			if ($gateway -eq "" ) 
			{
				$gateway = "0.0.0.0"
			}
			$subnet=$NIC.IPSubnet[0]
			if ($subnet -eq "" ) 
			{
				$subnet = "0.0.0.0"
			}
			$dns=$NIC.DNSServerSearchOrder
			if ($dns -eq "" ) 
			{
				$dns = "0.0.0.0"
			}
			$mac=$NIC.MACAddress
			if ($mac -eq "" ) 
			{
				$ip = "0:0:0:0"
			}
			$sysinfo=Get-WmiObject -Class Win32_ComputerSystem -Computer $Computer
			$domain=$sysinfo.Domain
			$outstring=$Computer + "," + $ip + "," + $subnet + "," + $gateway + "," + $dns + "," + $mac + "," + $domain >>ipinfo.txt
			$outstring
		}
	}
	
}
Function GetNetStat
{
	$FileIn=Get-Content wmi.txt
	del getNetStat.txt -ErrorAction SilentlyContinue
	foreach($Computer in $FileIn)
	{
		Invoke-WmiMethod -class Win32_process -name Create -ArgumentList ("cmd /c netstat -a >c:\netstat.txt") -ComputerName $Computer
	}
	Sleep 5
	foreach($Computer in $FileIn)
	{
		foreach($record in type \\$Computer\c$\netstat.txt)
		{
			$OutRecord=$Computer + " " + $record
			$OutRecord >>getNetStat.txt
		}
	}
	
}
Function GetDiskInfo
{
	$FileIn=Get-Content wmi.txt
	del diskinfo.txt -ErrorAction SilentlyContinue
	foreach($Computer in $FileIn)
	{
		.\getdiskinfo.ps1 -ComputerName $Computer -ShowProgress >>diskinfo.txt
	}
}
Function GetInstalledApp
{
	$FileIn=Get-Content wmi.txt
	del getInstallApp.txt -ErrorAction SilentlyContinue
	echo "Processing wmi.txt for Install Applications"
	foreach($Computer in $FileIn){
	    echo $computer
	    $computername=$Computer
	    #Define the variable to hold the location of Currently Installed Programs
	    $UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall" 
	    #Create an instance of the Registry Object and open the HKLM base key
	    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computername) 
	    #Drill down into the Uninstall key using the OpenSubKey Method
	    $regkey=$reg.OpenSubKey($UninstallKey) 
	    #Retrieve an array of string that contain all the subkey names
	    $subkeys=$regkey.GetSubKeyNames() 
	    #Open each Subkey and use GetValue Method to return the required values for each
	    foreach($key in $subkeys){
	        $thisKey=$UninstallKey+"\\"+$key 
	        $thisSubKey=$reg.OpenSubKey($thisKey) 
	        $obj = New-Object PSObject
	        $obj | Add-Member -MemberType NoteProperty -Name "ComputerName" -Value $computername
	        $obj | Add-Member -MemberType NoteProperty -Name "DisplayName" -Value $($thisSubKey.GetValue("DisplayName"))
	        $obj | Add-Member -MemberType NoteProperty -Name "DisplayVersion" -Value $($thisSubKey.GetValue("DisplayVersion"))
	        $obj | Add-Member -MemberType NoteProperty -Name "InstallLocation" -Value $($thisSubKey.GetValue("InstallLocation"))
	        $obj | Add-Member -MemberType NoteProperty -Name "Publisher" -Value $($thisSubKey.GetValue("Publisher"))
		$out=$Computer + "," + $Obj.DisplayName + "," + $obj.DisplayVersion + "," + $obj.InstallLocation + "," + $obj.Publisher
		$out >>getInstallApp.txt
	    } 
	}
}
Function GetUserHistory
{
	$FileIn=Get-Content wmi.txt
	del userhistory.txt -ErrorAction SilentlyContinue
	echo "Processing wmi.txt for user login history"
	foreach($Computer in $Filein)
	{
		echo $Computer
		cscript lookatit.vbs /c:$Computer >>userhistory.txt
	}
}
Function GetServices
{
	$FileIn=Get-Content wmi.txt
	del services.txt -ErrorAction SilentlyContinue
	Write-Host “Retrieving Services"
	foreach($Computer in $Filein)
	{
		$colitems=Get-WmiObject win32_service -ComputerName $Computer | select Name,
		 @{N=”Startup Type”;E={$_.StartMode}},
		 @{N=”Service Account”;E={$_.StartName}},
		 @{N=”System Name”;E={$_.Systemname}} | Sort-Object “Name”
		foreach($service in $colitems)
		{
			$out=$computer + "," + $service
			$out >>services.txt
		}
	}
}
# FILTER OUT UNREACHABLE SERVERS
FilterPing
FilterWMI
GetIPInfo
#GetNetStat
#GetDiskInfo
#GetInstalledApp
#GetUserHistory
#GetServices
