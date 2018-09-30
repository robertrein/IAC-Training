connect-viserver apsep2565cls.ms.ds.uhc.com
$chaskadatastore2 = Get-Datastore uci023dc01_vmsan025
foreach ($myvm in (Get-Datastore mule_vol_vm_devnet_bos_datastore02  | Get-VM)) {Move-VM -VM $myvm -Datastore $chaskadatastore2}
disconnect-viserver