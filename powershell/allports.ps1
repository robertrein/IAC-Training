$myexportpath = "C:\bob\"
$mydclist = Get-DataCenter
$myoutput = @()

foreach ($mydc in $mydclist)
{
       $myclusters = Get-Cluster -location $mydc
       foreach ($mycls in $myclusters)
       {
            $myhost = $mycls | Get-VMHost | select -First 1
            $myhost  
            $myPortGroup = $myhost | Get-VirtualPortGroup | where {($_.Name -notlike "*Management*") -and 
            ($_.Name -notlike "*NFS*") -and ($_.Name -notlike "*vMotion*") -and 
            ($_.Name -notlike "*kernel*") -and ($_.Name -notlike "*n1kv*") -and
            ($_.Name -notlike "*NAS*") -and ($_.Name -notlike "*unused*") -and
            ($_.Name -notlike "*service console*") -and ($_.Name -notlike "*disconnected*") -and
            ($_.Name -notlike "*heartbeat*")
        }
                     
              foreach ($mypg in $myPortGroup) {
            $myport = $_
            $output = "" | Select Datacenter, Cluster, PortGroup, VLanID
            $output.Datacenter = $mydc.Name
            $output.Cluster = $mycls.Name
            $output.PortGroup = $mypg.Name
            $output.VLanID = $mypg.VLanID

            $myoutput += $output
            }        
       }
}

$myoutput | export-csv $myexportpath"Allports.csv" 


