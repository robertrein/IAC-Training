$RECS=Get-Content .\mailinfo.txt
foreach($REC in $RECS)
{
	$FIELDS = $REC -SPLIT '	'
	$EMAIL=$FIELDS[0]
	$FIRSTNAME=$FIELDS[1]
	$SECUREID=$FIELDS[2]
	$USERNAME=$FIELDS[3]
	$CRLF=[convert]::ToChar(13)
	Send-MailMessage -To $EMAIL -Subject "Access to HPOO" -Body "Dear $FIRSTNAME $CRLF $CRLF I submitted a secure request number $SECUREID for your MSID username $USERNAME for access to HPOO Central for ESD report execution. $CRLF Instructions will be forthcoming on how to run HPOO Engineering reports. $CRLF Initially for running the TEST OF PORTS report for firewall testing. $CRLF $CRLF If you have any questions please feel free to ask. $CRLF $CRLF $CRLF $CRLF Robert Rein" `
	  -From robert.rein@optum.com -SmtpServer mailo2.uhc.com
	WRITE-HOST "EMAIL SENT TO "$EMAIL
	SLEEP 60
}