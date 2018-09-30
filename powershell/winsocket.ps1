
$ToServer=Read-Host -Prompt "Please provide Destination Server or IP"
$Port=Read-Host -Promp "Please provide PORT to test"
$error.clear()

$socket=new-object System.Net.Sockets.TcpClient("$ToServer",$Port) -EA SilentlyContinue
$socket.Connected

$error[0]