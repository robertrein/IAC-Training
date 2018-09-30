###############################################################################################################################
###############################################################################################################################                                                         
#### Script by George Giani                                                                                                ####
#### April 2014                                                                                                            ####
####                                                                                                                       ####
#### IMPORTANT:  Run this command prior to executring this script:  'Set-ExecutionPolicy RemoteSsigned'.                   ####
#### Set-ExecutionPolicy only needs to be run one time on the machine on which the script will run.                        ####
#### Script will join domain, so ensure IP/DNS & computer name are configured correctly before running script.             ####
#### Also ensure all local disks are & formatted.                                                                          ####
###############################################################################################################################
###############################################################################################################################

#### Ask for prerequisites, exit script if not met ####
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.MessageBox]::Show("Important pre-requisites: `r`n `r`nComputername must be configured. `r`nIP/DNS must be configured. `r`nAll local disks must be formatted." , "Pre-requisites" , 0)
$output = [System.Windows.Forms.MessageBox]::Show("Also, first run the 'AD Groups' script on a DC if you want the global groups added to the local groups on this server. `
`r`nYou'll be prompted about this later but it's best to first run the 'AD Groups' script on a DC. `
`r`nAre you ready to proceed?" , "Prerequisites" , 4)
if ($output -eq "NO")
{
    [System.Windows.Forms.MessageBox]::Show("Make sure to apply the prerequisite configuration items, `r`nthen re-run this script. `r`n`r`nExiting now..." , "Prerequisites" , 0)
    Exit
}
    else
{
    [System.Windows.Forms.MessageBox]::Show("OK, Let's continue... `n `
    What the script does: `n `
    Set power profile to `"High Performance`". `
    Turn off hibernation. `
    Set DVD Drive letter (from supplied input). `
    Disable services. `
    Remove Z$ shares from registry. `
    Add SNMP Feature. `
    Disable UAC, Disable IE ESC. `
    Disable Windows Error Reporting. `
    Remove 'Everyone' from security on all local disks. `
    Create Temp folder on C: and also on supplied Transient disk. `
    Modify Temp and TMP variables to use supplied Transient disk. `
    Set pagefile size (from supplied input). `
    Move pagefile to supplied transient disk. `
    Set the time zone (from supplied input). `
    Set the RDP security layer. `
    Join the domain from supplied domain name. `
    Add domain groups computername-Admins/Powerusers/Users to corresponding local groups." , "Run the script" , 0)   
}
#######################################################

#### Configure Power options ####
powercfg.exe /SETACTIVE 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c    #set power profile to high performance
powercfg.exe /h off    #turns off hibernation
Write-Host "Power profile set to 'high performance', hibernation turned off..."    #diagnostics
#################################

#### Set DVD drive letter ####
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$dvdletter = [Microsoft.VisualBasic.Interaction]::InputBox("Enter desired drive letter for DVD drive (e.g., Z:)" , "DVD Drive Letter")  #collect desired DVD drive letter
$pat = "[defghijklmnopqrstuvwxyz]:"  #pattern to test if letter and colon entered

while (!($dvdletter -match $pat) -or $dvdletter.length -ne 2)  #test if input is correct (letter & colon, 2 characters long); reject input and repeat if conditions not met
{
[System.Windows.Forms.MessageBox]::Show("Invalid input.`r`nEnter Single drive letter and colon (e.g., Z:)" , "Invalid Input" , 0)
$dvdletter = [Microsoft.VisualBasic.Interaction]::InputBox("Enter desired drive letter for DVD drive (e.g., Z:)" , "DVD Drive Letter")  #collect desired DVD drive letter
}

(gwmi Win32_cdromdrive).drive | %{$a = mountvol $_ /l;mountvol $_ /d;$a = $a.Trim();mountvol "$dvdletter" $a}  #set DVD drive letter
Write-Host "DVD Drive letter set to $dvdletter..."  #diagnostics
####################################

#### Collect Transient Disk Drive letter ####
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null
$arraydisk =@()  #array to store logical disks
$arraysize =@()  #array to store logical disk sizes
$arrayvolname =@()  #array to store volume names
$coldisks = Get-WmiObject -query "select * from win32_logicaldisk where DriveType = '3'"
foreach ($drive in $coldisks)    #build the array of logical disks
    {
    $disk = $drive.DeviceID
    $space = $drive.size
    $volname = $drive.VolumeName
    $arraydisk += $disk
    $arraysize += [math]::round(($space/1024/1024/1024), 2)
    $arrayvolname += $volname
    }
