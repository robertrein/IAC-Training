$timestamp = Get-Date -format "yyyyMMdd-HH.mm"
 
# $csvFile = Read-Host "Enter csv file"
$csvfile = "C:\users\rrein\desktop\$timestamp-vminfo.csv"
 
$vCenter = "slcp7vmctr04.pcl.ingenix.com"
Connect-VIServer $vCenter
 
$myCol = @()
 
# All VMs
foreach ($VM in (Get-VM)){
# Folder
# foreach ($VM in (get-folder testfolder | get-vm )){
# Host
# foreach ($vm in (get-vmhost testhost.domain | get-vm )){
# Test one VM
#foreach ($VM in (Get-VM WINXP-TESTVM)){
 
# All VMs
#foreach ($VM in (Get-VM)){
# Test one VM
# foreach ($VM in (Get-VM ROAPRDT301)){
# Folder
# foreach ($VM in (get-folder Frankfurt | get-vm )){
# Host
#foreach ($vm in (get-vmhost esxprd101.intranet | get-vm )){
 
$vmnic = Get-NetworkAdapter -VM $VM
$vmview = Get-VM $VM | Get-View
# Below is the original command that gave the working command I need to get all MacAddresses
# Get-VM | Select-Object -Property Name,@{N="MacAdresses";E={$_.NetworkAdapters | ForEach-Object {$_.MacAddress}}},VMHost
# Get output without headers: | format-wide -column 1
$nicmac = Get-NetworkAdapter -VM $VM | ForEach-Object {$_.MacAddress}
$nictype = Get-NetworkAdapter -VM $VM | ForEach-Object {$_.Type}
$nicname = Get-NetworkAdapter -VM $VM | ForEach-Object {$_.NetworkName}
# Get multiple scsi adapters
$scsiname = Get-ScsiController -VM $VM | Foreach-Object {$_.Name}
$scsitype = Get-ScsiController -VM $VM | Foreach-Object {$_.Type}
# If GuestOS is Windows XP or Windows Server 2003 it's possible to get the network information from the Guest itself
# To make this work you need credentials for the guest
while ($credentials -eq $null) {
  Write-Host (get-date -uformat %I:%M:%S) "Please provide authentication credentials for VM Guest Operating System(s)" -ForegroundColor Green;
  #$credentials = Get-Credential -Credential ""
  $credentials = $Host.UI.PromptForCredential("Please enter credentials", "Enter Guest credentials", "Administrator", "")
}
 
$VMInfo = "" |select-Object VMName,VMHostName,NICCount,IPAddress,MacAddress,NICType,NetworkName,SCSIControllers,SCSIType,CPUReservation,CPULimit,CPUShares,NumCPU,MEMSize,MEMReservation,MEMLimit,MEMShares,GuestFamily,GuestSelectedOS,GuestRunningOS,PowerState,ToolsVersion,ToolsStatus,ToolsRunningStatus,HWLevel,VMHost,GuestIPpolicy,GuestIP,GuestSubnetMask,GuestDefaultGateway,GuestDNSPolicy,GuestDNSServers
$VMInfo.VMName = $vmview.Name
$VMInfo.VMHostName = $vmview.Guest.HostName
$VMInfo.NICCount = $vmview.Guest.Net.Count
$VMInfo.IPAddress = [String]$VM.Guest.IPAddress
# If you need the IPaddresses specifically specified you can use this:
#$VMInfo.IPAddress1 = $VM.Guest.IPAddress[0]
#$VMInfo.IPAddress2 = $VM.Guest.IPAddress[1]
#$VMInfo.IPAddress3 = $VM.Guest.IPAddress[2]
$VMInfo.MacAddress = [String]$nicmac
$VMInfo.NICType = [String]$nictype
$VMInfo.NetworkName = [String]$nicname
# This options shows the connection state of the NIC. Uncomment if needed.
#$VMInfo.NICState = $vmnic.ConnectionState.Connected
$VMInfo.SCSIControllers = [String]$scsiname
$VMInfo.SCSIType = [String]$scsitype
$VMInfo.CPUReservation = $vmview.Config.CpuAllocation.Reservation
If ($vmview.Config.CpuAllocation.Limit-eq "-1"){
   $VMInfo.CPULimit = "Unlimited"}
Else{
   $VMInfo.CPULimit = $vmview.Config.CpuAllocation.Limit
}
$VMInfo.CPUShares = $vmview.Config.CpuAllocation.Shares.Shares
$VMInfo.NumCPU = $VM.NumCPU
$VMInfo.MEMSize = $vmview.Config.Hardware.MemoryMB
$VMInfo.MEMReservation = $vmview.Config.MemoryAllocation.Reservation
If ($vmview.Config.MemoryAllocation.Limit-eq "-1"){
   $VMInfo.MEMLimit = "Unlimited"}
Else{
   $VMInfo.MEMLimit = $vmview.Config.MemoryAllocation.Limit
}
$VMInfo.MEMShares = $vmview.Config.MemoryAllocation.Shares.Shares
$VMInfo.GuestFamily = $vmview.Guest.GuestFamily
$VMInfo.GuestSelectedOS = $vmview.Summary.Config.GuestFullName
$VMInfo.GuestRunningOS = $vmview.Guest.GuestFullname
$VMInfo.PowerState = $VM.PowerState
$VMInfo.ToolsVersion = $vmview.Guest.ToolsVersion
$VMInfo.ToolsStatus = $vmview.Guest.ToolsStatus
$VMInfo.ToolsRunningStatus = $vmview.Guest.ToolsRunningStatus
$VMInfo.HWLevel = $vmview.Config.Version
$VMInfo.VMHost = $VM.VMHost
if (($VMInfo.GuestRunningOS -match "2003") -or ($VMInfo.GuestRunningOS -match "XP") -and ($VMInfo.PowerState -eq "PoweredOn") -and ($VMInfo.ToolsStatus -eq "ToolsOK")){
  $GuestInterface = Get-VMGuestNetworkInterface -VM $VM -GuestCredential $credentials;
  $VMInfo.GuestIPpolicy = $GuestInterface.IPPolicy;
  $VMInfo.GuestIP = $GuestInterface.Ip;
  $VMInfo.GuestSubnetMask = $GuestInterface.SubnetMask;
  $VMInfo.GuestDefaultGateway = $GuestInterface.DefaultGateway;
  $VMInfo.GuestDNSPolicy = $GuestInterface.DnsPolicy;
  $VMInfo.GuestDNSServers = [string]$GuestInterface.Dns
}
else{
  $VMInfo.GuestIPpolicy = "Not available for this Guest OS, PowerState or ToolsStatus"
}
 
$myCol += $VMInfo
}
 
$myCol |Export-csv -NoTypeInformation $csvfile
 
# Disconnect-VIServer -Confirm:$false