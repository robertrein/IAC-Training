connect-viserver apsep2565cls.ms.ds.uhc.com
$chaskadatastore4 = Get-Datastore uci023dc01_vmsan017
foreach ($myvm in (Get-Datastore mule_vol_vm_devnet_bos_datastore04  | Get-VM)) {Move-VM -VM $myvm -Datastore $chaskadatastore4}
disconnect-viserver