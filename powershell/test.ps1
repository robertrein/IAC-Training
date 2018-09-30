$global:XPath="C:\Users\rrein\Documents"
if (Test-Path($XPath + "\cluster.xls"))
{
	echo worked
}