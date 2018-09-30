Function ExitApp
{
		cls
		Write-Host "Disconnecting from VCenter Server...ignore error if displayed"
		sleep 5
		disconnect-viserver -force
		exit
}
Function PromptField($Question)
{
	
	Write-Host "Type Q for (Q)uit"
	$Variable=Read-Host -Prompt $Question
	if ($Variable.ToUpper() -eq "Q")
	{
		ExitApp
	}
	if ($Variable -eq "")
	{
		Write-Host "Field required"
		PromptField($Question)
	}
	else
	{
		cls
		Return $Variable
	}
}

Function GetVMClient
{
	$global:VMClient=PromptField("Please enter VMWare Client Server Name[FQDN]")
	$FindChar=$VMClient.IndexOf(".")
	if ($FindChar -eq -1)
	{
		Write-Host "Please enter a FQDN please"
		GetVMClient
	}
	if(!(Test-Connection -Cn $VMClient -BufferSize 16 -Count 1 -ea 0 -quiet))
	{	
		Write-Warning "Cannot Reach Server $VMClient"
		GetVMClient
	}
	Return $VMClient
}

Function GetCluster
{

	get-cluster >cluster.txt
	type cluster.txt
	$global:VMCluster=PromptField("Please Enter the CLUSTER Name to add guest to")
	$CheckCluster=get-cluster $VMCluster
	if ($CheckCluster -eq $NULL)
	{
		Write-output "Cluster not found"
		GetCluster
	}
}
Function GetTemplate
{
	get-template >template.txt
	type template.txt
	$global:VMTemplate=PromptField("Please enter Template name to use")
	$CheckTemplate=get-template $VMTemplate
	if ($CheckTemplate -eq $NULL)
	{
		Write-output "Template not found"
		GetTemplate
	}
}
Function GetESX
{
	get-vmhost -location $VMCluster >esx.txt
	type esx.txt
	$global:VMServer=PromptField("Please enter ESX host to put guest")
	$CheckEsx=get-vmhost $VMServer
	if ($CheckEsx -eq $NULL)
	{
		Write-output "ESX Host not found"
		GetESX
	}
}
Function GetDatastore
{
	Get-Datastore -Location $VMCluster >datastore.txt
	type datastore.txt
	$global:VMDataStore=PromptField("Please enter DATASTORE to put Guest on")
	$CheckDatastore=Get-Datastore $VMDataStore
	if ($CheckDatastore -eq $NULL)
	{
		Write-Output "Datastore not Found"
		GetDatastore
	}
}
Function GetAdapter
{
	$global:Adapter=Get-NetworkAdapter -VM $VMGuestName
	$Adapter
	$CheckAdapter=Get-NetworkAdapter -VM $VMGuestName $Adapter
	$CheckAdapter
	
}

cls
$VMClient=GetVMClient
$User=PromptField("Please enter user name")
$Password=PromptField("Please enter Password")

Write-Output "Connecting to VCLient " $VMClient
Connect-VIserver -Server $VMClient -Protocol https -User $User -Password $Password

GetCluster

$VMGuestName=PromptField("Please enter the VMWare Guest Name")
$VMGuestUser=PromptField("Please Enter the Windows OS Administrator User Name")
$VMGuestPassword=PromptField("Please Enter the Windows OS Password")
$VMGuestMemory=PromptField("Please Enter the amount of memory to allocate")
$VMGuestCPU=PromptField("Please Enter the Total CPU Count")
GetTemplate
GetESX
GetDatastore

Write-Output "Please Review your Settings Before continuing"
Write-Output ""
Write-Output "Cluster Name is: $VMCluster"
Write-Output "VM Guest Name is: $VMGuestName"
Write-Output "VM Guest User is: $VMGuestUser"
Write-Output "VM Guest Password is: $VMGuestPassword"
Write-Output "VM Template to Create VM From is: $VMTemplate"
Write-Output "VM ESX Host is: $VMServer"
Write-Output "VM Will be Stored in Datastore: $VMDataStore"
$Answer=Read-Host -Prompt "Do you want to continue Y/N"
if ($Answer.ToUpper() -eq "N")
{
	ExitApp
}
cls
Write-Warning "Creating Virtual Guest $VMGuestName"
New-VM -Template $VMTemplate -VMHost $VMServer -Name $VMGuestName -Datastore $VMDataStore
cls

Set-VM -VM $VMGuestName -MemoryGB $VMGuestMemory -NumCPU $VMGuestCPU

Write-Warning "Starting Virtual Guest $VMGuestName"
Start-VM $VMGuestName
Sleep 30
$Dummy=Read-Host -Prompt "Please sign onto VM as administrator and all initial OS startups are done....then press return"
Write-Output "Mounting VMWARE TOOLS"
mount-tools $VMGuestName
$Dummy=Read-Host -Prompt "Press Return after VMWARE tools is completed, system has rebooted, and you are signed back into windows..."

GetAdapter

Get-VirtualPortGroup $VMServer >port.txt
type port.txt
del port.txt
$PortGroup=PromptField("Enter Port Group to connect to[case sensitive]")

Set-NetworkAdapter -NetworkAdapter $Adapter -NetworkName $PortGroup -StartConnected:$true -Connected:$true




$IPAddress=PromptField("Please enter IP Address to assign")
$IPSubNet=PromptField("Please enter Subnet Address to assign")
$Gateway=PromptField("Please enter Gateway Address")
$DNS1=PromptField("Please enter DNS1 Address")
$DNS2=PromptField("Please enter DNS2 Address")

$VMGuestNetworkInterface=Get-VMGuestNetworkInterface -VM $VMGuestName
Set-VMGuestNetworkInterface -VmGuestNetworkInterface $VMGuestNetworkInterface -DnsPolicy Static -IPPolicy Static -Ip $IPAddress -Netmask $IPSubNet -Gateway $Gateway -Dns $DNS1,$DNS2



