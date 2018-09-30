# Version: 1.0.3

param([string]$exe, [Parameter(Mandatory = $false)][string]$userInput, [Parameter(Mandatory = $false)][string]$projInput, [Parameter(Mandatory = $false)][string]$folderPath, [Parameter(Mandatory = $false)][string]$buildfile, [Parameter(Mandatory = $false)][string]$bsettings, [Parameter(Mandatory = $false)][string]$bquant)

# Build new user file via CLI interaction, output is msid.json, flag to call via command line: ms
function MSIDconfig {
"Creating new user file: "

$msid = Read-Host 'Recipient MS ID (Required)'
while ($msid -notmatch "^[a-zA-Z0-9]+$") {
  "**Please enter a valid MSID**"
  $msid = Read-Host 'Recipient MS ID'
}

$email = Read-Host 'Recipient Email Address (Required)'
while ($email -notmatch "^\w+(.|_)\w+@(optum|uhc).com$") {
  "**Please enter a valid email address**"
  $email = Read-Host 'Recipient Email Address'
}

$group = Read-Host 'Service Recipient Group (Required)'
while ($group -notmatch "^[a-zA-Z0-9 _]+$") {
  "**Please enter a valid Service Recipient Group**"
  $group = Read-Host 'Service Recipient Group'
}

$bunit = Read-Host 'GL Business Unit (Required)'
while ($bunit -notmatch "^\d{5}$") {
  "**Please enter a valid GL Business Unit**"
  $bunit = Read-Host 'GL Business Unit'
}

$ounit = Read-Host 'GL Operating Unit (Required)'
while ($ounit -notmatch "^\d{5}$") {
  "**Please enter a valid GL Operating Unit**"
  $ounit = Read-Host 'GL Operating Unit'
}

$loc = Read-Host 'GL Location (Required)'
while ($loc -notmatch "^[A-Z0-9]{8}$") {
  "**Please enter a valid GL Location**"
  $loc = Read-Host 'GL Location'
}

$department = Read-Host 'GL Department (Required)'
while ($department -notmatch "^\d{6}$") {
  "**Please enter a valid GL Department**"
  $department = Read-Host 'GL Department'
}

$unixid = Read-Host 'Unix ID (Required for Linux builds only)'
while ($unixid -and ($unixid -notmatch "^[a-zA-Z0-9]+$")) {
  "**Please enter a valid Unix ID**"
  $unixid = Read-Host 'Unix ID'
}

$agroup = Read-Host 'Server Admin Group (Required)'
while (($agroup -eq "" -and $agroup -eq [String]::Empty) -or ($agroup -notmatch "^[a-zA-Z0-9 _]+$")) {
  "**Please enter a valid Server Admin Group**"
  $agroup = Read-Host 'Server Admin Group'
}

$customer = Read-Host 'GL Customer (Optional)'
while ($customer -and ($customer -notmatch "^\d{7}$")) {
  "**Please enter a valid GL Customer or 'Enter' for no value**"
  $customer = Read-Host 'GL Customer'
}

$product = Read-Host 'GL Product (Optional)'
while ($product -and ($product -notmatch "^\d{6}$")) {
  "**Please enter a valid GL Product or 'Enter' for no value**"
  $product = Read-Host 'GL Product'
}

$project = Read-Host 'GL Project (Optional)'
while ($project -and ($project -notmatch "^\d{10}$")) {
  "**Please enter a valid GL Project or 'Enter' for no value**"
  $project = Read-Host 'GL Project'
}

$account = Read-Host 'GL Account (Optional)'
while ($account -and ($account -notmatch "^\d{5}$")) {
  "**Please enter a valid GL Account or 'Enter' for no value**"
  $account = Read-Host 'GL Account'
}

$output = @"
{
    "msid": "$msid",
    "email": "$email",
    "group": "$group",
    "bunit": "$bunit",
    "ounit": "$ounit",
    "loc": "$loc",
    "department": "$department",
    "unixid": "$unixid",
    "agroup": "$agroup",
    "customer": "$customer",
    "product": "$product",
    "project": "$project",
    "account": "$account"
}
"@

$filename = $msid + '.json'

$output | Out-File $filename -Encoding utf8
}

