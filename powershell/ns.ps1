
function Read-InputObjects([string]$Message,[string]$WindowTitle)
{
	Add-Type -AssemblyName System.Drawing
	Add-Type -AssemblyName System.Windows.Forms

	# Create the Label.
	$label = New-Object System.Windows.Forms.Label
	$label.Location = New-Object System.Drawing.Size(10,10)
	$label.Size = New-Object System.Drawing.Size(280,20)
	$label.AutoSize = $true
	$label.Text = $Message

	# Create the TextBox used to capture the user's text.
	$textBox = New-Object System.Windows.Forms.TextBox
	$textBox.Location = New-Object System.Drawing.Size(10,40)
	$textBox.Size = New-Object System.Drawing.Size(670,200)
	$textBox.AcceptsReturn = $true
	$textBox.AcceptsTab = $false
	$textBox.Multiline = $true
	$textBox.ScrollBars = 'Both'
	$textBox.Text = $Message

	# Create the OK button.
	$okButton = New-Object System.Windows.Forms.Button
	$okButton.Location = New-Object System.Drawing.Size(415,250)
	$okButton.Size = New-Object System.Drawing.Size(75,25)
	$okButton.Text = "OK"
	$okButton.Add_Click({ $form.Tag = $textBox.Text; $form.Close() })

	# Create the Clear button.
	$clearButton = New-Object System.Windows.Forms.Button
	$clearButton.Location = New-Object System.Drawing.Size(510,250)
	$clearButton.Size = New-Object System.Drawing.Size(75,25)
	$clearButton.Text = "Clear"
	$clearButton.Add_Click({ $form.Tag = $clearButton.Text; $form.Close() })

	# Create the Cancel button.
	$cancelButton = New-Object System.Windows.Forms.Button
	$cancelButton.Location = New-Object System.Drawing.Size(605,250)
	$cancelButton.Size = New-Object System.Drawing.Size(75,25)
	$cancelButton.Text = "Cancel"
	$cancelButton.Add_Click({ $form.Tag = $cancelButton.Text; $form.Close() })

	# Create the form.
	$form = New-Object System.Windows.Forms.Form
	$form.Text = $WindowTitle
	$form.Size = New-Object System.Drawing.Size(705,320)
	$form.FormBorderStyle = 'FixedSingle'
	$form.StartPosition = "CenterScreen"
	$form.AutoSizeMode = 'GrowAndShrink'
	$form.Topmost = $True
	$form.AcceptButton = $okButton
	$form.CancelButton = $cancelButton
	$form.ShowInTaskbar = $true

	# Add all of the controls to the form.
	$form.Controls.Add($label)
	$form.Controls.Add($textBox)
	$form.Controls.Add($okButton)
	$form.Controls.Add($clearButton)
	$form.Controls.Add($cancelButton)

	# Initialize and show the form.

	$form.Add_Shown({$form.Activate()})

	$form.ShowDialog() > $null	# Trash the text of the button that was clicked.


	# Return the text that the user entered.
	return $form.Tag
}

$whichWay=Read-Host "(F)orward or (R)everse"
$whichWay=$whichWay.toLower()

if ($whichWay -eq "f")
{
	Read-InputObjects($Message="Please Enter FQDN Host Names here", "Powershell NSLookup")
}