$count = $arraydisk.count -1  #store number of elements (number of logical drives) for later use

[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Select the transient disk..."
$objForm.Size = New-Object System.Drawing.Size(300,200) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$script:Transient=$objListBox.SelectedItem;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$script:Transient=$objListBox.SelectedItem.Substring(0,2);$objForm.Close()})
#$OKButton.Add_Click({$script:Transient=$objListBox.SelectedItem;$objForm.Close()})

$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(280,20) 
$objLabel.Text = "Disk:     Volume:          Total Size(GB):"
$objForm.Controls.Add($objLabel) 

$objListBox = New-Object System.Windows.Forms.ListBox 
$objListBox.Location = New-Object System.Drawing.Size(10,40) 
$objListBox.Size = New-Object System.Drawing.Size(260,20) 
$objListBox.Height = 80

$i = 0    #counter variable
while ($i -le $count) {
[void] $objListBox.Items.Add(($arraydisk[$i]) + "`t" + ($arrayvolname[$i]) + "`t`t" + ($arraysize[$i]))    #add logical disks (from array) to input box
#[void] $objListBox.Items.Add($arraysize[$i])
$i += 1
}

$objForm.Controls.Add($objListBox) 
$objForm.Topmost = $True
$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()

Write-Host "Transient disk $Transient selected..."  #diagnostics
################################

#### Set Time Zone  ####
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 

$objForm = New-Object System.Windows.Forms.Form 
$objForm.Text = "Time Zone"
$objForm.Size = New-Object System.Drawing.Size(300,200) 
$objForm.StartPosition = "CenterScreen"

$objForm.KeyPreview = $True
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter") 
    {$script:x=$objListBox.SelectedItem;$objForm.Close()}})
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape") 
    {$objForm.Close()}})

$OKButton = New-Object System.Windows.Forms.Button
$OKButton.Location = New-Object System.Drawing.Size(75,120)
$OKButton.Size = New-Object System.Drawing.Size(75,23)
$OKButton.Text = "OK"
$OKButton.Add_Click({$script:x=$objListBox.SelectedItem;$objForm.Close()})

$objForm.Controls.Add($OKButton)

$CancelButton = New-Object System.Windows.Forms.Button
$CancelButton.Location = New-Object System.Drawing.Size(150,120)
$CancelButton.Size = New-Object System.Drawing.Size(75,23)
$CancelButton.Text = "Cancel"
$CancelButton.Add_Click({$objForm.Close()})
$objForm.Controls.Add($CancelButton)

$objLabel = New-Object System.Windows.Forms.Label
$objLabel.Location = New-Object System.Drawing.Size(10,20) 
$objLabel.Size = New-Object System.Drawing.Size(280,20) 
$objLabel.Text = "Please select the time zone:"
$objForm.Controls.Add($objLabel) 

$objListBox = New-Object System.Windows.Forms.ListBox 
$objListBox.Location = New-Object System.Drawing.Size(10,40) 
$objListBox.Size = New-Object System.Drawing.Size(260,20) 
$objListBox.Height = 80

[void] $objListBox.Items.Add("Eastern Standard Time")
[void] $objListBox.Items.Add("Central Standard Time")
[void] $objListBox.Items.Add("Mountain Standard Time")
[void] $objListBox.Items.Add("Pacific Standard Time")

$objForm.Controls.Add($objListBox) 

$objForm.Topmost = $True

$objForm.Add_Shown({$objForm.Activate()})
[void] $objForm.ShowDialog()

tzutil.exe /s $x     # set time zone to the one selected from list box
Write-Host "Time zone set to $x..."  #diagnostics
######################################################

#### Create Temp folders ####
if (!(Test-Path -Path C:\Temp)) {     # check if C:\Temp exists
    New-Item C:\Temp -ItemType directory | Out-Host     # create C:\Temp only if it doesn't exist already
    }
if (!(Test-Path -Path $Transient\Temp)) {    # check if \Temp exists on transient disk
    New-Item $Transient\Temp -ItemType directory | Out-Host    # create \Temp (on Transient disk) only if it doesn't exist already
    }
write-host "Temp folders created..."    #diagnostics
##############################

#### Move environment variables (Temp, TMP) to user-supplied transient disk ####
Write-Host $Transient
[Environment]::SetEnvironmentVariable("TEMP", "$Transient\Temp", "Machine")
[Environment]::SetEnvironmentVariable("TMP", "$Transient\Temp", "Machine")
write-host "Environment variables modified..."    #diagnostics
################################################################################

#### Move pagefile to user-supplied transient disk ####