# Build config file via CLI interaction. Input is user file, output is config.xml, flag to call via command line: i
function interactiveConfigBuild {
param([string]$jsonInput)

$prodVar = 'linuxserver_6.2full','linuxserver_7full','WindowsServer2012_full','WindowsServer2012_R2_full','l6','l7','win12'
$dcVar = 'Chaska', 'Elk River'
$zoneVar = 'Intranet', 'Internet'
$interfaceZoneVar = 'Presentation Zone','Application Zone','Tools Zone','Database Zone', ' '
$drVar = 'uCI Active','uCI Standby', ' '

$json = Get-Content -Raw -Path $jsonInput | ConvertFrom-Json

$msid = $json.msid
$email = $json.email
$group = $json.group
$bunit = $json.bunit
$ounit = $json.ounit
$loc = $json.loc
$department = $json.department
$unixid = $json.unixid
$agroup = $json.agroup
$customer = $json.customer
$product = $json.product
$project = $json.project
$account = $json.account

$prodid = Read-Host 'Product ID (Required, Default: linuxserver_7full)'
if ($prodid -eq "" -and $prodid -eq [String]::Empty) { $prodid = 'linuxserver_7full'}
while ($prodid -notin $prodVar) {
  "**Invalid Product ID. Please enter again. Must be: linuxserver_6.2full, linuxserver_7full, WindowsServer2012_full, or WindowsServer2012_R2_full**"
  $prodid = Read-Host 'Product ID (Required, Default: linuxserver_7full)'
  if ($prodid -eq "" -and $prodid -eq [String]::Empty) { $prodid = 'linuxserver_7full'}
}
if ($prodid -eq "l6") { $prodid = 'linuxserver_6.2full'}
if ($prodid -eq "l7") { $prodid = 'linuxserver_7full'}
if ($prodid -eq "win12") { $prodid = 'WindowsServer2012_full'}

$sname = Read-Host 'Service Name/Desciption (Required, Default: test123)'
if ($sname -eq "" -and $sname -eq [String]::Empty) { $sname = 'test123'}
while ($sname -eq "" -and $sname -eq [String]::Empty) {
  "**Please enter a Service Name or Description**"
  $sname = Read-Host 'Service Name (test123)'
  if ($sname -eq "" -and $sname -eq [String]::Empty) { $sname = 'test123'}
}

$projnum = Read-Host 'Project/ESC Number (Optional)'
if ($projnum -eq "" -and $projnum -eq [String]::Empty) { $projnum = ''}

$cpu = Read-Host 'CPU (Required, Default: 2)'
if ($cpu -eq "" -and $cpu -eq [String]::Empty) { $cpu = '2'}
while ($cpu -lt 1 -or $cpu -gt 8) {
  "**Invalid num of CPU. Must be between 1 and 8.**"
  $cpu = Read-Host 'CPU'
  if ($cpu -eq "" -and $cpu -eq [String]::Empty) { $cpu = '2'}
}

$ram = Read-Host 'RAM (Required, Default: 4)'
if ($ram -eq "" -and $ram -eq [String]::Empty) { $ram = '4'}
$numRAM = [INT]$ram
while ($numRAM -lt 1 -and $numRAM -gt 64) {
  "**Invalid num of RAM. Must be between 1 and 64.**"
  $ram = Read-Host 'RAM'
  $numRAM = [INT]$ram
  if ($ram -eq "" -or $ram -eq [String]::Empty) { $ram = '4'}
}

$env = Read-Host 'Environment (Required, Default: DEV)'
if ($env -eq "" -and $env -eq [String]::Empty) { $env = 'DEV'}
while ($env -notin @("DEV", "TEST", "STAGE", "PROD")) {
  "**Invalid Environment, must be DEV, TEST, STAGE or PROD.**"
  $env = Read-Host 'Environment (DEV)'
  if ($env -eq "" -and $env -eq [String]::Empty) { $env = 'DEV'}
}

#$platform = Read-Host 'Infrastructure Platform'
#if ($platform -eq "" -and $platform -eq [String]::Empty) { $platform = 'uCI'}

$platform = 'uCI'

$zone = Read-Host 'Network Zone (Required, Default: Intranet)'
if ($zone -eq "" -and $zone -eq [String]::Empty) { $zone = 'Intranet'}
while ($zone -notin @("Intranet", "Internet")) {
  "**Invalid Zone, must be Intranet or Internet.**"
  $zone = Read-Host 'Network Zone (Intranet)'
  if ($zone -eq "" -and $zone -eq [String]::Empty) { $zone = 'Intranet'}
}

$dcenter = Read-Host 'Data Center (Required, Default: Chaska)'
if ($dcenter -eq "" -and $dcenter -eq [String]::Empty) { $dcenter = 'Chaska'}
while ($dcenter -notin $dcVar) {
  "**Invalid Data Center. Must be Chaska or Elk River.**"
  $dcenter = Read-Host 'Data Center'
  if ($dcenter -eq "" -and $dcenter -eq [String]::Empty) { $dcenter = 'Chaska'}
}

$serverType = Read-Host 'Server Type (Required, Default: APP)'
if ($serverType -eq "" -and $serverType -eq [String]::Empty) { $serverType = 'APP'}
while ($serverType -notin @("APP", "DB", "WEB")) {
  "**Please enter a valid Server Type (WEB, APP, or DB)**"
  $serverType = Read-Host 'Server Type (APP)'
  if ($serverType -eq "" -and $serverType -eq [String]::Empty) { $serverType = 'APP'}
}

$tmdb = Read-Host 'TMDB Code (Optional)'
# Must add input validation here

$interfaceZone = Read-Host 'Interface Zone (Required if Network Zone is Internet, blank if Intranet)'
if ($interfaceZone -eq "" -and $interfaceZone -eq [String]::Empty) { $interfaceZone = ' '}
while ($interfaceZone -notin $interfaceZoneVar) {
  "**Invalid Interface Zone. Must be Presentation Zone, Application Zone, Tools Zone, Database Zone, or blank.**"
  $interfaceZone = Read-Host 'Interface Zone'
  if ($interfaceZone -eq "" -and $interfaceZone -eq [String]::Empty) { $interfaceZone = ' '}
}

$dr = Read-Host 'Disaster Recovery (Optional: uCI Active, uCI Standby, or blank)'
if ($dr -eq "" -and $dr -eq [String]::Empty) { $dr = ' '}
while ($dr -notin $drVar) {
  "**Invalid Disaster Recovery value. Must be uCI Active, uCI Standby, or blank.**"
  $dr = Read-Host 'Disaster Recovery (Optional: uCI Active, uCI Standby, or blank)'
  if ($dr -eq "" -and $dr -eq [String]::Empty) { $dr = ' '}
}

$filename = Read-Host 'Please enter file name to save to (config)'
if ($filename -eq "" -and $filename -eq [String]::Empty) { $filename = 'config' }
$filename = $filename + '.xml'

$config = @"
<form_elements><form_element>
<display_name>Recipient MS ID</display_name>
<user_value>$msid</user_value>
</form_element><form_element>
<display_name>Recipient Email Address</display_name>
<user_value>$email</user_value>
</form_element><form_element>
<display_name>Service Recipient Group</display_name>
<user_value>$group</user_value>
</form_element><form_element>
<display_name>Product ID</display_name>
<user_value>$prodid</user_value>
</form_element><form_element>
<display_name>Service Name</display_name>
<user_value>$sname</user_value>
</form_element><form_element>
<display_name>GL Business Unit</display_name>
<user_value>$bunit</user_value>
</form_element><form_element>
<display_name>GL_Operating_Unit</display_name>
<user_value>$ounit</user_value>
</form_element><form_element>
<display_name>GL Location</display_name>
<user_value>$loc</user_value>
</form_element><form_element>
<display_name>GL Department</display_name>
<user_value>$department</user_value>
</form_element><form_element>
<display_name>CPU</display_name>
<user_value>$cpu</user_value>
</form_element><form_element>
<display_name>RAM</display_name>
<user_value>$ram</user_value>
</form_element><form_element>
<display_name>Environment</display_name>
<user_value>$env</user_value>
</form_element><form_element>
<display_name>Infrastructure Platform</display_name>
<user_value>$platform</user_value>
</form_element><form_element>
<display_name>Network Zone</display_name>
<user_value>$zone</user_value>
</form_element><form_element>
<display_name>Data_Center</display_name>
<user_value>$dcenter</user_value>
</form_element><form_element>
<display_name>Unix ID</display_name>
<user_value>$unixid</user_value>
</form_element><form_element>
<display_name>Server Admin Group</display_name>
<user_value>$agroup</user_value>
</form_element><form_element>
<display_name>Server Type</display_name>
<user_value>$serverType</user_value>
</form_element><form_element>
<display_name>TMDB Application Search Code</display_name>
<user_value>$tmdb</user_value>
</form_element><form_element>
<display_name>Interface Zone</display_name>
<user_value>$interfaceZone</user_value>
</form_element><form_element>
<display_name>Disaster Recovery</display_name>
<user_value>$dr</user_value>
</form_element><form_element>
<display_name>GL Customer</display_name>
<user_value>$customer</user_value>
</form_element><form_element>
<display_name>GL Product</display_name>
<user_value>$product</user_value>
</form_element><form_element>
<display_name>GL Project</display_name>
<user_value>$project</user_value>
</form_element><form_element>
<display_name>GL Account</display_name>
<user_value>$account</user_value>
</form_element><form_element>
<display_name>Quantity</display_name>
<user_value>$quantity</user_value>
</form_element><form_element>
<display_name>Project Number</display_name>
<user_value>$projnum</user_value>
</form_element></form_elements>
"@

$config | Out-File $filename -Encoding utf8
}

