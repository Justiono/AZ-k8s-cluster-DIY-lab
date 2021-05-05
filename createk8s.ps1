# User input parameters"
# ====================="
. "./UserVariables.ps1"

# Define a credential object
$securePassword = ConvertTo-SecureString 'MyP@55w0rd' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azuser", $securePassword)

# Create a virtual network card (without public IP address)
$nic0 = New-AzNetworkInterface `
  -Name "jpk8snode0Nic" `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc `
  -SubnetId $virtualNetwork.Subnets[0].Id

# Create a virtual machine using the custom image

$vmConfig0 = New-AzVMConfig `
  -VMName "jpk8snode1" `
  -VMSize "Standard_D1" | `
Set-AzVMOperatingSystem `
  -Linux `
  -ComputerName "jpk8sedge" `
  -Credential $cred | `
Set-AzVMSourceImage `
  -Id $image.Id | `
Add-AzVMNetworkInterface `
  -Id $nic0.Id

New-AzVM `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc -VM $vmConfig0

