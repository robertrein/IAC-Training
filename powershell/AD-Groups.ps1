################################################################################################################################
################################################################################################################################
#### Script by George Giani                                                                                                 ####
#### April 2014                                                                                                             ####
####                                                                                                                        ####
#### IMPORTANT:  Run this command prior to executring this script:  'Set-ExecutionPolicy RemoteSsigned'.                    ####
#### Set-ExecutionPolicy only needs to be run one time on the machine on which the script will run.                         ####
#### Adds Global Groups to Active Directory domain: %computername%-Admins/Users/Powerusers'                                 ####
#### Run this script on any domain controller'                                                                              ####
################################################################################################################################
################################################################################################################################

Import-Module activedirectory

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic') | Out-Null

$computername = [Microsoft.VisualBasic.Interaction]::InputBox("What computer are these groups for?" , "Computer Name")
$output = [System.Windows.Forms.MessageBox]::Show("Domain Global groups will be created in $env:USERDNSDOMAIN as follows: `
`r`n$computername-Admins `
$computername-Powerusers `
$computername-Users `
`r`nAre you ready to proceed?" , "Confirmation" , 4)

if ($output -eq "NO")
{
    [System.Windows.Forms.MessageBox]::Show("OK. Run this script later when you are ready. Exiting now..." , "Confirmation" , 0)
    Exit
}
    else
{
    #### get domain distinguished name ####
    $Root = [ADSI]"LDAP://RootDSE"
    $domain = $Root.Get("rootDomainNamingContext")    #DN will be used - appended into command to create groups
    #######################################
    #Write-Host "Domain is " $domain    #debugging
    [System.Windows.Forms.MessageBox]::Show("OK, Let's continue..." , "Continue" , 0)
    [System.Windows.Forms.MessageBox]::Show("You'll now be asked for OU names into which to put the groups. `
    `r`nCheck 'Active Directory Users and Computers' for the correct OU names. `
    `r`nNote: OU Names are not case-sensitive." , "Notice" , 0)
    $ou1 = [Microsoft.VisualBasic.Interaction]::InputBox("What is the OU (usually Groups)?" , "OU Name")
    $ou2 = [Microsoft.VisualBasic.Interaction]::InputBox("What is the child OU (usually 'Server Access')?" , "Child OU Name")
    new-adgroup -Name "$computername-Admins" -GroupCategory Security -GroupScope Global -path "ou=$ou2,ou=$ou1,$domain"
    new-adgroup -Name "$computername-Powerusers" -GroupCategory Security -GroupScope Global -path "ou=$ou2,ou=$ou1,$domain"
    new-adgroup -Name "$computername-Users" -GroupCategory Security -GroupScope Global -path "ou=$ou2,ou=$ou1,$domain"
}