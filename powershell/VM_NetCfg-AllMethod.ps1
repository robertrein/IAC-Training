#
# SCRIPT COMMENTS SECTION
#
# Author:  Dave Bisseger
# Date Finalized: 12/15/2013
#
# DESCRIPTION:  TO CHANGE NIC CARD IP INFORMATION TO IP INFORMATION CONTAINED IN INPUT FILE
# IT READS EITHER A .TXT OR .CSV FILE OF VM'S AND INJECTS 2 .BAT SCRIPTS IN A DIRECTORY CREATED ON THE ROOT C DRIVE CALLED MIGRATION TEMP.
# IT PROMPTS FOR VCENTER SERVERS (SEPERATED BY COMA'S), INPUT FILE NAME, VCENTER CREDENTIALS,ESX SERVER CREDENTIALS AND GUEST CREDENTIALS.
# DEPENDING ON NETWORK ACCESS TO THE GUEST, IT IS DETERMINED WHETHER THE FILE INJECTIONS ARE DONE VIA WMI OR VMTOOLS METHODS.
# ONCE THE SCRIPTS ARE INJECTED, IT RUNS ONE OF THE 2 .BAT FILES TO SCHEDULE THE SECOND BATCH JOB TO RUN ON REBOOT
# BATCHFILE 1 IS A SCRIPT CREATED TO CHANGE THE IP INFORMATION
# BATCHFILE 2 IS A SCRIPT CREATED AND EXECUTED BY THIS SCRIPT TO SCHEDULE BATCHFILE 1 TO RUN ON NEXT REBOOT
#
# EXAMPLE OF INPUT FILE
#Name,VMName,NetworkPath,Zone,NewPriIP,NewPriSNM,NewPriGW,ChangeBU,CurBUIP,NewBUIP,NewBUSNM,ChangeTSM,NewTSMDrive,NewTargetTSMDC,NewTSMServer,NewTSMTCPPort,ReCFGDate,ReCFGTime
#testvm2,testvm2,10.155.100.96,Intranet,10.155.100.100,255.255.255.0,10.155.100.1,No,,,,No,,,,,,
#testvm3,testvm3,10.155.100.97,Intranet,10.155.100.101,255.255.255.0,10.155.100.1,No,,,,No,,,,,,
#testvm4,testvm4,10.155.100.98,Intranet,10.155.100.102,255.255.255.0,10.155.100.1,Yes,10.155.100.111,10.155.100.112,255.255.255.0,No,,,,,,
#testvm5,testvm5,10.155.100.99,Intranet,10.155.100.103,255.255.255.0,10.155.100.1,No,,,,No,,,,,,
# THE INPUT FILE CAN BE MAINTAINED VIA MICROSOFT EXCEL AND IS DYNAMIC AND MUST BE EITHER .TXT OR .CSV
#
#  NAME=OS GUEST NAME
#  VMNAME=VMWARE LABEL NAME
#  NETWORKPATH=CURRENT PRIMARY IP ADDRESS
#  ZONE=UHG ZONE GUEST IS LOCATED
#  NEWPRIIP=NEW PRIMARY IP ADDRESS
#  NEWPRISNM=NEW NET MASK
#  NEWPRIGW=NEW PRIMARY GATEWAY ADDRESS
#  CHANGEBU="Yes" if you want to change a backup nic, "No" if you do not
#  CURBUIP=IF CHANGEBU="Yes" THEN CONTAINS CURRENT BACKUP IP ADDRESS
#  NEWBUIP=IF CHANGEBU="Yes" THEN CONTAINS NEW BACKUP IP ADDRESS
#  NEWBUSNM=IF CHANGEBU="YES" THEN CONTAINS NEW BACKUP SUBNET MASK
#  CHANGETSM=
#  NEWTSMDRIVE=
#  NEWTARGETTSMDC=
#  NEWTSMSERVER=
#  NEWTSMTCPPORT=
#  RECFGDATE=
#  RECFGTIME=
#
#
#  SCRIPT MAINTENANCE SECTION(WHO CHANGED THIS)
#
#DATE: 4/9/2014
#RE-AUTHOR:  BOB REIN
#
#  1.  CHANGED METHOD OF IDENTIFYING WHICH CARD TO UPDATE WITH WHICH IP BY COMPARING NIC CARD IP WITH OLD IP ADDRESS
#  2.  ADDED ERROR CHECKS FOR VALID VCENTER, VCENTER CREDENTIALS AND INPUT FILE.  IF THESE CHECKS FAIL I EXIT THE SCRIPT
#  3.  CHANGED METHOD OF SUBMITTING THE SCHEDULE TO SIMPLY RUNNING ON NEXT REBOOT
#  4.  INJECTED ADDITIONAL COMMAND IN SCHEDULED BATCH JOB TO REMOVE THE SCHEDULED JOB AFTER IT RUNS (PREVENTS FROM RUNNING EVERYTIME THE SYSTEM IS REBOOOTED)
#
#DATE: 4/11/2014
#RE-AUTHOR: BOB REIN
#  1.  ADDED UPDATE PARAMETER Y OR N FOR RUNNING SCRIPT IN READ OR WRITE(TO SERVERS) MODE.  READ ONLY WILL PRODUCT OUTPUT_SCRIPTS FOLDER ONLY
#

#
# UPDATE PARAMETER (Y)ES OR (N)O
#
#

Param
(
	[Parameter(Mandatory=$True)]
	[string]$Update
)
$Update=$Update.ToUpper()
If (($Update -ne "Y") -and ($Update -ne "N"))
{
	Write-Host "Update flag must be Y or N"
	exit
}


#
# FUNCTION DEFINITIONS
#


#Set working location to directory where the script resides
#
FUNCTION Get-ScriptDirectory
	{
	$Invocation = (Get-Variable MyInvocation -Scope 1).Value
	Split-Path $Invocation.MyCommand.Path
	}
		
