$Server="webed0880"


 $job = gwmi win32_computersystem -ComputerName $server -AsJob | Wait-Job -Timeout 30
 if ($job.State -ne 'Completed') {
     Write-Host "'$server' timed out after 30 seconds."
     return
 }
 $results = $job | Receive-Job | select numberofprocessors,domain,manufacturer,model,totalphysicalmemory
$results