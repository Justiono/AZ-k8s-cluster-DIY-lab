$AzRgName = "jprgk8slab"
$AzImageRgName = "jprgk8simglab"
$AzLoc = "EastUS"
$AzVnet = "jpvnk8slab"
$AzSubnet = "jpk8ssubnet1"

$virtualNetwork = Get-AzVirtualNetwork -Name $AzVnet -ResourceGroup $AzRgName

# Create a resource group

#New-AzResourceGroup -Name $AzImageRgName -Location $AzLoc

# Create a new image

Stop-AzVM -ResourceGroupName $AzRgName -Name jpk8snode1 -Force
Set-AzVm -ResourceGroupName $AzRgName -Name jpk8snode1 -Generalized

$vm = Get-AzVM -Name jpk8snode1 -ResourceGroupName $AzRgName
$imageConfig = New-AzImageConfig -Location $AzLoc -SourceVirtualMachineId $vm.Id
$image = New-AzImage -Image $imageConfig -ImageName jpimgk8sv2 -ResourceGroupName $AzImageRgName

Get-AzImage -ResourceGroupName $AzImageRgName

Remove-AzVm -Name jpk8snode1 -ResourceGroupName $AzRgName -Force
# Create the 1st Docker K8S node (from the template)

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

# To Clean up
#Remove-AzResourceGroup -Name $AzRgName