#Begin ChooseFile Function
Function ChooseFile
	{   
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
	Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.ShowHelp = $true;
	$OpenFileDialog.initialDirectory = $ScriptDir
	$OpenFileDialog.filter = "All files (*.*)| *.*"
	$OpenFileDialog.title = "Please choose an input file..."
# 	$OpenFileDialog.ShowDialog() | Out-Null
 	$OpenFileDialog.ShowDialog() | Out-Null
 	$OpenFileDialog.filename
	}
#End ChooseFile Function

#Begin VIServer Connect Function
Function VIServerConnect
	{
	$Error.Clear()
	If($Viservers -imatch "dmzmgmt")
		{
		If($cred -eq $null)
			{
			$cred = Get-Credential -Message "DMZMGMT Credentials:"
			}
		}
	
	IF(($DefaultVIServers.count -eq 0) -or ($DefaultVIServers -eq $null))
		{
		Foreach($VIserver in $Viservers)
			{
			IF($VIserver -imatch ".dmzmgmt.uhc.com")
				{
				IF($DefaultVIServers -inotcontains $VIserver)
					{
					Connect-viserver $Viserver -Credential $cred
					}
				}
			ELSE 
				{
				IF($DefaultVIServers -inotcontains $VIserver)
					{
					$cred=$host.ui.PromptForCredential("Need Credentials","Please enter VCenter Credentials","","")
					Connect-viserver $Viserver -Credential $cred
					}
				}
			}
		}

	
	if ($Error.Count -ne 0)
		{
		[System.Windows.Forms.MessageBox]::Show(`
		"Error connecting to Vcenter..."`
		,"Cancelling...",0) | Out-Null
		Exit
		}


	}
#End VIServer Connect Function

#Begin ChooseFileResult Function
Function ChooseFileResult
	{
	IF(($Filename -ieq "") -or ($Filename -eq $null))
		{
		[System.Windows.Forms.MessageBox]::Show(`
		"Either no filename was specified or you have chosen to cancel script execution."`
		,"Cancelling...",0) | Out-Null
		Exit
		}
	If($Filename -imatch ".txt")
		{
		$Script:InputList = Get-Content $Filename
		}
	ElseIf($Filename -imatch ".csv")
		{
		$Script:InputList = Import-Csv $Filename
		}
	Else
		{
		[System.Windows.Forms.MessageBox]::Show(`
		"Filename must be either .txt or .csv"`
		,"Cancelling...",0) | Out-Null
		Exit
		}
	}
	
#End ChooseFileResult Function
#Begin ClearScriptVars Function
Function ClearScriptVars
	{
	ForEach($ScriptVar in $ScriptVars)
		{
		IF ((Test-Path variable:ScriptVar) -ieq $true)
			{
			Clear-Variable -Name ScriptVar
			}
		}
	}
#End ClearScriptVars Function


#
# END FUNCTION DEFINITIONS
#


#
# WORKING SECTION
#
# Lets get the current directory of this script and set it as our working directory
$ScriptDir = Get-ScriptDirectory
Set-Location $ScriptDir
#
#End Set working directory

# Lets clear the current display
Clear-Host


#Prompt to continue and input VIServer(s)
#

# Lets setup the graphical environment with [System.Reflection.Assembly]

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 

#
# Lets display a dialogue box and describe what the script does and give the user a choice whether to continue or not
#
$ScriptChoice = [System.Windows.Forms.MessageBox]::Show(`
	"This script will reconfigure the target VMs' settings"+ `
	" according to the contents of the file selected.`r`r`r`Do you wish to"+ `
	" continue?" , "VM Reconfiguration" , 4)
	IF($ScriptChoice -eq "YES")
		{
   		[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
		$VIServersInput = [Microsoft.VisualBasic.Interaction]::InputBox(`
		"Enter the Virtual Center Server FQDN(s), separated by commas:","VIServers")

		IF($VIServersInput -ieq "")
			{
			[System.Windows.Forms.MessageBox]::Show(`
			"Either no VIServers were provided or you have chosen to cancel script execution."`
			,"Cancelling...",0) | Out-Null
			Exit
			}
		}
	IF($ScriptChoice -eq "NO")
    	{
		Exit
		}
	Else
		{
		$Viservers = $VIServersInput.split(',') | % {$_.trim()}
		}

foreach ($viserver in $viservers)
{
	$Error.Clear()
	$Alive=Test-Connection $viserver
	if ($Error.Count -ne 0)
	{
		[System.Windows.Forms.MessageBox]::Show(`
		"Host is not reachable."`
		,"Cancelling...",0) | Out-Null
		Exit

	}
}
#
#End prompt to continue and input VIServer(s)

# Clear Filename variable if it has a value
IF ($Filename -ne $NULL)
	{
	Clear-Variable -Name $Filename
	}

#Lets Get the input file name from the users
#
$Filename = ChooseFile


#Run ChooseFileResult Function 
# Lets ensure the file is either a .txt or .csv file and import the data

ChooseFileResult

#Add VMWare PowerCli Snap-in
Add-PSsnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue


#Run VIserverConnect Function
VIServerConnect

#Prompt for and cache credentials for hosts and guest
$Hostcred = $host.ui.PromptForCredential("Need Credentials","Please enter ESX root Credentials","","")
IF($Hostcred -ieq $null)
	{
	[System.Windows.Forms.MessageBox]::Show(`
	"Either no host credentials were provided or you have chosen to cancel script execution."`
	,"Cancelling...",0)
	Exit
	}

$GuestCred = $Host.ui.PromptForCredential("Need Credentials","Please enter Guest Credentials","","")
IF($GuestCred -ieq $null)
	{
	[System.Windows.Forms.MessageBox]::Show(`
	"Either no guest credentials were provided or you have chosen to cancel script execution."`
	,"Cancelling...",0) | Out-Null
	Exit
	}


