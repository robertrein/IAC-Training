
$IE=new-object -com internetexplorer.application
$webpage="http://openview.uhc.com/certs/policies/a4c90b9a-f15e-11d6-9032-001083fdff5e_data"
$IE.navigate2($webpage) >a4c90b9a-f15e-11d6-9032-001083fdff5e_data
$IE.visible=$false
