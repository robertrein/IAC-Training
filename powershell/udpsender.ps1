#Sends a message to a host on a particular port.
 
Param(
[parameter(Mandatory=$True,Position=0, HelpMessage='The host to send the message to')]
[String]$Hostname,
 
[parameter(Mandatory=$True,Position=1, HelpMessage='The message to send')]
[String]$Message,
 
[parameter(Mandatory=$True,Position=2, HelpMessage='The host UDP port to send the message to')]
[Int]$Port
)
 
function Send-UDPMessage{
[CmdletBinding(
    DefaultParameterSetName='Relevance',
    SupportsShouldProcess=$False
)]
Param(
[parameter(Mandatory=$True,Position=0, HelpMessage='The host to send the message to')]
[String]$Hostname,
 
[parameter(Mandatory=$True,Position=1, HelpMessage='The message to send')]
[String]$Message,
 
[parameter(Mandatory=$True,Position=2, HelpMessage='The host UDP port to send the message to')]
[Int]$Port
)
Write-Host "Message to send: $Message"
$udpclient=new-Object System.Net.Sockets.UdpClient
$b=[Text.Encoding]::ASCII.GetBytes($Message)
$bytesSent=$udpclient.Send($b,$b.length,$Hostname, $Port)
write-host "Sent: $b"
$udpclient.Close()
 
}
 
Send-UDPMessage -Hostname $Hostname -Message $Message -Port $Port
