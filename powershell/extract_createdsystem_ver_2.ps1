# -----------------------------------------------------------------------------
# Script: extract_createdsystem.ps1
# -----------------------------------------------------------------------------

<#

.SYNOPSIS
This PowerShell script can be used to extract the information of the servers created using service catalog

.DESCRIPTION
This PowerShell script will parse the outlook folder specified(inbox by default) for the mails recieved by the service catlog for the s pecified filters and then would display the records on screen
as well as generate a csv output file

.EXAMPLE
./extract_createdsystem.ps1 -folder <outlook folder under inbox> -requestid <service catalog request id> -createdon <date for which data is to be retrieved>

.NOTES
#Use only one of the options from -requestid, -createdon, -createdbefore, -createdafter
#-folder can be used in combination with any of the above

.CONTACT
raj_shekhar1@optum.com

#>

# input parameters
Param(

#RequestID
  [Parameter(Mandatory=$False)]
   [string]$requestid,
#request completion date
   [Parameter(Mandatory=$false)]
   [string]$createdon,
#request completed efore specified date
   [Parameter(Mandatory=$false)]
   [string]$createdbefore,
#request completed after specified date
   [Parameter(Mandatory=$false)]
   [string]$createdafter,
#outlook folder to be searched 
   [Parameter(Mandatory=$false)]
   [string]$folder
)

# function to retrieve the outlook contents
Function Get-OutlookInBox
{
 Add-type -assembly "Microsoft.Office.Interop.Outlook" | out-null
 $olFolders = "Microsoft.Office.Interop.Outlook.olDefaultFolders" -as [type]
 $outlook = new-object -comobject outlook.application
 $namespace = $outlook.GetNameSpace("MAPI")
 $folder1 = $namespace.getDefaultFolder($olFolders::olFolderInBox)
 if($folder){
 $targetfolder = $folder1.Folders | where-object { $_.name -eq "$folder" }
 $targetfolder.items | #where-object { $_.body -match "keyword" } | % { $_.body }
 Select-Object -Property Subject, ReceivedTime, Importance, SenderName, Body}
 else{
 $folder1.items |
 Select-Object -Property Subject, ReceivedTime, Importance, SenderName, Body}
} #end function Get-OutlookInbox

