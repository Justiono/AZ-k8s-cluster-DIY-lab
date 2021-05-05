# User input parameters"
# ====================="

$AzQualifier = "jpk8slab"
$AzLoc = "EastUS"
$AzVMSize = "Standard_D1"
$NumOfMasterNode = 1
$NumOfWorkerNode = 2

# System parameters"
# ====================="

$AzRgName = "rg" + $AzQualifier
$AzImageRgName = "rgimg" + $AzQualifier
$AzModelVM = "vmmodel" + $AzQualifier
$AzModelVMNic = $AzModelVM + "Nic"
$AzVNet = "vn" + $AzQualifier
$AzSubnet = "snet1" + $AzQualifier
$AzNsgRule1 = "rule" + $AzQualifier + "SSH"
$AzNsgRule2 = "rule" + $AzQualifier + "HTTPS"
$AzNsgName = "nsg" + $AzQualifier
$AzCustomImageName = "img" + $AzQualifier
