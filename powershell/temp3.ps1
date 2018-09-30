# WMI Win32_NTLogEvent PowerShell script
Clear-Host
$Logs = Get-WmiObject -class Win32_NTLogEvent `
 -filter "(logfile='Application') AND (type='error')" 
$Logs | Format-Table EventCode, EventType, Message -auto