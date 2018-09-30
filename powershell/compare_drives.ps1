Param(
	[string]$Path1,
	[string]$Path2
)

$folderReference = $Path1
$folderDifference = $Path2

$FolderReferenceContents = Get-ChildItem $folderReference -Recurse | 
    where-object {-not $_.PSIsContainer}
$ReferenceCount=get-childitem $folderReference -Recurse | Measure-Object
$FolderDifferenceContents = Get-ChildItem $folderDifference -Recurse | 
    where-object {-not $_.PSIsContainer}
$DifferenceCount=get-childitem $folderDifference -Recurse | Measure-Object
$Diff=$null
#get only files that are on laptop not on server
$Diff=Compare-Object -ReferenceObject $FolderReferenceContents `
-DifferenceObject $FolderDifferenceContents -Property ('Name', 'Length') -PassThru |
    where-object { $_.SideIndicator -eq '=>'} | 
        select FullName

if ($Diff -eq $NULL)
{
	$OutString="No missing or different sized files found on PATH: " + $folderDifference + `
	" Compared to PATH: " + $FolderReference
	$OutString
	$OutString="Total Files on PATH: "+$folderDifference + " is: "+$DifferenceCount.count
	$OutString
	$OutString="Total Files on PATH: "+$folderReference + " is: "+$ReferenceCount.count
	$OutString
}
else
{
	$OutString="Files found on path: "+$folderDifference+" but not on path: "+$folderReference
	$OutString
	$Diff
}
