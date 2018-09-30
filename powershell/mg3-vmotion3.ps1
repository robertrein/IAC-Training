connect-viserver apsep2565cls.ms.ds.uhc.com
$chaskadatastore3 = Get-Datastore uci023dc01_vmsan007
foreach ($myvm in (Get-Datastore mule_vol_vm_devnet_bos_datastore03  | Get-VM)) {Move-VM -VM $myvm -Datastore $chaskadatastore3}
disconnect-viserver