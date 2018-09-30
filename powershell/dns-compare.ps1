#Description: Reads a file, with a server and IP on each line.  Doaes a DNS lookup on the server and 
#             determines if the IP is correct.
#Output file: dns-fail.txt - comma delimited file with output showing servers that do not match their IP, with the IP from the file 
#             followed by the IP from the host
#
$file = Get-Content dns-compare.txt
del dns-fail.txt
Foreach ($line in $file)
    {
    $info = $line.split(",")
    $server = $info[0]
    $file_ip = $info[1]

    $host_ip = [System.Net.Dns]::GetHostAddresses($server)
    IF ($host_ip -ne $file_ip)
        {
        Write-Host "DNS failed for $server"
        $strOut = $server + ',' + $file_ip + ',' + $host_ip
        $strOut >>dns-fail.txt
        }
    ELSE
        {
        Write-Host "DNS successful for $server"
        }
    }