# Build proj file via CLI interaction. Input is user file, output is proj.json, flag to call via command line: pi
function interactiveProjBuild {
$buildserver = $true
$serverlist = @()

while ($buildserver) {
$prodVar = 'linuxserver_6.2full','linuxserver_7full','WindowsServer2012_full','WindowsServer2012_R2_full','l6','l7','win12', 'win12r2'
$dcVar = 'Chaska', 'Elk River'
$zoneVar = 'Intranet', 'Internet'
$interfaceZoneVar = 'Presentation Zone','Application Zone','Tools Zone','Database Zone', ' '
$drVar = 'uCI Active','uCI Standby', ' '

$captype = Read-Host 'Product ID (Required, Default: linuxserver_7full)'
if ($captype -eq "" -and $captype -eq [String]::Empty) { $captype = 'linuxserver_7full'}
while ($captype -notin $prodVar) {
  "**Invalid Product ID. Please enter again. Must be: linuxserver_6.2full, linuxserver_7full, WindowsServer2012_full, or WindowsServer2012_R2_full**"
  $captype = Read-Host 'Product ID (Required, Default: linuxserver_7full)'
  if ($captype -eq "" -and $captype -eq [String]::Empty) { $captype = 'linuxserver_7full'}
}

$sname = Read-Host 'Service Name/Desciption (Required, Default: test123)'
if ($sname -eq "" -and $sname -eq [String]::Empty) { $sname = 'test123'}
while (($sname -eq "" -and $sname -eq [String]::Empty)) {
  "**Please enter a Service Name or Description**"
  $sname = Read-Host 'Service Name/Desciption (Required, Default: test123)'
  if ($sname -eq "" -and $sname -eq [String]::Empty) { $sname = 'test123'}
}

$projnum = Read-Host 'Project/ESC Number (Optional)'
if ($projnum -eq "" -and $projnum -eq [String]::Empty) { $projnum = ''}

$cpu = Read-Host 'CPU (Required, Default: 2)'
if ($cpu -eq "" -and $cpu -eq [String]::Empty) { $cpu = '2'}
while ($cpu -lt 1 -or $cpu -gt 8) {
  "**Invalid num of CPU. Must be between 1 and 8.**"
  $cpu = Read-Host 'CPU (Required, Default: 2)'
  if ($cpu -eq "" -and $cpu -eq [String]::Empty) { $cpu = '2'}
}

$ram = Read-Host 'RAM (Required, Default: 4)'
if ($ram -eq "" -and $ram -eq [String]::Empty) { $ram = '4'}
$numRAM = [INT]$ram
while ($numRAM -lt 1 -or $numRAM -gt 64) {
  "**Invalid num of RAM. Must be between 1 and 64.**"
  $ram = Read-Host 'RAM (Required, Default: 4)'
  $numRAM = [INT]$ram
  if ($ram -eq "" -and $ram -eq [String]::Empty) { $ram = '4'}
}

$env = Read-Host 'Environment (Required, Default: DEV)'
if ($env -eq "" -and $env -eq [String]::Empty) { $env = 'DEV'}
while ($env -notin @("DEV", "TEST", "STAGE", "PROD")) {
  "**Invalid Environment, must be DEV, TEST, STAGE or PROD.**"
  $env = Read-Host 'Environment (Required, Default: DEV)'
  if ($env -eq "" -and $env -eq [String]::Empty) { $env = 'DEV'}
}

#$platform = Read-Host 'Infrastructure Platform'
#if ($platform -eq "" -and $platform -eq [String]::Empty) { $platform = 'uCI'}

$platform = 'uCI'

$zone = Read-Host 'Network Zone (Required, Default: Intranet)'
if ($zone -eq "" -and $zone -eq [String]::Empty) { $zone = 'Intranet'}
while ($zone -notin @("Intranet", "Internet")) {
  "**Invalid Zone, must be Intranet or Internet.**"
  $zone = Read-Host 'Network Zone (Required, Default: Intranet)'
  if ($zone -eq "" -and $zone -eq [String]::Empty) { $zone = 'Intranet'}
}

$dcenter = Read-Host 'Data Center (Required, Default: Chaska)'
if ($dcenter -eq "" -and $dcenter -eq [String]::Empty) { $dcenter = 'Chaska'}
while ($dcenter -notin $dcVar) {
  "**Invalid Data Center. Must be Chaska or Elk River.**"
  $dcenter = Read-Host 'Data Center (Required, Default: Chaska)'
  if ($dcenter -eq "" -and $dcenter -eq [String]::Empty) { $dcenter = 'Chaska'}
}

$serverType = Read-Host 'Server Type (Required, Default: APP)'
if ($serverType -eq "" -and $serverType -eq [String]::Empty) { $serverType = 'APP'}
while ($serverType -notin @("APP", "DB", "WEB")) {
  "**Please enter a valid Server Type (WEB, APP, or DB)**"
  $serverType = Read-Host 'Server Type (Required, Default: APP)'
  if ($serverType -eq "" -and $serverType -eq [String]::Empty) { $serverType = 'APP'}
}

$tmdb = Read-Host 'TMDB Code (Optional)'
# Must add input validation here

$interfaceZone = Read-Host 'Interface Zone (Required if Network Zone is Internet, blank if Intranet)'
if ($interfaceZone -eq "" -and $interfaceZone -eq [String]::Empty) { $interfaceZone = ' ' }
while ($interfaceZone -notin $interfaceZoneVar) {
  "**Invalid Interface Zone. Must be Presentation Zone, Application Zone, Tools Zone, Database Zone, or blank.**"
  $interfaceZone = Read-Host 'Interface Zone (Required if Network Zone is Internet, blank if Intranet)'
  if ($interfaceZone -eq "" -and $interfaceZone -eq [String]::Empty) { $interfaceZone = ' ' }
}

$dr = Read-Host 'Disaster Recovery (Optional: uCI Active, uCI Standby, or blank)'
if ($dr -eq "" -and $dr -eq [String]::Empty) { $dr = ' '}
while ($dr -notin $drVar) {
  "**Invalid Disaster Recovery value. Must be uCI Active, uCI Standby, or blank.**"
  $dr = Read-Host 'Disaster Recovery (Optional: uCI Active, uCI Standby, or blank)'
  if ($dr -eq "" -and $dr -eq [String]::Empty) { $dr = ' '}
}

$quantity = Read-Host 'Number of Servers (Required, Default: 1)'
if ($quantity -eq "" -and $quantity -eq [String]::Empty) { $quantity = '1'}
while ($quantity -lt 1 -and $quantity -gt 5) {
  "**Invalid num of CPU. Must be between 1 and 5.**"
  $quantity = Read-Host 'Number of Servers (Required, Default: 1)'
  if ($quantity -eq "" -and $quantity -eq [String]::Empty) { $quantity = '1'}
}

$serverconfig = @"
{
    "captype":"$captype",
    "sname":"$sname",
    "projnum":"$projnum",
    "cpu":"$cpu",
    "ram":"$ram",
    "environment":"$env",
    "zone":"$zone",
    "datacenter":"$dcenter",
    "serverType":"$serverType",
    "tmdb":"$tmdb",
    "interfaceZone":"$interfaceZone",
    "dr":"$dr",
    "quantity":"$quantity"
}
"@

$serverlist += $serverconfig

$buildresp = Read-Host 'Do you want to add another server to the project config file (Required, Default: n)'
if ($buildresp -eq "" -and $buildresp -eq [String]::Empty) { $buildserver = $false }
if ($buildresp -eq "n") { $buildserver = $false  }

}

$filename = Read-Host 'Please enter file name to save to (Default: project)'
if ($filename -eq "" -and $filename -eq [String]::Empty) { $filename = 'project' }
$filename = $filename + '.json'

$servstring = $serverlist -join ', '

if ($serverlist.Count -gt 1) {
$serverstring = '[' + $servstring + ']'
}
else { $serverstring = $servstring }

$config = @"
{ "SLD":
{ "uCIServers":
{ "server": $serverstring
},
"uCIdb":null
}
}
"@
$config | Out-File $filename -Encoding utf8
}