#filtering data based on request id
if($requestid){
$requiredtext = Get-OutlookInbox | Where-Object { $_.SenderName -match ‘ESC_Mailer@uhc.com’} | Where-Object { $_.Subject -match "System response for request # $requestid" } | Where-Object { $_.Body -match "name" } | Where-Object { $_.Body -match "ip"}
$result_text = $requiredtext | select-string -Pattern '(\wame:[ ]\w{5}\d{4})|(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)|([# ]\b\d\d\d\d\d\d[-]\d\d\d\d\d\d\d\b)|([: ](\d|\d\d)\/(\d|\d\d)\/(\d\d\d\d))' -AllMatches | % { $_.Matches } | % { $_.Value }
}
#filtering data based on date
elseif($createdon){
try{
$newdate=[datetime]"$createdon"
$newdate=$newdate.AddDays(1)
$requiredtext = Get-OutlookInbox | where { $_.ReceivedTime -gt [datetime]$createdon -AND $_.ReceivedTime -lt [datetime]$newdate } | Where-Object { $_.SenderName -match ‘ESC_Mailer@uhc.com’} | Where-Object { $_.Subject -match "System response for request #" } | Where-Object { $_.Body -match "name" } | Where-Object { $_.Body -match "ip"}
$result_text = $requiredtext | select-string -Pattern '(\wame:[ ]\w{5}\d{4})|(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)|([# ]\b\d\d\d\d\d\d[-]\d\d\d\d\d\d\d\b)|([: ](\d|\d\d)\/(\d|\d\d)\/(\d\d\d\d))' -AllMatches | % { $_.Matches } | % { $_.Value }
Write-Host "INFO::Date selected command line is request completion date and date displayed below would be request creation date" -BackgroundColor DarkYellow
}
catch{
Write-Host "Incorrect date format" -ForegroundColor Red
break
}
}
elseif($createdbefore){
try{
$newdate=[datetime]"$createdbefore"
$requiredtext = Get-OutlookInbox | where { $_.ReceivedTime -lt [datetime]$newdate } | Where-Object { $_.SenderName -match ‘ESC_Mailer@uhc.com’} | Where-Object { $_.Subject -match "System response for request #" } | Where-Object { $_.Body -match "name" } | Where-Object { $_.Body -match "ip"}
$result_text = $requiredtext | select-string -Pattern '(\wame:[ ]\w{5}\d{4})|(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)|([# ]\b\d\d\d\d\d\d[-]\d\d\d\d\d\d\d\b)|([: ](\d|\d\d)\/(\d|\d\d)\/(\d\d\d\d))' -AllMatches | % { $_.Matches } | % { $_.Value }
Write-Host "INFO::Date selected in command line is request completion date and date displayed below would be request creation date" -BackgroundColor DarkYellow
}
catch{
Write-Host "Incorrect date format" -ForegroundColor Red
break
}}
elseif($createdafter){
try{
$newdate=[datetime]"$createdafter"
$requiredtext = Get-OutlookInbox | where { $_.ReceivedTime -gt [datetime]$newdate } | Where-Object { $_.SenderName -match ‘ESC_Mailer@uhc.com’} | Where-Object { $_.Subject -match "System response for request #" } | Where-Object { $_.Body -match "name" } | Where-Object { $_.Body -match "ip"}
$result_text = $requiredtext | select-string -Pattern '(\wame:[ ]\w{5}\d{4})|(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)|([# ]\b\d\d\d\d\d\d[-]\d\d\d\d\d\d\d\b)|([: ](\d|\d\d)\/(\d|\d\d)\/(\d\d\d\d))' -AllMatches | % { $_.Matches } | % { $_.Value }
Write-Host "INFO::Date selected command line is request completion date and date displayed below would be request creation date" -BackgroundColor DarkYellow
}
catch{
Write-Host "Incorrect date format" -ForegroundColor Red
break
}}
#if no filter is requested then display all the requested servers
else{
$requiredtext = Get-OutlookInbox | Where-Object { $_.SenderName -match ‘ESC_Mailer@uhc.com’} | Where-Object { $_.Subject -match "System response for request #" } | Where-Object { $_.Body -match "name" } | Where-Object { $_.Body -match "ip"}
$result_text = $requiredtext | select-string -Pattern '(\wame:[ ]\w{5}\d{4})|(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b)|([# ]\b\d\d\d\d\d\d[-]\d\d\d\d\d\d\d\b)|([: ](\d|\d\d)\/(\d|\d\d)\/(\d\d\d\d))' -AllMatches | % { $_.Matches } | % { $_.Value }
}#filtering completed

# formatting the data to be displayed
try{
$array = $result_text.Replace('N','n')
}
catch{
Write-host "No records found"
exit
}
$array = $array.Replace(" ","")
$array = $array.Replace("# ","")
$array = $array.Replace(": ","")
$array = $array.Replace(":","")
$array = $array -split("name")
$array = $array | ? {$_}  
#formatting ends here

#function to write the csv
Function write-op-csv{
$counter=0
for ($i=0; $i -lt $array.Length; $i++){
  
    $i=$i+3
  
  $counter=$counter+1
  }
$resultsarray =@()
$index=0
 while ($counter -gt 0){
 $valueObject = new-object PSObject
 $valueObject | add-member -membertype NoteProperty -name "ServerName" -Value $array[$index+2]
 $valueObject | add-member -membertype NoteProperty -name "IP" -Value $array[$index+3]
 $valueObject | add-member -membertype NoteProperty -name "RequestId" -Value $array[$index] 
 $valueObject | add-member -membertype NoteProperty -name "RequestDate" -Value $array[$index+1]
 $index=$index+4
 $counter=$counter-1
 $resultsarray += $valueObject 
 }
 $filenm=[environment]::getfolderpath(“mydocuments”) + "\sed_automation\ps_output"+"\ServerDetail_$(get-date -f MM-dd-yyyy-HH-mm-ss)"
 New-Item -ItemType File -Force -Path $filenm".csv"
 $resultsarray| Export-csv $filenm".csv" -notypeinformation
 }#function ends here


#  Print Results

Write-Host "ServerName             IP           RequestID            RequestDate"
Write-Host "--------------------------------------------------------------------"

  for ($i=0; $i -lt $array.Length; $i++){
  #Write-Host -NoNewline $array[$i] "`t" $array[$($i+1)] "`t`t"$array[$($i+2)]"`t"$array[$($i+3)]
  Write-Host -NoNewline $array[$($i+2)] "`t" $array[$($i+3)] "`t"$array[$i]"`t"$array[$($i+1)]
    $i=$i+3
  Write-Host "`n"
  }

#write to csv
write-op-csv