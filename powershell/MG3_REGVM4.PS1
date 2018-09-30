#Run 2 of 4 for each NFS datastore
connect-viserver apsep2565cls.ms.ds.uhc.com
#Add-PSSnapin vmwa*
$myhost4 = get-vmhost “vsmep1531.uhc.com”
$myfolder =  get-folder "WalthamDevnet"
dir apsep2565cls@443\uci023dc01\mule_vol_vm_devnet_bos_datastore04\*\*.vmx |
% {New-VM -VMFilePath $_.DatastoreFullPath -VMHost $myhost4 -Location $myfolder -RunAsync}
disconnect-viserver