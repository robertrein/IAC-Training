#Waits for a UDP message on a particular port.
Param(
[parameter(Mandatory=$True,Position=0, HelpMessage='The host UDP port to send the message to')]
[Int]$Port,
[parameter(Mandatory=$False,Position=1, HelpMessage='If set, the function will continue listening for messages instead of exiting after the first one it receives. ')]
[switch]$Loop=$False
)
 
function Receive-UDPMessage{
[CmdletBinding(
    DefaultParameterSetName='Relevance',
    SupportsShouldProcess=$False
)]
Param(
[parameter(Mandatory=$True,Position=0, HelpMessage='The host UDP port to send the message to')]
[Int]$Port,
[parameter(Mandatory=$False,Position=1, HelpMessage='If set, the function will continue listening for messages instead of exiting after the first one it receives. ')]
[switch]$Loop=$False
)
    try {
        $endpoint = new-object System.Net.IPEndPoint ([IPAddress]::Any,$port)
        $udpclient=new-Object System.Net.Sockets.UdpClient $port
        do  {
 
            Write-Host "Waiting for message on UDP port $Port..."
            Write-Host ""
            $content=$udpclient.Receive([ref]$endpoint)        
            Write-Host "Received: $content"
            write-host "Received message: $([Text.Encoding]::ASCII.GetString($content))"
            Write-Host "Received from: $($endpoint.address.toString()):$($endpoint.Port)"
 
        } while($Loop)
    }catch [system.exception] {
        throw $error[0]
 
    } finally {
        $udpclient.Close()
    }
 
}
 
Receive-UDPMessage -Port $Port $Loop