gwmi Win32_ComputerSystem -EnableAllPrivileges | swmi -Arguments @{AutomaticManagedPagefile=$false}
$CurrentPageFile = gwmi -Query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'" -EnableAllPrivileges    # Get current paging file on drive C:
If($CurrentPageFile){$CurrentPageFile.Delete()}    # Delete current paging file on drive C:

$disk = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$Transient'"  #  get transient disk properties
Select-Object Size,FreeSpace  

$size = $disk.Size  #get transient disk size
$sizeGB = $size/1024/1024/1024  #convert size in bytes to size in GB
Write-Host "transient size in GB is " $sizeGB  #diagnostics
$rounded = [decimal]::round($sizeGB)  #round to nearest GB
write-host "rounded size is" $rounded  #diagnostics

[int]$pagefilesize = [Microsoft.VisualBasic.Interaction]::InputBox("Transient disk is $rounded GB. Enter desired pagefile size (whole number - in GB) no larger than $rounded" , "Pagefile Size")  #collect desired pagefile size

while (!($pagefilesize -is [Int32]) -or ($pagefilesize -ge $rounded))  #test if input is a number and smaller than size of transient disk; reject input and repeat if conditions not met
{
[System.Windows.Forms.MessageBox]::Show("Invalid input.`r`nPagefile size must be a whole number only.`r`nAlso Pagefile must be smaller than $rounded GB.`r`nPlease try again." , "Invalid Input" , 0)
[int]$pagefilesize = [Microsoft.VisualBasic.Interaction]::InputBox("Transient disk is $rounded GB. Enter desired pagefile size (whole number - in GB) no larger than $rounded" , "Pagefile Size")  #collect desired pagefile size
}

$size = [int]$pagefilesize * 1024  #calculate size in MB

#Write-Host $size  #debugging
swmi Win32_PageFileSetting -Arguments @{Name="$Transient\pagefile.sys"; InitialSize=$size; MaximumSize=$size}    # Create paging file on selected Transient disk
Write-Host "Pagefile moved to $Transient..." #diagnostics
########################################################

#### Remove 'Everyone' permission from root of all logical disks ####
$coldisks = Get-WmiObject -query "select * from win32_logicaldisk where DriveType = '3'"
foreach ($drive in $coldisks)
    {
    $disk = $drive.DeviceID
    icacls $disk\ /remove Everyone
    }
Write-Host "Removed 'Everyone' permissions from local disks..."    #diagnostics
#####################################################################

####  Misc Registry tweaks  ####
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v HideFileExt /t REG_DWORD /d 0 /f  # always show file extensions
reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v AlwaysShowMenus /t REG_DWORD /d 1 /f  # always show explorer menus
Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\system -Name EnableLUA -Value 0     # disable UAC
Set-ItemProperty -Path registry::"HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name SecurityLayer -Value 0     # Set RDP security layer
Set-ItemProperty -Path registry::"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\Windows Error Reporting" -Name Disabled -Value 1    #Disable Windows Error Reporting
Write-Host "Applied registry fixes: Disable UAC, set RDP Security Layer, disable Windows Error Reporting...."    #diagnostics
###############################

#### Remove Z$ shares ####
Remove-ItemProperty -path registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\LanmanServer\Shares -Name z$ -ErrorAction SilentlyContinue
Remove-ItemProperty -path registry::HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\services\LanmanServer\Shares -Name z$ -ErrorAction SilentlyContinue
Remove-ItemProperty -path registry::HKEY_LOCAL_MACHINE\SYSTEM\ControlSet002\services\LanmanServer\Shares -Name z$ -ErrorAction SilentlyContinue
Write-Host "Z$ shares removed..."    #diagnostics
##########################

#### disable IE ESC ####
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0
Stop-Process -Name Explorer
Write-Host "IE ESC Disabled..."    #diagnostics
#######################################################

#### disable services ####
Set-Service -Name spooler -StartupType disabled     #print spooler
Stop-Service -Name spooler -Force
Set-Service -Name CertPropSvc -StartupType disabled     #Certificate Propogation
Stop-Service -Name CertPropSvc -Force
Set-Service -Name WerSvc -StartupType disabled     #Windows Error Reporting
Stop-Service -Name WerSvc -Force
Set-Service -Name iphlpsvc -StartupType disabled     # IP Helper
Stop-Service -Name iphlpsvc -Force
Set-Service -Name hidserv -StartupType disabled     # Human Interface Device
Stop-Service -Name hidserv -Force
Set-Service -Name NlaSvc -StartupType disabled     # Network Location Awareness
Stop-Service -Name NlaSvc -Force
Set-Service -Name netprofm -StartupType disabled     # Network List Service
Stop-Service -Name netprofm -Force
Set-Service -Name ShellHWDetection -StartupType disabled     # Shell Hardware Detection
Stop-Service -Name ShellHWDetection -Force
Set-Service -Name AudioSrv -StartupType disabled     # Windows Audio
Stop-Service -Name AudioSrv -Force
Set-Service -Name MpsSvc -StartupType disabled     # Windows Firewall
Stop-Service -Name MpsSvc -Force
Write-Host "Required services have been disabled..."    #diagnostics
#################################################################################

