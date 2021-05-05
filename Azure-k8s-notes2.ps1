$AzRgName = "jprgk8slab"
$AzLoc = "EastUS"

# Create a resource group

New-AzResourceGroup -Name $AzRgName -Location $AzLoc

#Create VNet

$subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name jpk8ssubnet1 `
  -AddressPrefix 10.10.1.0/24

$virtualNetwork = New-AzVirtualNetwork `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc `
  -Name jpvnk8slab `
  -AddressPrefix 10.10.0.0/16 `
  -Subnet $subnetConfig

# Create an edge node VM (bastion host)

$pip = New-AzPublicIpAddress `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc `
  -AllocationMethod Static `
  -IdleTimeoutInMinutes 4 `
  -Name "jpk8sedge$(Get-Random)"

# Create an inbound network security group rule for port 22
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
  -Name "jpnsgk8sRuleSSH"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22 `
  -Access "Allow"

# Create a network security group
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc `
  -Name "jpnsgk8s" `
  -SecurityRules $nsgRuleSSH

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface `
  -Name "jpk8sedgeNic" `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc `
  -SubnetId $virtualNetwork.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Define a credential object
$securePassword = ConvertTo-SecureString 'MyPa55w0rd!' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azuser", $securePassword)

exit

# Create a virtual machine configuration
$vmConfig = New-AzVMConfig `
  -VMName "jpk8sedge" `
  -VMSize "Standard_D1" | `
Set-AzVMOperatingSystem `
  -Linux `
  -ComputerName "jpk8sedge" `
  -Credential $cred | `
Set-AzVMSourceImage `
  -PublisherName "Canonical" `
  -Offer "UbuntuServer" `
  -Skus "18.04-LTS" `
  -Version "latest" | `
Add-AzVMNetworkInterface `
  -Id $nic.Id

# Configure the SSH key
ssh-keygen -m PEM -t rsa -b 4096
$sshPublicKey = cat ~/.ssh/id_rsa.pub
Add-AzVMSshPublicKey `
  -VM $vmconfig `
  -KeyData $sshPublicKey `
  -Path "/home/azuser/.ssh/authorized_keys"

New-AzVM `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc -VM $vmConfig

Get-AzPublicIpAddress -ResourceGroupName $AzRgName | Select "IpAddress"

# Create the 1st Docker node (for a template)

# Create a virtual network card (without public IP address)
$nic0 = New-AzNetworkInterface `
  -Name "jpk8snode0Nic" `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc `
  -SubnetId $virtualNetwork.Subnets[0].Id `
  -NetworkSecurityGroupId $nsg.Id

# Create a virtual machine configuration
$vmConfig0 = New-AzVMConfig `
  -VMName "jpk8snode0" `
  -VMSize "Standard_D1" | `
Set-AzVMOperatingSystem `
  -Linux `
  -ComputerName "jpk8snode0" `
  -Credential $cred | `
Set-AzVMSourceImage `
  -PublisherName "Canonical" `
  -Offer "UbuntuServer" `
  -Skus "18.04-LTS" `
  -Version "latest" | `
Add-AzVMNetworkInterface `
  -Id $nic0.Id

Add-AzVMSshPublicKey `
  -VM $vmconfig0 `
  -KeyData $sshPublicKey `
  -Path "/home/azuser/.ssh/authorized_keys"

New-AzVM `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc -VM $vmConfig0

# Perform Docker installation

# Take a snapshot and create a new image



# To Clean up
#Remove-AzResourceGroup -Name $AzRgName
