ForEach ($Cluster in Get-Cluster)
{
	ForEach($ESXServer in ($Cluster | get-vmhost))
	{
		echo $Cluster $ESXServer
	}
}