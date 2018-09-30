#
#THIS SCRIPT IS TO BUILD CODE FOR WEB PAGE PROCESSING
#
if (test-path %HOME%\documents\webcodegen)
{
  $dummy=""
}
else
{
  mkdir %HOME%\documents\webcodegen
}
$workDir=%HOME\documents\webcodegen
$codeName=Read-Host "Please enter the code name you want to work with?"
if (test-path $workDir\$codeName.txt)
{
  $dummy=""
}
else
{
  echo "# CODE BUILD FOR "$codeName >$workDir\$codeName.txt
}