#Check version of "Schtasks.exe" on local machine and sets variable $SCHTasksVer to resultant value
$SCHTasksVer = [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$env:windir\system32\schtasks.exe").FileVersion.ToString().Substring(0,1) 

# SET STATIC VARIABLES, CHANGE THIS ACCORDING TO YOUR REQUIREMENTS
#Set universal values
$IPPolicy = "Static"
$PriDNSPolicy = "Static"
$PriWinsPolicy = "Static"
$BUDNSPolicy = "Static"
$BUWinsPolicy = "Static"
$DNS1 = "10.90.40.105"
$DNS2 = "10.4.148.103"
$DNS3 = "10.3.116.104"
$DMZDNS1 = "10.117.7.30"
$DMZDNS2 = "10.217.12.36"
$WINS1 = "10.175.231.100"
$WINS2 = "10.223.192.155"
$DMZWINS = "10.119.116.63"
$LenexaDNSSSO = "ksc.pcl.ingenix.com,pcl.ingenix.com,geoaccess.com,dmzkc1.geoaccess.com,ms.ds.uhc.com,uhc.com"

#Create array variable containing script variables that are redefined for each VM.
$ScriptVars = ("BatchfileHeader,BUOSNIC,BUOSNICName,BUVMNICMAC,ComputerName,`
DeleteOldScriptStr,DisableNBTBUStr,ExecuteScriptText,FQCN,Matches,NetCfgBU, `
NetCfgDMZDNSWINS,NetCfgIntraDNSWINS,NetCfgPriAll,NewBUIP,NewBUSNM,NewConfigLine,`
NewPriDefaultGateway,NewPriIP,NewPriSubnetMask,NewTargetTSMDC,NewTCPPort,`
NewTCPServer,NewTSMDrive,OSNetElementRaw,OSNICsInfoRaw,OSNetNamesMacsRaw,OSNicID,`
OSNicProp,OSNics,PRIOSNIC,PRIOSNICName,PRIVMNICMAC,ReCFGDate,ReCFGTime,Scriptout,`
ScriptoutName,StdPriOSNICName,TSMCFG,VMHost,VMName,VMNics,VMZone,WMIBUNICIndex,`
WMIBUNICMac,WMINICs,WMINICsStr").split(',') | % {$_.trim()}



#Get VM data from input file's array variable.
$VMList = $InputList
$VMs = ForEach($VMLine in $VMList)
	{
	$Name = $VMLine.VMName
	Get-View -ViewType VirtualMachine -Property Name,Runtime,Config,Guest,Network -Filter @{"name" = $Name}
	}
$DTStamp = Get-Date -Format yyyyMMddHHmmss

$ErrFile = $Filename.Substring(0,($filename.lastindexof("\")+1)) + "Error_" + $DTStamp + ".txt"

New-Item -ItemType File -Path $ErrFile


ForEach($VM in $VMs)
	{
	ClearScriptVars
	
	#Error/Exception Capture
	$ErrLogVMNameHeader = "--------------------------------------`r`n" + $VM.Name + "`r`n--------------------------------------`r`nvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv`r`n"
	Add-Content $ErrFile $ErrLogVMNameHeader
	
	trap {$_.Exception.Message | Out-File -FilePath $ErrFile -Append; continue}
    $Error[0].Exception.Message | Out-File -FilePath $ErrFile -Append  
	

		
	IF ($VM.Guest.GuestFullName -imatch "2003")
		{
		$OSFamily = "2003"
		}
	IF ($VM.Guest.GuestFullName -imatch "2008")
		{
		$OSFamily = "2008"
		}
	$VMHost = (Get-View $VM.runtime.host -property Name,Parent).name
	$NewConfigLine = ($VMList | Where {$_.Name -imatch ((($VM.Guest.HostName).Split("."))[0])})
	$ComputerName = $NewConfigLine.name
	$NetworkPath = $NewConfigLine.NetworkPath
	$FQCN = $VM.Guest.HostName
	$VMName = $VM.name
	$VMZone = $NewConfigLine.zone
	$VMNics = Get-NetworkAdapter -VM $VMName
	$PriVMNicMac = ($VMNics | Where{$_.Name -ieq "Network Adapter 1"}).MacAddress
	IF ($VMNics.Count -igt 1)
		{
		$BUVMNicMac = ($VMNics | Where{$_.Name -ieq "Network Adapter 2"}).MacAddress
		}
	$StdPriOSNicName = $ComputerName.ToUpper() + "_PRI"
	$StdBUOSNicName = "backup-storage"
	$NewPriIP = $NewConfigLine.newpriip
	$NewPriSubnetMask = $NewConfigLine.newprisnm
	$NewPriDefaultGateway = $NewConfigLine.newprigw
	IF ($NewConfigLine.ChangeBU -ieq "Yes")
		{
		$NewBUIP = $NewConfigLine.newbuip
		$NewBUSNM = $NewConfigLine.newbusnm
		}
	ELSE
		{
		$NewBUIP = $null
		$NewBUSNM = $null
		}
	
	#Read reconfig date and time from input file.
	#$ReCFGDate must be in mm/dd/yyyy format.
	IF($NewConfigLine.recfgdate.Indexof("/") -igt 1)
		{
		$ReCFGDate = $NewConfigLine.recfgdate
		}
	ELSE
		{
		$ReCFGDate = "0" + $NewConfigLine.recfgdate
		}
	
	IF($ReCFGDate.LastIndexof("/") -ile 4)
		{
		$ReCFGDate = $ReCFGDate.Substring(0,3) + "0" +  $ReCFGDate.Substring(3)
		}
		
	
	#$ReCFGTime must be in 24 hour hh:mm format.
	$ReCFGTime = $NewConfigLine.recfgtime
		
	#Check for network access to target VM's OS and set $QueryMethod variable accordingly.
	$Testpath = "\\$ComputerName\c$"
	$NetworkAccess = Test-Path $Testpath
	IF ($NetworkAccess -ieq $true)
		{
			$WMIObjOutput=Get-WmiObject -Class Win32_PnPEntity -Namespace "root\cimv2" -Computer $ComputerName -ErrorVariable myerror -ErrorAction SilentlyContinue
			Write-Host $ComputerName $myerror.count
			if ($myerror.count -eq 0)
			{
				$QueryMethod = "WMI"
			}
			else
			{
				$QueryMethod = "VMTools"
				$myerror.clear()
			}
		}
	IF ($NetworkAccess -ieq $false)
		{
		$QueryMethod = "VMTools"
		}
	
	#Place required utility files and query target VM's OS; via the network.	
	IF ($QueryMethod -ieq "WMI")
		{
		$DestinationPath = "\\$ComputerName\c$\MigrationTemp"
		#Query target VM's OS.
		$OSNicsCfg = Get-WMIObject -class Win32_NetworkAdapterConfiguration -ComputerName $NetworkPath | Where{$_.IpEnabled -imatch "True"}
		$OSNicsInfo = Get-WmiObject -class Win32_NetworkAdapter -ComputerName $NetworkPath | Where{$_.NetConnectionStatus -eq  "2"}
		$PriOSNicCfg = $OSNicsCfg | Where {$_.MacAddress -ieq $PriVMNicMac}
		$PriOSNicInfo = $OSNicsInfo | Where {$_.DeviceID -ieq $PriOSNicCfg.Index}	
		$PriOSNicName = $PriOSNicInfo.NetConnectionID
		IF (($BUVMNICMAC -ine $null) -or ($BUVMNICMAC -inotmatch ""))
			{
			$BUOSNicCfg = $OSNicsCfg | Where {$_.MacAddress -ieq $BUVMNicMac}
			$BUOSNicInfo = $OSNicsInfo | Where {$_.DeviceID -ieq $BUOSNicCfg.Index}	
			$BUOSNicName = $BUOSNicInfo.NetConnectionID
			$BUOSNicIndex = $BUOSNicCfg.index
			}
		}
	
	#Place required utility files and query target VM's OS; via VMTools.
	IF ($QueryMethod -ieq "VMTools")
		{
		$DestinationPath = "c:\MigrationTemp"
		#Query target VM's OS.
		$OSNicsInfoScriptText = "cmd.exe /C ipconfig /all"
		$OSNicsInfoRaw = Invoke-VMScript -GuestCredential $Guestcred -ScriptText $OSNicsInfoScriptText -ScriptType Bat -VM $VMName
		IF($OSNicsInfoRaw.GetType().BaseType.Name -imatch "Array")
			{
			$OSNicsInfo = $OSNicsInfoRaw.ScriptOutput[0].Split("`r") | Select-string "Ethernet adapter.*:|Physical address|IP.*Address" | Where {$_ -inotmatch "00-00-00-00-00-00-00|IPv6"}
			}
		ELSE
			{
			$OSNicsInfo = $OSNicsInfoRaw.ScriptOutput.Split("`r") | Select-string "Ethernet adapter.*:|Physical address|IP.*Address" | Where {$_ -inotmatch "00-00-00-00-00-00-00|IPv6"}
			}
		$OSNicID = 0
		$OSNics = @()
		ForEach($OSNicsItem in $OSNicsInfo | Where {$_ -imatch "Ethernet Adapter"})
			{
			$OSNicProp = "" | Select Name,MAC,IP
			$OSNicProp.Name = (((($OSNicsInfo | Where{$_ -imatch "Ethernet Adapter"})[$OSNicID].ToString()).split(":"))[0]).Substring(18)
			$OSNicProp.MAC =  (((($OSNicsInfo | Where{$_ -imatch "Physical Address"})[$OSNicID].ToString()).split(":"))[1]).Trim()
			$OSNicProp.IP = (((((($OSNicsInfo | Where{$_ -imatch "IP"})[$OSNicID].ToString()).split(":"))[1]).split("("))[0]).trim()
			IF ($NewConfigLine.NetworkPath -ieq $OSNicProp.IP)
				{
				$PRIOSNicName=$OSNicProp.Name
				}
			IF ($NewConfigLine.CURBuIP -ieq $OSNicProp.IP)
				{
				$BUOSNicName=$OSNicProp.Name
				}
			$OSNics += $OSNicProp
			$OSNicID = $OSNicID + 1
			}
		$PRIVMNICMAC = ($VMNics | Where{$_.Name -ieq "Network Adapter 1"}).MacAddress
		IF ($VMNics -igt 1)
			{
			$BUVMNICMAC = ($VMNics | Where{$_.Name -ieq "Network Adapter 2"}).MacAddress
			}
#		$PRIOSNIC = $OSNics | Where {($_.Mac -replace "-",":")  -ieq $PRIVMNICMAC}
#		$PRIOSNicName = $PRIOSNIC.Name
		IF (($BUVMNICMAC -ine $null) -or ($BUVMNICMAC -inotmatch ""))
			{
			$BUOSNIC = $OSNics | Where {($_.Mac -replace "-",":")  -ieq $BUVMNICMAC}
#			$BUOSNICName = $BUOSNIC.Name
			}
		IF ($NewConfigLine.ChangeBU -ieq "Yes")
			{
			$OSNicsCfgRaw = Invoke-VMScript -VM $VMName -GuestCredential $GuestCred -ScriptText "wmic nicconfig get index,macaddress" -ScriptType Bat
			$OSNicsCfg = ($OSNicsCfgRaw | %{$_ -ireplace "ScriptOutput",""}| %{$_ -ireplace "\s+\r",".`r"} | %{$_ -replace "\s+",","} | %{$_ -ireplace "`r,","`r"}).split('.') | % {$_.trimstart(",")} | Select -Skip 1 | Where {$_ -imatch ","}
			$BUOSNicIndex = ($OSNicsCfg | Where{$_ -imatch $BUVMNICMAC}).split(",") | Select -First 1
			$BUOSNicMac = ($OSNicsCfg | Where{$_ -imatch $BUVMNICMAC}).split(",") | Select -Skip 1
			$DisableNBTBUStr = "wmic nicconfig where index=$BUOSNicIndex call SetTcpipNetbios 2"
			}
		}

	
	IF ($NewConfigLine.ChangeTSM -ieq "Yes")
		{
		$NewTSMDrive = $NewConfigLine.newtsmdrive
		$NewTargetTSMDC = $NewConfigLine.newtargettsmdc
		$NewTCPServer = $NewConfigLine.newtsmserver
		$NewTCPPort = $NewConfigLine.newtsmtcpport
		}
		
	#Prepare script blocks for batchfile creation
	$BatchfileHeader = "`n`n:: This script will configure (or reconfigure) the indicated elements of a VM guest. `n`n" + `
	"@ECHO off `n`nSetLocal `n`n"
	
	
	IF($OSFamily -imatch "2008")
		{
		$NetCfgPriAll = "::***********************************************************************************`n" + `
		"::*  Configure Primary network interface name and IP.                               *`n" + `
		"::***********************************************************************************`n`n" + `
		"::Rename PRI NIC to standard. `n" + `
		"::Clear DNS and WINS server entries. `n" + `
		"::Set Primary NIC as first in binding order. `n" + `
		"schtasks /delete -tn " + """" + "Migration Config" + """" + " /F `n" + `
		"netsh interface set interface name="""+$PriOSNicName+""" newname="""+$StdPriOSNicName+""" `nsleep 10 `n" + `
		"netsh int ipv4 set address name="""+$StdPriOSNicName+"""  source=$IPPolicy address=$NewPriIp " + `
		"mask=$NewPriSubnetMask gateway=$NewPriDefaultGateway gwmetric=0 `n" + `
		"netsh int ipv4 set dnssserver name="""+$StdPriOSNicName+""" address=none source=$IPPolicy `n" + `
		"netsh int ipv4 set winsserver name="""+$StdPriOSNicName+""" address=none source=$IPPolicy `n" + `
		"c:\MigrationTemp\nvspbindxp.exe /++ $StdPriOSNicName ms_tcpip `n" + `
		"REG ADD HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters /v ""SearchList"" /d """+$LenexaDNSSSO+""" /f `n`n`n"
		
		
		$NetCfgIntraDNSWINS = "::***********************************************************************************`n" + `
		"::*  Configure Primary network interface DNS and WINS, per standard (Internal).     *`n" + `
		"::***********************************************************************************`n`n" + `
		"netsh int ipv4 add dnsserver name="""+$StdPriOSNicName+"""  address=$dns1 index=1 `n" + `
		"netsh int ipv4 add dnsserver name="""+$StdPriOSNicName+"""  address=$dns2 index=2 `n" + `
		"netsh int ipv4 add dnsserver name="""+$StdPriOSNicName+"""  address=$dns3 index=3 `n" + `
		"netsh int ipv4 add winsserver name="""+$StdPriOSNicName+""" address=$Wins1 index=1 `n" + `
		"netsh int ipv4 add winsserver name="""+$StdPriOSNicName+""" address=$Wins2 index=2 `n`n`n"
		
		
		$NetCfgDMZDNSWINS = "::***********************************************************************************`n" + `
		"::* Configure Primary network interface DNS and WINS, per standard (DMZ).           *`n" + `
		"::***********************************************************************************`n`n" + `
		"netsh int ipv4 add dnsserver name="""+$StdPriOSNicName+""" address=$dmzdns1 index=1 `n" + `
		"netsh int ipv4 add dnsserver name="""+$StdPriOSNicName+""" address=$dmzdns2 index=2 `n" + `
		"netsh int ipv4 add winsserver name="""+$StdPriOSNicName+""" address=$dmzwins index=1 `n`n`n"
				
		IF ($NewConfigLine.ChangeBU -ieq "Yes")
			{
			$NetCfgBU =  "::***********************************************************************************`n" + `
			"::* Configure backup network interface name and IP.                                 *`n" + `
			"::* Clear DNS and WINS server entries.                                              *`n" + `
			"::* Disable dynamic DNS registration.                                               *`n" + `
			"::* Disable NetBIOS.                                                                *`n" + `
			"::* Disable File and Print Sharing.                                                 *`n" + `
			"::***********************************************************************************`n`n" + `
			"netsh interface set interface name="""+$BUOSNicName+""" newname="""+$StdBUOSNicName+"""  `nsleep 10 `n" + `
			"netsh int ipv4 set address name="""+$StdBUOSNicName+"""  source=$IPPolicy addr=$NewBUIP mask=$NewBUSNM `n" + `
			"netsh int ipv4 set dns name="""+$StdBUOSNicName+""" source=$IPPolicy addr=none register=none `n" + `
			"wmic nicconfig where index=$BUOSNicIndex call SetTcpipNetbios 2 `n" + `
			"c:\MigrationTemp\nvspbindxp.exe -d $StdBUOSNicName ms_server `n`n`n"
			}
		Else
			{
			$NetCfgBU =  $null
			}
		}
		
		
		IF($OSFamily -imatch "2003")
		{
		$NetCfgPriAll = "::***********************************************************************************`n" + `
		"::*  Configure Primary network interface name and IP.                               *`n" + `
		"::***********************************************************************************`n`n" + `
		"::Rename PRI NIC to standard. `n" + `
		"::Clear DNS and WINS server entries. `n" + `
		"::Set Primary NIC as first in binding order. `n" + `
		"schtasks /delete /tn " + """" + "Migration Config" + """" + " /F `n" + `
		"netsh interface set interface name="""+$PriOSNicName+""" newname="""+$StdPriOSNicName+""" `nsleep 10 `n" + `
		"netsh int ip set address name="""+$StdPriOSNicName+""" source=$IPPolicy addr=$NewPriIp " + `
		"mask=$NewPriSubnetMask gateway=$NewPriDefaultGateway gwmetric=0 `n" + `
		"netsh int ip set dns name="""+$StdPriOSNicName+""" addr=none source=$IPPolicy `n" + `
		"netsh int ip set wins name="""+$StdPriOSNicName+""" addr=none source=$IPPolicy `n" + `
		"c:\MigrationTemp\nvspbindxp.exe /++ $StdPriOSNicName ms_tcpip `n" + `
		"REG ADD HKLM\SYSTEM\CurrentControlSet\services\Tcpip\Parameters /v ""SearchList"" /d """+$LenexaDNSSSO+""" /f `n`n`n"
		
		
		$NetCfgIntraDNSWINS = "::***********************************************************************************`n" + `
		"::*  Configure Primary network interface DNS and WINS, per standard (Internal).     *`n" + `
		"::***********************************************************************************`n`n" + `
		"netsh int ip add dns name="""+$StdPriOSNicName+""" addr=$dns1 index=1 `n" + `
		"netsh int ip add dns name="""+$StdPriOSNicName+""" addr=$dns2 index=2 `n" + `
		"netsh int ip add dns name="""+$StdPriOSNicName+""" addr=$dns3 index=3 `n" + `
		"netsh int ip add wins name="""+$StdPriOSNicName+""" addr=$Wins1 index=1 `n" + `
		"netsh int ip add wins name="""+$StdPriOSNicName+""" addr=$Wins2 index=2 `n`n`n"
		
		
		$NetCfgDMZDNSWINS = "::***********************************************************************************`n" + `
		"::* Configure Primary network interface DNS and WINS, per standard (DMZ).           *`n" + `
		"::***********************************************************************************`n`n" + `
		"netsh int ip add dns name="""+$StdPriOSNicName+""" addr=$dmzdns1 index=1 `n" + `
		"netsh int ip add dns name="""+$StdPriOSNicName+""" addr=$dmzdns2 index=2 `n" + `
		"netsh int ip add wins name="""+$StdPriOSNicName+""" addr=$dmzwins index=1 `n`n`n"
		
		
		IF ($NewConfigLine.ChangeBU -ieq "Yes")
			{
			$NetCfgBU =  "::***********************************************************************************`n" + `
			"::* Configure backup network interface name and IP.                                 *`n" + `
			"::* Clear DNS and WINS server entries.                                              *`n" + `
			"::* Disable dynamic DNS registration.                                               *`n" + `
			"::* Disable NetBIOS.                                                                *`n" + `
			"::* Disable File and Print Sharing.                                                 *`n" + `
			"::***********************************************************************************`n`n" + `
			"netsh interface set interface name="""+$BUOSNicName+""" newname="""+$StdBUOSNicName+""" `nsleep 10 `n" + `
			"netsh int ip set address name="""+$StdBUOSNicName+"""  source=$IPPolicy addr=$NewBUIP mask=$NewBUSNM `n" + `
			"netsh int ip set dns name="""+$StdBUOSNicName+""" source=$IPPolicy addr=none register=none `n" + `
			"wmic nicconfig where index=$BUOSNicIndex call SetTcpipNetbios 2 `n" + `
			"c:\MigrationTemp\nvspbindxp.exe -d $StdBUOSNicName ms_server `n`n`n"
			}
		Else
			{
			$NetCfgBU =  $null
			}
		}
		
	IF ($NewConfigLine.ChangeTSM -ieq "Yes")
		{
		$TSMCFG = "::***********************************************************************************`n" + `
		"::*  Configure (or reconfigure) TSM.                                                *`n" + `
		"::***********************************************************************************`n`n" + `
		"::Check for TSM directory structure. `n" + `
		":ChkDir `n" + `
		"IF NOT EXIST $NewTSMDrive`:\TSM_Jobs MD $NewTSMDrive`:\TSM_Jobs `n" + `
		"IF NOT EXIST $NewTSMDrive`:\TSM_Logs MD $NewTSMDrive`:\TSM_Logs `n" + `
		"IF NOT EXIST $NewTSMDrive`:\TSM_Logs\Backups MD $NewTSMDrive`:\TSM_Logs\Backups `n" + `
		"IF NOT EXIST $NewTSMDrive`:\TSM_Logs\Errors MD $NewTSMDrive`:\TSM_Logs\Errors `n" + `
		"::Check for existing OPT file.  Rename if exists.  Create new. `n" + `
		":ChkOptFile `n" + `
		"IF EXIST $NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt SET /A optfile=""1"" `n" + `
		"IF %optfile% equ 1 REN $NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt " + $ComputerName + "_backup_dsm.opt.premig `n" + `
		"ECHO NODENAME $ComputerName>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO PASSWORDACCESS  GENERATE>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO TCPPORT  $newtcpport>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO TCPSERVERADDRESS  $newtcpserver>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO tcpbuffsize 32>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO Tcpnodelay Yes>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO tcpwindowsize 63>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO subdir Yes>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO txnbytelimit 25600>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO retryp 10>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO diskbuffsize 32>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO COMMrestartduration 180>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO COMMrestartinterval 300>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO MAXCMDretries ^6>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO SNAPSHOTPROVIDERIMAGE VSS>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO Schedlogretention ^0>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO Errorlogretention ^0>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO Schedlogname $NewTSMDrive`:\TSM_Logs\Backups\backup.log>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO Errorlogname $NewTSMDrive`:\TSM_Logs\Errors\backuperror.log>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO postschedulecmd ""cscript /nologo $NewTSMDrive`:\TSM_Jobs\TSM_local_backup_Post.vbs"">>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt `n`n" + `
		"::Check logfiles.  Renames if exists.  Creates new logfiles. `n" + `
		":ChkLogFiles `n" + `
		"IF EXIST $NewTSMDrive`:\TSM_Logs\Backups\backup.log SET /A bulog=""1"" `n" + `
		"IF EXIST $NewTSMDrive`:\TSM_Logs\Errors\backuperror.log SET /A errlog=""1"" `n" + `
		"IF %bulog% equ 1 REN $NewTSMDrive`:\TSM_Logs\Backups\backup.log backup.log.premig `n" + `
		"IF %errlog% equ 1 REN $NewTSMDrive`:\TSM_Logs\Backups\backuperrpr.log backuperror.log.premig `n" + `
			"ECHO.> NUL 2>$NewTSMDrive`:\TSM_Logs\Backups\backup.log `n" + `
		"ECHO.> NUL 2>$NewTSMDrive`:\TSM_Logs\Errors\backuperror.log `n`n" + `
		"::Check TSMQuery. Create if not exists. `n" + `
		":ChkTSMQuery `n" + `
		"IF EXIST $NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd GOTO ChkLocalBU `n" + `
		"ECHO C:>$NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd `n" + `
		"ECHO CD C:\program files\Tivoli\TSM\baclient\>>$NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd `n" + `
		"ECHO dsmc.exe query session -optfile=$NewTSMDrive`:\TSM_JOBS\"+$ComputerName+"_backup_dsm.opt>>$NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd `n" + `
		"ECHO pause>>$NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd `n" + `
		"ECHO dsmc.exe query schedule -optfile=$NewTSMDrive`:\TSM_JOBS\"+$ComputerName+"_backup_dsm.opt>>$NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd `n" + `
		"ECHO pause>>$NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd `n" + `
		"ECHO dsmc.exe query inclexcl -optfile=$NewTSMDrive`:\TSM_JOBS\"+$ComputerName+"_backup_dsm.opt>>$NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd `n" + `
		"ECHO pause>>$NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\TSMQuery.cmd `n`n" + `
		"::Check Local_Backup file.  Create if not exist. `n" + `
		":ChkLocalBU `n" + `
		"IF EXIST $NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd GOTO ChkPost `n" + `
		"ECHO C:>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n" + `
		"ECHO CD C:\program files\Tivoli\TSM\baclient\>>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n" + `
		"ECHO REM Backup results will be written to $NewTSMDrive`:\TSM_Logs\Backups\Manual.Backup.log.>>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n" + `
		"ECHO dsmc incremental -optfile=$NewTSMDrive`:\TSM_Jobs\"+$ComputerName+"_backup_dsm.opt ^> $NewTSMDrive`:\TSM_Logs\Backups\Manual.Backup.log>>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n" + `
		"ECHO REM See $NewTSMDrive`:\TSM_Logs\Backups\Manual.Backup.log for results of backup.>>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n" + `
		"ECHO Pause>>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n" + `
		"ECHO.>>$NewTSMDrive`:\TSM_Jobs\Local_Backup.cmd `n`n" + `
		"::Check for the ""Post"" VBS file `n" + `
		":ChkPost `n" + `
		"IF NOT EXIST $NewTSMDrive`:\TSM_Jobs\TSM_local_backup_Post.vbs COPY c:\MigrationTemp\TSM_local_backup_Post.vbs $NewTSMDrive`:\TSM_Jobs `n`n" + `
		"::Check TSM Scheduler Service. `n" + `
		":ChkSchdlr `n" + `
		"SC QUERY TSM-$ComputerName-Backup-Scheduler | FINDSTR ""SERVICE_NAME"" `n" + `
		"IF ERRORLEVEL 1 ( GOTO CreateSchdlr) `n" + `
		"SC STOP TSM-$ComputerName-Backup-Scheduler `nSLEEP 5 `n" + `
		"SC DELETE TSM-$ComputerName-Backup-Scheduler `nSLEEP 5 `n`n" + `
		"::Create a new TSM Scheduler Service. `n" + `
		":CreateSchdlr `n" + `
		"""C:\program files\Tivoli\TSM\baclient\dsmcutil.exe"" install Scheduler /name:TSM-$ComputerName-Backup-Scheduler /clientdir:""c:\Program files\tivoli\tsm\baclient"" /optfile:$NewTSMDrive`:\TSM_JOBS\"+$ComputerName+"_backup_dsm.opt /node:$ComputerName /password:$NewTargetTSMDC$ComputerName /validate:yes /autostart:yes /startnow:yes /clusternode:no `n"
		}
	Else
		{
		$TSMCFG = $null
		}
		
		
	#Consolidate script output
	IF ($VMZone -imatch "Intranet")
		{
		$ReCFGScriptout = $BatchfileHeader + $NetCfgPriAll + $NetCfgIntraDNSWINS + $NetCfgBU + $TSMCFG
		}
	IF ($VMZone -imatch "dmz")
		{
		$ReCFGScriptout = $BatchfileHeader + $NetCfgPriAll + $NetCfgDMZDNSWINS + $NetCfgBU + $TSMCFG
		}
	
	#Create scripts
	#Set variable with the filename for the reconfiguration script
	$ReCFGScriptoutFileName = $ComputerName + "_MigConfig.bat"
	#Set variable with location where the reconfiguration script will be created
	$ReCFGScriptDestFile= "C:\MigrationTemp\" + $ReCFGScriptoutFileName
	#Create reconfiguration script
	New-Item -ItemType File -Name $ReCFGScriptoutFileName -Force -Path .\Output_Scripts -Value $ReCFGScriptout
	
	#Set variable with the filename for the reconfiguration scheduing script
	$SchReCFGTaskFileName = $ComputerName + "_SchTaskMigConfig.bat"
	#Set variable with location where the reconfiguration script will be created
	$SchReCFGTaskDestFile = "C:\MigrationTemp\" + $SchReCFGTaskFileName
	#Command syntax string to create reconfig task, which is parsed into the schedue reconfig script
	$SchReCFGTaskOut = "schtasks /create /RU ""SYSTEM"" /sc ONstart /tn ""Migration Config"" /TR ""$ReCFGScriptDestFile"" /F"
	New-Item -ItemType File -Name $SchReCFGTaskFileName -Force -Path .\Output_Scripts -Value $SchReCFGTaskOut
	$SchReCFGScriptDestFile=$DestinationPath + "\" + $SchReCFGTaskFileName
	#Copy script and other necessary files to target VM.
	Write-Host "Checking to see what Query Method we are using"
	Write-Host $QueryMethod
	if ($Update -ieq "N")
	{
		Write-Host "EXECUTION IS IN NON-UPDATE MODE, NO HOST WILL BE WRITTEN TO"
	}
	Else
	{
		IF ($QueryMethod -ieq "WMI")
			{
			Write-Host Processing WMI
			$CleanupDestStr = " /C IF EXIST $DestinationPath DEL /F /Q $DestinationPath &  IF EXIST $DestinationPath RMDIR /S /Q $DestinationPath"
			$CreateDestStr = " /C IF NOT EXIST $DestinationPath MKDIR $DestinationPath"
			#Start-Process cmd.exe -ArgumentList $CleanupDestStr -Wait -NoNewWindow
			#sleep 5
			if (test-path $DestinationPath)
			{
				del $DestinationPath\*.*
				rmdir $DestinationPath
			}
			mkdir $DestinationPath
			#Start-Process cmd.exe -ArgumentList $CreateDestStr -Wait -NoNewWindow
			copy .\Output_Scripts\$ReCFGScriptoutFileName $DestinationPath
			copy .\Output_scripts\$SchReCFGTaskFileName $DestinationPath
			Copy-Item -path .\Output_Scripts\$SchReCFGTaskFileName -Destination $DestinationPath -Force
			Copy-Item -path .\nvspbindxp.exe -Destination $DestinationPath -Force
			Copy-Item -path .\sleep.exe -Destination $DestinationPath -Force
			#Copy-Item -path .\TSM_local_backup_Post.vbs -Destination $DestinationPath -Force
			$SchMigConfigTask = " /create /s \\$NetworkPath /RU ""SYSTEM"" /V1 /sc ONCE /tn ""Schedule Migration Config"" /TR ""$SchReCFGTaskDestFile"" /sd $ReCFGDate /st $ReCFGTime /F"
			#Start-Process schtasks.exe -ArgumentList $SchMigConfigTask -Wait -NoNewWindow
			Invoke-VMScript -GuestCredential $Guestcred -ScriptText $SchReCFGScriptDestFile -ScriptType Bat -VM $VMName
	#		Restart-VMGuest -VM $VMName
			
			}
	
		IF ($QueryMethod -ieq "VMTools")
			{
			$CleanupDestStr = "CMD.EXE /C IF EXIST $DestinationPath DEL /F /Q $DestinationPath &  IF EXIST $DestinationPath RMDIR /S /Q $DestinationPath"
			$CreateDestDir = "CMD.EXE /C IF NOT EXIST $DestinationPath MD $DestinationPath"
			Invoke-VMScript -VM $VMName -GuestCredential $GuestCred -ScriptText $CleanupDestStr -ScriptType Bat
			Invoke-VMScript -VM $VMName -GuestCredential $GuestCred -ScriptText $CreateDestDir -ScriptType Bat
			Copy-VMGuestFile -Source .\Output_Scripts\$ReCFGScriptoutFileName -Destination $DestinationPath -VM $VMName -LocalToGuest -GuestCredential $GuestCred -HostCredential $Hostcred	-Force
			Copy-VMGuestFile -Source .\Output_Scripts\$SchReCFGTaskFileName -Destination $DestinationPath -VM $VMName -LocalToGuest -GuestCredential $GuestCred -HostCredential $Hostcred	-Force
			Copy-VMGuestFile -Source .\nvspbindxp.exe -Destination $DestinationPath -VM $VMName -LocalToGuest -GuestCredential $GuestCred -HostCredential $Hostcred	-Force
			Copy-VMGuestFile -Source .\sleep.exe -Destination $DestinationPath -VM $VMName -LocalToGuest -GuestCredential $GuestCred -HostCredential $Hostcred	-Force
			#Copy-VMGuestFile -Source .\TSM_local_backup_Post.vbs -Destination $DestinationPath -VM $VMName -LocalToGuest -GuestCredential $GuestCred -HostCredential $Hostcred	-Force
			$SchMigConfigTaskStr = "schtasks.exe /create /RU ""SYSTEM"" /V1 /sc ONCE /tn ""ScheduleMigration Config"" /TR ""$SchReCFGScriptDestFile"" /sd $ReCFGDate /st $ReCFGTime /F"
	#		Invoke-VMScript -GuestCredential $Guestcred -ScriptText $SchMigConfigTaskStr -ScriptType Bat -VM $VMName
			Invoke-VMScript -GuestCredential $Guestcred -ScriptText $SchReCFGScriptDestFile -ScriptType Bat -VM $VMName
			}
		
		$ErrLogVMNameFooter = "`r`n^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^`r`n`r`n`r`n"
		Add-Content $ErrFile $ErrLogVMNameFooter
		
		}	
	}