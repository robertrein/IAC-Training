Function ConnectToVCServer {
    $VCenter=Read-Host "Please Enter VCENTER IP or Hostame:"
    if ($VCenter -eq "")
    {
        Exit
    }

    Write-Host "Connecting to VCENTER Server "$VCenter
    Write-Host "Get the vCenter server credentials"
    $vcCred = Get-Credential
    Connect-VIServer -Server $VCenter -Credential $vcCred -Protocol https
}

$VMs = Get-Content vm-shutdown.txt
$VMn = Get-Content vm-exclude.txt

ConnectToVCServer

Foreach ($VM in $VMs)
    {
	IF ($VMn -contains $VM)
            {
            Write-Host "$VM excluded from being shutdown"
            }
        ELSE
	    {
            Write-Host "$VM being shut down"
            Shutdown-VMGuest -VM $VM -Confirm:$false
            }

    trap {$_.Exception.Message | Out-File -FilePath ./downerror.txt -Append; continue}
        $Error[0].Exception.Message | Out-File -FilePath ./downerror.txt -Append  
    }
