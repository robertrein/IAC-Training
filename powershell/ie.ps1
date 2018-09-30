$ie = new-object -com "InternetExplorer.Application"
$ie.navigate("https://releaseservices.uhc.com/itg/dashboard/app/portal/PageView.jsp")
$ie.visible = $true
$doc = $ie.document 
$tb1 = $doc.getElementByID("uniqueID") 
$tb1 