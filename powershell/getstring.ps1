Param(
	[string]$pathInput,
    	[string]$searchString
)


if ( $pathInput -eq "" ) {
	Write-Host "Path not provided"
	exit
}
foreach($path in $pathInput){
	echo $path
	$files=Get-ChildItem -name $path
	foreach($file in $files)
	{
		$outString="Filename: " + $file
		write-host -foregroundcolor "red" $outString
		write-host -foregroundcolor "blue" "================================"
		get-content $file | select-string -pattern $searchString
		write-host -foregroundcolor "blue" "================================"

	}

}