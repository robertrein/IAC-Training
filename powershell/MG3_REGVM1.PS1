#Run 1 of 4 for each NFS datastore
connect-viserver apsep2565cls.ms.ds.uhc.com
#Add-PSSnapin vmwa*
$myhost1 = get-vmhost “vsmep1528.uhc.com”
$myfolder =  get-folder "WalthamDevnet"
dir apsep2565cls.ds.uhc.com@443\UCI023DC01\mule_vol_vm_devnet_bos_datastore01\*\*.vmx |
% {New-VM -VMFilePath $_.DatastoreFullPath -VMHost $myhost1 -Location $myfolder -RunAsync}
DISCONNECT-VISERVER