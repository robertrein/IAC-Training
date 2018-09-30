param(
	[Parameter(Mandatory=$True)]
	[String]$FileName
)
#
# SCRIPT DESCRIPTION SECTION
#
#AUTHOR: ROBERT REIN
#DATE: 4/9/2014
#DESCRIPTION:  FUNCTION TO INPUT A COLUMNIZED AND TITLED CSV FILE AND RETURN
#VARIABLE ARRAY
#


#
# FUNCTIONS
#
Function ReadFile
{
	$InputList=import-csv $Filename
	Return $InputList

}

ReadFile