#Run 2 of 4 for each NFS datastore
connect-viserver apsep2565cls.ms.ds.uhc.com
#Add-PSSnapin vmwa*
$myhost2 = get-vmhost “vsmep1529.uhc.com”
$myfolder =  get-folder "WalthamDevnet"
dir apsep2565cls.ms.ds.uhc.com@443\UCI023DC01\mule_vol_vm_devnet_bos_datastore02\*\*.vmx |
% {New-VM -VMFilePath $_.DatastoreFullPath -VMHost $myhost2 -Location $myfolder -RunAsync} 
DISCONNECT-VISERVER