# Generate multiple configs from single project file. Flag: g, Input user.json file and proj.json file
function proj2config {
param([string]$userInput, [string]$projInput)

$json = Get-Content -Raw -Path $userInput | ConvertFrom-Json

if ($projInput.Split('.')[1] -eq "json") { $proj = Get-Content -Raw -Path $projInput | ConvertFrom-Json }
elseif ($projInput.Split('.')[1] -eq "xml") { $proj = [xml](get-content $projInput) }

$path = (Get-Location).tostring() + "\" + $userInput.Split(".")[0] + "-" + $projInput.Split(".").Split("-")[0]
if (test-path $path){ remove-item $path -force -recurse }
$newfolder = New-item -ItemType directory -Path $path -Force

$msid = $json.msid
$email = $json.email
$group = $json.group
$bunit = $json.bunit
$ounit = $json.ounit
$loc = $json.loc
$department = $json.department
$unixid = $json.unixid
$agroup = $json.agroup
$customer = $json.customer
$product = $json.product
$project = $json.project
$account = $json.account

foreach($server in $proj.SLD.uCIServers.server) {
    switch ($server.captype) {
        "Linux VM uCI" { $prodid = 'linuxserver_7full' }
        'linuxserver_6.2full'{ $prodid = 'linuxserver_6.2full' }
        'linuxserver_7full'{ $prodid = 'linuxserver_7full' }
        'WindowsServer2012_full'{ $prodid = 'WindowsServer2012_full' }
        'WindowsServer2012_R2_full' { $prodid = 'WindowsServer2012_R2_full' }
        "l6" { $prodid = 'linuxserver_6.2full' }
        "l7" { $prodid = 'linuxserver_7full' }
        "w12" { $prodid = 'WindowsServer2012_full' }
        "w12r2" { $prodid = 'WindowsServer2012_R2_full' }
    }
    $sname = $server.sname;
    if ($server.sname -eq "" -and $server.sname -eq [String]::Empty) { $sname = 'test123' }
    $cpu = ($server.cpu -as [int]).ToString();
    $ram = ($server.ram -as [int]).ToString();
    $env = $server.environment
    switch ($server.environment) {
        "Development" { $env = 'DEV' }
        "System Test" { $env = 'TEST' }
        "Staging" { $env = 'STAGE' }
        "Production" { $env = 'PROD' }
    }
    $platform = 'uCI'
    switch ($server.zone) {
        "Intranet Zone" { $zone = 'Intranet' }
        "Internet Zone" { $zone = 'Internet' }
        "Intranet" { $zone = 'Intranet' }
        "Internet" { $zone = 'Internet' }
    }
    switch ($server.datacenter) {
        "Chaska" { $dcenter = 'Chaska' }
        "ELR" { $dcenter = 'Elk River' }
        "Elk River" { $dcenter = 'Elk River' }
    }
    $serverType = $server.serverType
    $tmdb = $server.tmdb
    $interfaceZone = $server.interfaceZone
    $dr = $server.dr
    if ($server.serverType -eq "" -and $server.serverType -eq [String]::Empty) { $serverType = 'APP' }
    if ($server.tmdb -eq "" -and $server.tmdb -eq [String]::Empty) { $tmdb = ' ' }
    if ($server.interfaceZone -eq "" -and $server.interfaceZone -eq [String]::Empty) { $interfaceZone = ' ' }
    if ($server.dr -eq "" -and $server.dr -eq [String]::Empty) { $dr = ' ' }
    $quantity = ($server.quantity -as [int]).ToString();
    $projnum = $server.projnum
    if ($server.projnum -eq "" -and $server.projnum -eq [String]::Empty) { $projnum = ' ' }

    $config = @"
<form_elements><form_element>
<display_name>Recipient MS ID</display_name>
<user_value>$msid</user_value>
</form_element><form_element>
<display_name>Recipient Email Address</display_name>
<user_value>$email</user_value>
</form_element><form_element>
<display_name>Service Recipient Group</display_name>
<user_value>$group</user_value>
</form_element><form_element>
<display_name>Product ID</display_name>
<user_value>$prodid</user_value>
</form_element><form_element>
<display_name>Service Name</display_name>
<user_value>$sname</user_value>
</form_element><form_element>
<display_name>GL Business Unit</display_name>
<user_value>$bunit</user_value>
</form_element><form_element>
<display_name>GL_Operating_Unit</display_name>
<user_value>$ounit</user_value>
</form_element><form_element>
<display_name>GL Location</display_name>
<user_value>$loc</user_value>
</form_element><form_element>
<display_name>GL Department</display_name>
<user_value>$department</user_value>
</form_element><form_element>
<display_name>CPU</display_name>
<user_value>$cpu</user_value>
</form_element><form_element>
<display_name>RAM</display_name>
<user_value>$ram</user_value>
</form_element><form_element>
<display_name>Environment</display_name>
<user_value>$env</user_value>
</form_element><form_element>
<display_name>Infrastructure Platform</display_name>
<user_value>$platform</user_value>
</form_element><form_element>
<display_name>Network Zone</display_name>
<user_value>$zone</user_value>
</form_element><form_element>
<display_name>Data_Center</display_name>
<user_value>$dcenter</user_value>
</form_element><form_element>
<display_name>Unix ID</display_name>
<user_value>$unixid</user_value>
</form_element><form_element>
<display_name>Server Admin Group</display_name>
<user_value>$agroup</user_value>
</form_element><form_element>
<display_name>Server Type</display_name>
<user_value>$serverType</user_value>
</form_element><form_element>
<display_name>TMDB Application Search Code</display_name>
<user_value>$tmdb</user_value>
</form_element><form_element>
<display_name>Interface Zone</display_name>
<user_value>$interfaceZone</user_value>
</form_element><form_element>
<display_name>Disaster Recovery</display_name>
<user_value>$dr</user_value>
</form_element><form_element>
<display_name>GL Customer</display_name>
<user_value>$customer</user_value>
</form_element><form_element>
<display_name>GL Product</display_name>
<user_value>$product</user_value>
</form_element><form_element>
<display_name>GL Project</display_name>
<user_value>$project</user_value>
</form_element><form_element>
<display_name>GL Account</display_name>
<user_value>$account</user_value>
</form_element><form_element>
<display_name>Quantity</display_name>
<user_value>$quantity</user_value>
</form_element><form_element>
<display_name>Project Number</display_name>
<user_value>$projnum</user_value>
</form_element></form_elements>
"@

$configPath = $path + '\'

switch ($prodid) {
    "linuxserver_6.2full" { $configPath = $configPath + 'L6' }
    "linuxserver_7full" { $configPath = $configPath + 'L7' }
    "WindowsServer2012_full" { $configPath = $configPath + 'WIN12' }
}
$configPath = $configPath + "." + $cpu + "." + $ram + "."
switch ($env) {
    "DEV" { $configPath = $configPath + 'D' }
    "TEST" { $configPath = $configPath + 'T' }
    "STAGE" { $configPath = $configPath + 'S' }
    "PROD" { $configPath = $configPath + 'P' }
}
switch ($zone) { "Intranet" { $configPath = $configPath + 'I' } }
switch ($dcenter) {
    "Chaska" { $configPath = $configPath + 'C' }
    "Elk River" { $configPath = $configPath + 'ER' }
}
switch ($serverType) {
    "APP" { $configPath = $configPath + 'A' }
    "DB" { $configPath = $configPath + 'DB' }
    "WEB" { $configPath = $configPath + 'W' }
}
$configPath = $configPath + '.xml'

$config > $configPath
}
}

