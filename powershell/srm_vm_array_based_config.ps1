<#
.SYNOPSIS
Protect a VM using SRM issuing the $ProtFlag value of "Protect"
Un-Protect a VM using SRM issuing the $ProtFlag value of "Un-protect"

.PARAMETER ServerAddr
VCENTER Server hosting the VMToBeConfigured

.PARAMETER User
User with appropriate permissions to configure SRM server

.PARAMETER Password
Password of User

.PARAMETER VMToBeConfigured
Virtual machine to be configure

.PARAMETER ProtFlag
Only 2 values are accepted, "protect" or "un-protect"

#>
Param(
	[parameter(Mandatory=$True)]
        [string]$ServerAddr,
	[parameter(Mandatory=$True)]
        [string]$User,
	[parameter(Mandatory=$True)]
        [string]$Password,
	[parameter(Mandatory=$True) ]
	[string]$VMToBeConfigured,
	[parameter(Mandatory=$True)]
	[string]$ProtFlag
)
Function EndOfJob()
{
	disconnect-srmserver -force -confirm:$false
	disconnect-viserver -force -confirm:$false
	Write-Host "Result Error Code:"$ErrorCode
	Write-Host "Result Description:"$ReturnStatus
	Write-Host ""
	sleep 15
	exit
}
add-pssnapin VMware.VimAutomation.Core


$global:ErrorCode=1   #Error Code Returned set to failed by default
$global:ReturnStatus=""
$MinimumStoragePerc=5
$DataStorePrefix="arep"





$Vcenter=Connect-VIServer -Server $ServerAddr -User $User -Password $Password
$Srm=Connect-SrmServer -RemoteUser $user -RemotePassword $Password
#Check to see correct protection flag was requested
if ($ProtFlag.ToUpper() -ne "PROTECT" -And $ProtFlag.ToUpper() -ne "UNPROTECT")
{
	Write-Host "Protection Flag must be Protect or UnProtect"
	$ErrorCode=1
	$ReturnStatus="Invalid-Protection-Flag:"+$ProtFlag
	EndOfJob
}
$error.clear()
$vmToAdd=get-vm $VMToBeConfigured
if ($error.count -ne 0)
{
	$ErrorCode=1
	$ReturnStatus="VM-is-not-located-in-this-vcenter:"+$VMToBeConfigured
	EndOfJob
}
$VMID=$VMToAdd.id
#Check to see all datastores associated with VM has 5% or more available space
if ($ProtFlag.ToUpper() -eq "PROTECT")
{
	Foreach($ds in get-datastore -vm $VMToBeConfigured)
	{
		$DsNamePrefix=$ds.name.substring(0,4)
		if ($DsNamePrefix.ToUpper() -ne $DataStorePrefix.ToUpper())
		{
			$ErrorCode=1
			$ReturnStatus=$ds.name + " does not have the " + $DataStorePrefix + " prefix"
			EndOfJob
		}
		
		$PercFree=(100-(($ds.freespacegb/$ds.capacitygb)*100))
		if ($PercFree -lt $MinimumStoragePerc)
		{
			$ErrorCode=1
			$ReturnStatus=$ds.Name + " less then " + $MinimumStoragePerc + " percent free"
			EndOfjob
		}
	}
}

$srmApi = $srm.ExtensionData
$protectionGroups = $srmApi.Protection.ListProtectionGroups()

$NumberOfGroups=0
foreach ($ProtectionGroup in $protectionGroups)
{
	$NumberOfGroups++
}

$NumberOfGroups=$NumberOfGroups-1
$i=0
do {
	$GroupInfo=$ProtectionGroups[$i].GetInfo()
	$targetProtectionGroup = $GroupInfo.Name
	$ProtectedVMs=$ProtectionGroups[$i].ListProtectedVMs()
	$targetProtectionGroup = $protectionGroups | where {$_.GetInfo().Name -eq $GroupInfo.Name }
	$protectionSpec = New-Object VMware.VimAutomation.Srm.Views.SrmProtectionGroupVmProtectionSpec
	$protectionSpec.Vm = $vmToAdd.ExtensionData.MoRef
	if ($ProtFlag.ToUpper() -eq "PROTECT")
	{
		$ProtectedVMs=$ProtectionGroups[$i].ListProtectedVMs()
		foreach($VM in $ProtectedVMs)
		{
			$VM=$VM.Vm.MoRef.Type + "-" + $VM.Vm.MoRef.Value
			if($VM -eq $VMID)
			{
				$ErrorCode=0
				$ReturnStatus="Protected"
				EndOfJob
			}
		}



		$protectTask = $targetProtectionGroup.ProtectVms($protectionSpec)
		while(-not $protectTask.IsComplete()) { sleep -Seconds 1 } 

		$ProtectedVMs=$ProtectionGroups[$i].ListProtectedVMs()
		foreach($VM in $ProtectedVMs)
		{
			$VM=$VM.Vm.MoRef.Type + "-" + $VM.Vm.MoRef.Value
			if($VM -eq $VMID)
			{
				$ErrorCode=0
				$ReturnStatus="Protected"
				EndOfJob
			}
			else
			{
				$ErrorCode=1
				$ReturnStatus="Unprotected"
			}
		}
		
	}
	else
	{
		$ProtectedVMs=$ProtectionGroups[$i].ListProtectedVMs()
		foreach($VM in $ProtectedVMs)
		{
			$VM=$VM.Vm.MoRef.Type + "-" + $VM.Vm.MoRef.Value
			if($VM -eq $VMID)
			{
				$protectTask=$targetProtectionGroup.unprotectVms($VM)
				while(-not $protectTask.IsComplete()) { sleep -Seconds 1 }
			}
		}
		$ProtectedVMs=$ProtectionGroups[$i].ListProtectedVMs()
		foreach($VM in $ProtectedVMs)
		{
			$VM=$VM.Vm.MoRef.Type + "-" + $VM.Vm.MoRef.Value
			if($VM -eq $VMID)
			{
				$ErrorCode=1
				$ReturnStatus="Protected"

			}
			else
			{
				$ErrorCode=0
				$ReturnStatus="Unprotected"
			}
		}

	}

	$i++	
}
While ($i -le $NumberOfGroups)

EndOfJob