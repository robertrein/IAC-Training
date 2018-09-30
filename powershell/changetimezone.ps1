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
Function Changezone
{

	$FileIn=Get-Content wmi.txt
	del services.txt -ErrorAction SilentlyContinue

	foreach($Computer in $Filein)
	{
		$OutRec= "Change Time Zone for Computer " + $Computer
		Write-host $OutRec
		$colItems = get-wmiobject -class "Win32_TimeZone" -namespace "root\CIMV2" `
			-computername $Computer
		foreach ($objItem in $colItems) {
		      	$OutRec="Current Time Zone is:" + $objItem.Caption
		}
	Write-Host $OutRec
	$OSVersion=Get-WmiObject Win32_OperatingSystem -Computername $Computer
	$Version=$OSVersion.Version.substring(0,1)

	if ($Version -lt 6)
	{
		$CmdStr="RunDLL32.exe shell32.dll,Control_RunDLL timedate.cpl,,/Z Central Standard Time"
	}
	Else
	{
		$CmdStr="tzutil /s " + """" + "Central Standard Time" + """"
	}
	$Results=Invoke-WmiMethod -ComputerName $Computer -Class Win32_Process -Name Create -ArgumentList $CmdStr
	sleep 5

	$colItems = get-wmiobject -class "Win32_TimeZone" -namespace "root\CIMV2" `
		-computername $Computer
	foreach ($objItem in $colItems) {
		$OutRec="Current Time Zone is:" + $objItem.Caption
	}
	Write-Host $OutRec
}
}
# FILTER OUT UNREACHABLE SERVERS
Cred=Get-Credential
FilterPing
FilterWMI
changezone