# Provision VMs via API, inputs folder path and env (d, t, or s, optional), flag to call via command line: b
function buildconfig {
param([string]$folderpath, [string]$settings)

$path = $pwd.path + "\" + $folderpath

$buildenv="prod"
#$buildenv="dev"
#$buildenv="test"
#$buidenf="stage"

if ($settings -eq 't') { $buildenv="test" }
elseif ($settings -eq 'd') { $buildenv="dev" }
elseif ($settings -eq 's') { $buildenv="stage" }
else { $buildenv="prod" }


while($true){
    $build = $true
    $user = Read-Host "User "
    $user = "MS\" + $user
    $securepw = Read-Host "Password " -AsSecureString
    $pw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepw))
    $url = "https://servcat-$buildenv.uhc.com/spe/spews.asmx/Login?sUserId=$user&sPassword=$pw"
    if ($buildenv -eq 'prod') { $url = "https://servicecatalog.uhc.com/spe/spews.asmx/Login?sUserId=$user&sPassword=$pw" }

    try {
        $response = Invoke-RestMethod $url -Method Get -ErrorAction Stop
        $xmlresp = [xml]$response
        [string]$sessionID = $xmlresp.string.InnerText
        'Login Successful. Session token number: ' + $sessionID
        break
    }
    catch {
        write-host "**LOGIN ERROR**" -ForegroundColor Red
        write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
        write-host "`nInvalid Login. Please try again."
    }
}
    $RSOcall = 'InfrastructureProvisioningAuto'
    $configFiles = Get-ChildItem -Path $path -Include *.xml -Recurse
    $totalquant = 0
    foreach ($configFile in $configFiles) {
        $config = Get-Content $configFile
        [string]$configPath = $folderPath + "\" + $configFile.name
        $xml = [xml](get-content $configFile)
        $server = $xml.form_elements.form_element
        $quant = [int]$server[25].user_value
        $totalquant = $totalquant + $quant
        if (($totalquant -gt 10) -or ($quant -gt 10)) { break; }
    }
    if ($totalquant -gt 10) {
        $build = $false 
        "BuildMe has a 10 server cap. Please try again."
    }
    if ($build) {
        foreach ($configFile in $configFiles) {
            $config = Get-Content $configFile
            [string]$configPath = $folderPath + "\" + $configFile.name
            $xml = [xml](get-content $configFile)
            $server = $xml.form_elements.form_element
            $quant = $server[25].user_value
            if (($quant -eq "" -and $quant -eq [String]::Empty) -or ($quant -eq $null)) { $quant = 1 }
            for($i=1; $i -le $quant; $i++) {
                $valid = validateconfig -configfile $configpath
                if ($valid) {
                    try {
                        $url = "https://servcat-$buildenv.uhc.com/spe/spews.asmx/OrderProduct?sSessionId=$sessionID&sUserId=$user&sProductId=$RSOcall&sQuestionValueXml=$config"
                        if ($buildenv -eq 'prod') { $url = "https://servicecatalog.uhc.com/spe/spews.asmx/OrderProduct?sSessionId=$sessionID&sUserId=$user&sProductId=$RSOcall&sQuestionValueXml=$config" }
                        $response = Invoke-RestMethod $url -Method Get -ErrorAction Stop
                        $xmlresp = [xml]$response
                        [string]$token = $xmlresp.string.InnerText
                        'Build request successfully submitted. ESC number: ' + $token
                    }
                    catch {
                        write-host "**BUILD ERROR**" -ForegroundColor Red
                        write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
                        write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
                else {
                    "**ERROR**  Please enter a valid config file: " + $configFile
                }
            }
        }
    }
}

# Provision VM via API, inputs config.xml file and env (d, t, or s, optional), flag to call via command line: bf
#add param vor quantity
function buildfromfile {
param([string]$buildfile, [string]$settings, [string]$bquant)

$buildenv="prod"

if ($settings -eq 't') { $buildenv="test" }
elseif ($settings -eq 'd') { $buildenv="dev" }
elseif ($settings -eq 's') { $buildenv="stage" }
else { $buildenv="prod" }

while($true){
    $user = Read-Host "User "
    $user = "MS\" + $user
    $securepw = Read-Host "Password " -AsSecureString
    $pw = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($securepw))

    $url = "https://servcat-$buildenv.uhc.com/spe/spews.asmx/Login?sUserId=$user&sPassword=$pw"
    if ($buildenv -eq 'prod') { $url = "https://servicecatalog.uhc.com/spe/spews.asmx/Login?sUserId=$user&sPassword=$pw" }

    try {
        $response = Invoke-RestMethod $url -Method Get -ErrorAction Stop
        $xmlresp = [xml]$response
        [string]$sessionID = $xmlresp.string.InnerText
        'Login Successful! Session ID: ' + $sessionID
        break
    }
    catch {
        write-host "**LOGIN ERROR**" -ForegroundColor Red
        write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
        write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
        write-host "`nInvalid Login. Please try again."
    }
}
    $RSOcall = 'InfrastructureProvisioningAuto'
    $config = Get-Content $buildfile
    #$xml = [xml](get-content $buildfile)
    #$quant = $xml.'#comment'
    $quant = $bquant
    if (($quant -eq "" -and $quant -eq [String]::Empty) -or ($quant -eq $null)) { $quant = 1 }
    if (($intquant -ge 5)) {
        write-host "**Max Server Quantity (5)**"
        $quant = 5
    }
    for($i=1; $i -le $quant; $i++) {
        $valid = validateconfig -configfile $buildfile
        if ($valid) {
            try {
                $url = "https://servcat-$buildenv.uhc.com/spe/spews.asmx/OrderProduct?sSessionId=$sessionID&sUserId=$user&sProductId=$RSOcall&sQuestionValueXml=$config"
                if ($buildenv -eq 'prod') { $url = "https://servicecatalog.uhc.com/spe/spews.asmx/OrderProduct?sSessionId=$sessionID&sUserId=$user&sProductId=$RSOcall&sQuestionValueXml=$config" }
                $response = Invoke-RestMethod $url -Method Get -ErrorAction Stop
                $xmlresp = [xml]$response
                [string]$token = $xmlresp.string.InnerText
                'Build Successful! Token: ' + $token
            }
            catch {
                write-host "**BUILD ERROR**" -ForegroundColor Red
                write-host "Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
                write-host "Exception Message: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        else {
            "**ERROR**  Please enter a valid config file: " + $buildfile
        }
    }
}

# Perform input validation on inputted config file before allowing call to PMG, return true if pass
function validateconfig {
param([string]$configFile)

$xml = [xml](get-content $configFile)

$server = $xml.form_elements.form_element

$msid = $server[0].user_value
$email = $server[1].user_value
$group = $server[2].user_value
$prodid = $server[3].user_value
$sname = $server[4].user_value
$bunit = $server[5].user_value
$ounit = $server[6].user_value
$loc = $server[7].user_value
$department = $server[8].user_value
$cpu = $server[9].user_value
$ram = $server[10].user_value
$env = $server[11].user_value
$platform = $server[12].user_value
$zone = $server[13].user_value
$dcenter = $server[14].user_value
$unixid = $server[15].user_value
$agroup = $server[16].user_value
$serverType = $server[17].user_value
$tmdb = $server[18].user_value
$interfaceZone = $server[19].user_value
$dr = $server[20].user_value
$customer = $server[21].user_value
$product = $server[22].user_value
$project = $server[23].user_value
$account = $server[24].user_value
$quantity = $server[25].user_value
$projnum = $server[26].user_value

$invalid = @()
if ($msid -notmatch "^[a-zA-Z0-9]+$") { $invalid += "msid" }
if ($email -notmatch "^\w+(.|_)\w+@(optum|uhc).com$") { $invalid += "email" }
if ($group -notmatch "^[_a-zA-Z0-9 ]+$") { $invalid += "group" }
if ($bunit -notmatch "^\d{5}$") { $invalid += "bunit" }
if ($ounit -notmatch "^\d{5}$") { $invalid += "ounit" }
if ($loc -notmatch "^[a-zA-Z0-9]{8}$") { $invalid += "loc" }
if ($department -notmatch "^\d{6}$") { $invalid += "department" }
if ($unixid -and ($unixid -notmatch "^[a-zA-Z0-9]+$")) { $invalid += "unixid" }
if ($agroup -notmatch "^[_a-zA-Z0-9 ]+$") { $invalid += "agroup" }
if ($prodid -notin @("WindowsServer2012_full", "WindowsServer2012_R2_full", "linuxserver_6.2full", "linuxserver_7full")) { $invalid += "prodid" }
if ([int]$cpu -lt 1 -or [int]$cpu -gt 8) { $invalid += "cpu" }
if ([int]$ram -lt 1 -or [int]$ram -gt 64) { $invalid += "ram" }
if ($env -notin @("DEV", "TEST", "STAGE", "PROD")) { $invalid += "env" }
if ($platform -ne "uCI") { $invalid += "platform" }
if ($zone -notin @("Intranet", "Internet")) { $invalid += "zone" }
if ($dcenter -notin @("Chaska", "Elk River")) { $invalid += "dcenter" }
if ($serverType -notin @("APP", "DB", "WEB")) { $invalid += "servertype" }
if ($tmdb -notmatch "(^(TMDB-)[a-zA-Z0-9]+$)|^$") { $invalid += "tmdb" }
if (($interfaceZone -notin @('Presentation Zone','Application Zone','Tools Zone','Database Zone', ''))) { $invalid += "interfaceZone" }
if ($dr -notin @('uCI Active','uCI Standby', '')) { $invalid += "dr" }
if ($customer -notmatch "(^[a-zA-Z0-9]+$)|^$") { $invalid += "customer" }
if ($product -notmatch "(^[a-zA-Z0-9]+$)|^$") { $invalid += "product" }
if ($project -notmatch "(^[a-zA-Z0-9]+$)|^$") { $invalid += "project" }
if ($account -notmatch "(^[a-zA-Z0-9]+$)|^$") { $invalid += "account" }
#if ([int]$quantity -lt 1 -or [int]$quantity -gt 10) { $invalid += "quantity" }
#if ($projnum -notmatch "(^[a-zA-Z0-9]+$)|^$") { $invalid += "projnum" }

if ($invalid.Length -gt 0) {
write-host $invalid
return $false
#return $invalid
}
else { return $true }
}

# Perform input validation on user file before allowing call to PMG, return true if pass
function validateuser {
param([string]$userInput)
$json = Get-Content -Raw -Path $userInput | ConvertFrom-Json

$invalid = @()
if ($json.msid -notmatch "^[a-zA-Z0-9]+$") { $invalid += "msid" }
if ($json.email -notmatch "^\w+(.|_)\w+@(optum|uhc).com$") { $invalid += "email" }
if ($json.group -notmatch "^[a-zA-Z0-9 _]+$") { $invalid += "group" }
if ($json.bunit -notmatch "^\d{5}$") { $invalid += "bunit" }
if ($json.ounit -notmatch "^\d{5}$") { $invalid += "ounit" }
if ($json.loc -notmatch "^[A-Z0-9]{8}$") { $invalid += "loc" }
if ($json.department -notmatch "^\d{6}$") { $invalid += "department" }
if ($json.unixid -and ($json.unixid -notmatch "^[a-zA-Z0-9]+$")) { $invalid += "unixid" }
if ($json.agroup -notmatch "^[a-zA-Z0-9 _]+$") { $invalid += "agroup" }

if ($invalid.Length -gt 0) {
return $false
#return $invalid
}
else { return $true }
}

# Perform input validation on project file before allowing call to PMG, return true if pass
function validateproj {
param([string]$projInput)

if ($projInput.Split('.')[1] -eq "json") { $proj = Get-Content -Raw -Path $projInput | ConvertFrom-Json }
elseif ($projInput.Split('.')[1] -eq "xml") { $proj = [xml](get-content $projInput) }

$prodVar = 'linuxserver_6.2full','linuxserver_7full','WindowsServer2012_full','WindowsServer2012_R2_full','l6','l7','win12', 'win12r2'
$dcVar = 'Chaska', 'Elk River'
$zoneVar = 'Intranet', 'Internet'
$interfaceZoneVar = 'Presentation Zone','Application Zone','Tools Zone','Database Zone'
$drVar = 'uCI Active','uCI Standby', ' '

foreach($server in $proj.SLD.uCIServers.server) {
    switch ($server.captype) {
        "Linux VM uCI" { $captype = 'linuxserver_7full' }
        'linuxserver_6.2full'{ $captype = 'linuxserver_6.2full' }
        'linuxserver_7full'{ $captype = 'linuxserver_7full' }
        'WindowsServer2012_full'{ $captype = 'WindowsServer2012_full' }
        'WindowsServer2012_R2_full' { $captype = 'WindowsServer2012_R2_full' }
        "l6" { $captype = 'linuxserver_6.2full' }
        "l7" { $captype = 'linuxserver_7full' }
        "w12" { $captype = 'WindowsServer2012_full' }
        "w12r2" { $captype = 'WindowsServer2012_R2_full' }
    }
    $cpu = ($server.cpu -as [int]).ToString();
    $ram = ($server.ram -as [int]).ToString();
    $env = $server.environment;
    switch ($server.environment) {
        "Development" { $env = 'DEV' }
        "System Test" { $env = 'TEST' }
        "Staging" { $env = 'STAGE' }
        "Production" { $env = 'PROD' }
    }
    $platform = 'uCI'
    $zone = $server.zone;
    switch ($server.zone) {
        "Intranet Zone" { $zone = 'Intranet' }
        "Internet Zone" { $zone = 'Internet' }
    }
    switch ($server.datacenter) {
        "Chaska" { $dcenter = 'Chaska' }
        "ELR" { $dcenter = 'Elk River' }
    }
    $sname = $server.sname
    $serverType = $server.serverType
    $tmdb = $server.tmdb
    $interfaceZone = $server.interfaceZone
    $dr = $server.dr
    $quantity = $server.quantity
    $projnum = $server.projnum
}

$invalid = @()
if ((!$prodVar -contains $captype)) { $invalid += "captype" }
if ($sname -eq "" -and $sname -eq [String]::Empty) { $invalid += "sname" }
if ([int]$cpu -lt 1 -or [int]$cpu -gt 8) { $invalid += "cpu" }
if ([int]$ram -lt 1 -or [int]$ram -gt 64) { $invalid += "ram" }
if ($env -notin @("DEV", "TEST", "STAGE", "PROD")) { $invalid += "env" }
if ($platform -ne "uCI") { $invalid += "platform" }
if ($zone -notin @("Intranet", "Internet")) { $invalid += "zone" }
if ($dcenter -notin @("Chaska", "Elk River")) { $invalid += "dcenter" }
if ($serverType -notin @("APP", "DB", "WEB")) { $invalid += "servertype" }
if ($interfaceZone -notin @('Presentation Zone','Application Zone','Tools Zone','Database Zone', ' ')) { $invalid += "interfaceZone" }
if ($dr -notin @('uCI Active','uCI Standby', ' ')) { $invalid += 'dr' }
if ([int]$quantity -lt 1 -or [int]$quantity -gt 10) { $invalid += "quantity" }
#if ($projnum -notmatch "(^[a-zA-Z0-9]+$)|^$") { $invalid += "projnum" }

if ($invalid.Length -gt 0) {
#return $false
return $invalid
}
else { return $true }
}

#psboundparameter exe: 1st arg, userInput: 2nd arg, projInput: 3rd arg, folderPath: 4th arg, buildSettings
if ($exe -eq "" -and $exe -eq [String]::Empty) {
    "`nPlease enter a valid command`n============================`nms: create user config file`npi: interactive project config build`nm : start build (-userinput [json], -projinput [json])`n* : view additional buildme flags`n"
}
elseif ($exe -eq "*") {
    "`nPlease enter a valid command`n============================`nms: create user config file`npi: interactive project config build`nm : start build (-userinput [json], -projinput [json])`n============================`nx : start build and delete config.xml after (-userinput [json], -projinput [json])`ng : generate config files (-userinput [json], -projinput [json])`nb : build from config via folder (-folderPath [string] -settings [string]) `nbf: build from config via build file (-buildfile [string] -settings [string] -bquant [string])`ni : interactive config build (-userinput [json])`n"
}
elseif ($exe -eq "ms") {
    MSIDConfig
}
elseif ($exe -eq "g") {
    try {
        $validuser = validateuser -userInput $userInput
        $validproj = validateproj -projInput $projInput
        if ($validuser -and $validproj) { proj2config -userInput $userInput -projInput $projInput }
    }
    catch {
        "**ERROR** `nPlease enter a valid command`n============================`nms: create user config file`npi: interactive project config build`nm : start build (-userinput [json], -projinput [json])`n============================`nx : start build and delete config.xml after (-userinput [json], -projinput [json])`ng : generate config files (-userinput [json], -projinput [json])`nb : build from config via folder (-folderPath [string] -settings [string]) `nbf: build from config via build file (-buildfile [string] -settings [string] -bquant [string])`ni : interactive config build (-userinput [json])`n"
    }
}
elseif ($exe -eq "b") {
    try {
        if (!$folderPath) {
            $folderPath = $psboundparameters.userInput
            $bsettings = $psboundparameters.projInput
        }
        buildconfig -folderpath $folderPath -settings $bsettings
    }
    catch {
        "**ERROR**  Please enter a valid -folderpath"
        }
}
elseif ($exe -eq "bf") {
    try {
        if (!$buildfile) {
            $buildfile = $psboundparameters.userInput
            $bsettings = $psboundparameters.projInput
            $bquant = $psboundparameters.folderPath
        }
        if (validateconfig -configFile $buildfile) { buildfromfile -buildfile $buildfile -settings $bsettings -bquant $bquant}
    }
    catch {
        "**ERROR**  Please enter a valid -buildfile"
    }
}
elseif ($exe -eq "x") {
    try {
        $validuser = validateuser -userInput $userInput
        $validproj = validateproj -projInput $projInput
        if ($validuser -and $validproj) { proj2config -userInput $userInput -projInput $projInput }
        $folderpath = $userInput.Split(".")[0] + "-" + $projInput.Split(".").Split("-")[0]
        buildconfig -folderpath $folderpath
        remove-item $folderpath -force -recurse
    }
    catch {
        "**ERROR** `nBuild not successful"
    }
}
elseif ($exe -eq "m") {
   # try {
        $validuser = validateuser -userInput $userInput
        $validproj = validateproj -projInput $projInput
        if ($validuser -and $validproj) { proj2config -userInput $userInput -projInput $projInput }
        $folderpath = $userInput.Split(".")[0] + "-" + $projInput.Split(".").Split("-")[0]
        buildconfig -folderpath $folderpath
    #}
    #catch {
    #    "**ERROR** `nBuild not successful"
    #}
}
elseif ($exe -eq "i") {
    if ($userInput -eq "" -and $userInput -eq [String]::Empty) { }
    if (validateuser -userInput $userInput) { interactiveConfigBuild -jsonInput $userInput }
}
elseif ($exe -eq "pi") {
    interactiveProjBuild
}
elseif ($exe -eq "test") {
##put test scripts here
}
else { "**ERROR** `nPlease enter a valid command`n============================`nms: create user config file`npi: interactive project config build`nm : start build (-userinput [json], -projinput [json])`n============================`nx : start build and delete config.xml after (-userinput [json], -projinput [json])`ng : generate config files (-userinput [json], -projinput [json])`nb : build from config via folder (-folderPath [string] -settings [string]) `nbf: build from config via build file (-buildfile [string] -settings [string] -bquant [string])`ni : interactive config build (-userinput [json])`n"
}