#### Set required services to auto ####
Set-Service -Name PolicyAgent -StartupType automatic     # IPSec Policy Agent
Set-Service -Name W32Time -StartupType automatic     # Windows Time
Write-Host "Required services set to Auto..."    #diagnostics
#################################################################################

#### Install SNMP ####
Write-Host "Installing SNMP..."
Import-Module ServerManager
$check = Get-WindowsFeature | Where-Object {$_.Name -like "SNMP-Serv*"}     #check if SNMP is already installed
if ($check.Installed -ne "True")    #Check if SNMP is installed already
{    
    $version = [Environment]::OSVersion.Version    #Check Windows version (syntax changed in Windows 2012)
    Write-Host "Windows version is: " $version 
    if ($version -ge (New-Object 'version' 6,2))    #Windows Server 2012
    {
        Add-WindowsFeature -Name SNMP-Service -IncludeAllSubFeature -IncludeManagementTools | Out-Null    #Install SNMP - Windows 2012
    }
    else 
    {
        Add-WindowsFeature SNMP-Services -IncludeAllSubFeature | Out-Null     #Install SNMP - Windows 2008 R2  
    }
    Write-Host "SNMP Installed successfully."    #diagnostics
}
else    #SNMP already installed
{
    [System.Windows.Forms.MessageBox]::Show("SNMP is already installed. Continuing the script..." , "SNMP" , 0)
}

#### Set SNMP Services ####
Set-Service -Name SNMP -StartupType automatic     # IPSec Policy Agent
Set-Service -Name SNMPTRAP -StartupType manual     # WIndows Time
Write-Host "SNMP services startup properties have been set..."    #diagnostics
############################

#### Join Domain ####
$domain = [Microsoft.VisualBasic.Interaction]::InputBox("Enter Domain FQDN to join:" , "Domain")
#$username = [Microsoft.VisualBasic.Interaction]::InputBox("Enter your $domain user name:" , "Username")
$credentials = Get-Credential    #asks for domain credentials
#$credentials = "$domain\$username"
Add-Computer -DomainName $domain -Credential $credentials    #join the domain
Write-Host "Domain join to $domain complete..."    #diagnostics
##########################

#### Add Global groups to local groups ####
$name = (Get-WmiObject Win32_ComputerSystem).Name    #Get current host name
Write-Host "Computer name is:" $name    #diagnostics
$output = [System.Windows.Forms.MessageBox]::Show("Have you run the 'AD Groups' script on a DC?" , "Groups" , 4)
if ($output -eq "NO")
{
    [System.Windows.Forms.MessageBox]::Show("You'll need to run the 'AD Groups' script on a DC in the $domain domain. `
    `nOtherwise create the following domain groups manually: `
    `n$name-Admins `n$name-Powerusers `n$name-Users `
    `r`nYou'll then need to add these to their corresponding local groups on this server." , "Groups" , 0)
}
    else
{
Write-Host "domain is " $domain    #diagnostics
    [System.Windows.Forms.MessageBox]::Show("OK. Trying to add the domain groups to the local groups... `
    `r`nCheck the local groups after script execution to be sure." , "Groups" , 0)
    ([adsi]'WinNT://./Administrators,group').Add("WinNT://$domain/$name-Admins")    #add to Administrators local group
    ([adsi]'WinNT://./Power Users,group').Add("WinNT://$domain/$name-Powerusers")    #add to Power Users local group
    ([adsi]'WinNT://./Users,group').Add("WinNT://$domain/$name-Users")    #add to Users local group
}
############################################

$output = [System.Windows.Forms.MessageBox]::Show("Reboot required.  Do you want to reboot now?" , "Reboot required" , 4)
if ($output -eq "YES")
{ 
    Restart-Computer |Out-Null     # reboot if 'yes' selected
}
    else
{
[System.Windows.Forms.MessageBox]::Show("OK.  Don't forget to reboot later!", "Reboot required", 0)
}
