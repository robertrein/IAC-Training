$List=Get-WmiObject -class Win32_volume -filter "drivetype = 3" | select @{Name="Capacity";Expression={$_.capacity / 1GB}}
foreach($line in $List)
{
	$line.ToString.Value
}