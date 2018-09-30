ForEach ($Cluster in Get-Cluster)
    {
        ForEach ($vmhost in ($cluster | Get-VMHost))
        {
            $VMView = $VMhost | Get-View
	    $out=$VMhost.Name + "," + $Cluster.Name
            $out
        }
    }
