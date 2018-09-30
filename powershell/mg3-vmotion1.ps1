connect-viserver apsep2565cls.ms.ds.uhc.com
$chaskadatastore1 = Get-Datastore uci023dc01_vmsan019
foreach ($myvm in (Get-Datastore mule_vol_vm_devnet_bos_datastore01  | Get-VM)) {Move-VM -VM $myvm -Datastore $chaskadatastore1}
disconnect-viserver