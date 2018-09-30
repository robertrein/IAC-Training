$wshell = New-Object -ComObject wscript.shell;
#$wshell.SendKeys('~')
$IE=new-object -com internetexplorer.application
 $IE.navigate2("https://hpsm/sm/index.do")
 $IE.visible=$true

Sleep 5

$wshell.SendKeys("000781906{tab}Wildey13579{Enter}")