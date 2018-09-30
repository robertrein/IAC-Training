$myexportpath = "C:\bob\"
$mydclist = Get-DataCenter #-Name 'West Valley'
$myoutput = @()

foreach ($mydc in $mydclist)
{
       $myclusters = Get-Cluster -location $mydc
       foreach ($mycls in $myclusters)
       {
              $myvms  = $mycls | Get-VM
                     
              foreach ($myvm in $myvms) {
            $output = "" | Select Datacenter, Cluster, VM, Network
            $output.Datacenter = $mydc.Name
            $output.Cluster = $mycls.Name
            $output.VM = $myvm.Name
            $output.Network = $myvm.NetworkAdapters.Networkname | select -first 1

            $myoutput += $output
              }             
       }
}

$myoutput | export-csv $myexportpath"AllVMs.csv" 


