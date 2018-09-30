$Domain=Read-Host -Prompt "Please enter Domain Name"
$computer=Read-Host -Prompt "Please enter computer name"
$ADPath=Read-Host -Prompt "Please enter AD Path to add group to"
$cmd1="dsadd group " + "cn=" + $computer.ToUpper() + "-Admins" + "," + $ADPath + " -secgrp Yes -scope u"
$cmd2="dsadd group " + "cn=" + $computer.ToUpper() + "-Powerusers" + "," + $ADPath + " -secgrp Yes -scope u"
$cmd3="dsadd group " + "cn=" + $computer.ToUpper() + "-Users" + "," + $ADPath + " -secgrp Yes -scope u"
echo $cmd1 >bladgroupcmd.txt
echo $cmd2 >>bladgroupcmd.txt
echo $cmd3 >>bladgroupcmd.txt
type bladgroupcmd.txt | clip.exe
Write-Host "Command copied to clipboard for Adding Groups to AD Server"
$Dummy=Read-Host -Prompt "Press Enter for local computer commands"
#$de = [ADSI]"WinNT://bosp7iprsql05/Power Users,group"
#$de.psbase.Invoke("Add",([ADSI]"WinNT://asp.local/bosp7iprsql05-powerusers").path)
$cmd1="$" + "de = [ADSI]" + """" + "WinNT://"+ $Computer + "/Administrators,group" + """"
$cmd2="$" + "de.psbase.Invoke(" + """" + "Add" + """" +",([ADSI]" + """" + "WinNT://" + $Domain + "/" + $Computer + "-Admins" + """" + ").path)"

$cmd3="$" + "de.psbase.Invoke(" + """" + "Add" + """" +",([ADSI]" + """" + "WinNT://" + $Domain + "/" + "Server-Admin" + """" + ").path)"

$cmd4="$" + "de = [ADSI]" + """" + "WinNT://"+ $Computer + "/Power Users,group" + """"
$cmd5="$" + "de.psbase.Invoke(" + """" + "Add" + """" +",([ADSI]" + """" + "WinNT://" + $Domain + "/" + $Computer + "-Powerusers" + """" + ").path)"
$cmd6="$" + "de = [ADSI]" + """" + "WinNT://"+ $Computer + "/Users,group" + """"
$cmd7="$" + "de.psbase.Invoke(" + """" + "Add" + """" +",([ADSI]" + """" + "WinNT://" + $Domain + "/" + $Computer + "-Users" + """" + ").path)"
echo $cmd1 >bladgroupcmd.txt
echo $cmd2 >>bladgroupcmd.txt
echo $cmd3 >>bladgroupcmd.txt
echo $cmd4 >>bladgroupcmd.txt
echo $cmd5 >>bladgroupcmd.txt
echo $cmd6 >>bladgroupcmd.txt
echo $cmd7 >>bladgroupcmd.txt
type bladgroupcmd.txt | clip.exe
Write-Host "Commands copied to clipboard for local computer"