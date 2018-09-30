Param(
  [string]$inputFile
)
#$cred=get-credential
Import-Module -Name VMware.VimAutomation.Core
#connect-viserver -server rz050mn011v1mc.optumfe.com -Credential $cred

connect-viserver -server rz050mn011v2gc.optumfe.com


$VirtualMachinesCSV = $inputFile
$strDescription = "Created from template and CSV by Charles Colstrom"
echo "Got Here"
$VirtualMachinesDetails = Import-CSV $VirtualMachinesCSV
$VirtualMachinesDetails
#$VirtualMachinesDetails | %{ New-VM -Name $_.Name -Template $(Get-Template  $_.Template) -VMHost $($_.DestinationHost) -OSCustomizationSpec $(Get-OSCustomizationSpec $_.CustomSpec) }
$VirtualMachinesDetails | %{ New-VM -Name $_.Name -Template $(Get-Template  $_.Template) -ResourcePool $($_.DestinationHost) -OSCustomizationSpec $(Get-OSCustomizationSpec $_.CustomSpec) }
$VirtualMachinesDetails | %{ Set-VM -VM $_.Name -NumCpu $_.NumCpu -MemoryMB $_.MemoryMB -Description $strDescription -Confirm:$false }
$VirtualMachinesDetails | %{ Start-VM -VM $_.Name -Confirm:$false }
