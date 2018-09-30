Function PromptField($Question)
{
	
	Write-Host "Type Q for (Q)uit"
	$Variable=Read-Host -Prompt $Question
	if ($Variable.ToUpper() -eq "Q")
	{
		ExitApp
	}
	if ($Variable -eq "")
	{
		Write-Host "Field required"
		PromptField($Question)
	}
	else
	{
		cls
		Return $Variable
	}
}
Function GetVMClient
{
	$global:VMClient=PromptField("Please enter VMWare Client Server Name[FQDN]")
	$FindChar=$VMClient.IndexOf(".")
	if ($FindChar -eq -1)
	{
		Write-Host "Please enter a FQDN please"
		GetVMClient
	}
	if(!(Test-Connection -Cn $VMClient -BufferSize 16 -Count 1 -ea 0 -quiet))
	{	
		Write-Warning "Cannot Reach Server $VMClient"
		GetVMClient
	}
	Return $VMClient
}
Function ConnectVC()
{
	$global:VMClient=GetVMClient
	GetVCCreds
	Connect-VIserver -Server $VMClient -Credential $Creds
}
Function GetVCCreds
{
	$global:Creds=get-credential
}
Function GetGuestCreds
{
	$global:GuestCreds=get-credential
}
ConnectVC
GetGuestCreds
Remove-Item access.txt -ErrorAction SilentlyContinue
Remove-Item noaccess.txt -ErrorAction SilentlyContinue
Remove-Item groups.txt -ErrorAction SilentlyContinue
Remove-Item allgroups.txt -ErrorAction SilentlyContinue
foreach($vm in get-vm)
{
	clear
	Write-Host "Checking vm guest: "$vm.name
	$Output=Invoke-VMScript -GuestCredential $GuestCreds -ScriptText "net localgroup Administrators" -VM $vm `
	-ErrorVariable myerror -ErrorAction SilentlyContinue
	if ($myerror.count -eq 0)
	{
		$OutString="Computer Name: "+$vm.name
		$OutString >>groups.txt
		$Output >>groups.txt
		Write-Host "Vmware Guest can be accessed with credentials...:"$vm.name
		$vm >>access.txt
	}
	else
	{
		Write-Host "Vmware Guest CANNOT BE ACCESSED with Credentials...."$vm.name
		$vm >>noaccess.txt
	}
	$myerror.clear()
}
$reader = [System.IO.File]::OpenText("temp.txt")
try {
	for(;;) {
		$line = $reader.ReadLine()
        		if ($line -eq $null) { break }
        	# process the line
        		If ($line.Contains("Computer Name:"))
			{
				$Computer=$line.SubString(15)
				$Computer=$Computer.Replace(" ","")
			}
			if ($line.Contains("Members"))
			{
				$GetGroups=$True
				$RowCount=1
			}
			if ($line.Contains("The command"))
			{
				$GetGroups=$False
			}
			if ($GetGroups)
			{
				$RowCount=$RowCount+1
				if($RowCount -ge 6)
				{
					$Output=$Computer+","+$line.SubString(3) >>allgroups.txt
				}
			}	
    		}
	}
finally {
	$reader.Close()
}
Disconnect-ViServer
