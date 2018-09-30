connect-viserver apsep2565cls.ms.ds.uhc.com
$myfolder = get-folder "WalthamDevnet"
$myvm = get-folder $myfolder | get-vm 
Get-VM $myvm| Get-NetworkAdapter | Set-NetworkAdapter -NetworkName  "presentation_vlan_12" -confirm:$false
disconnect-viserver