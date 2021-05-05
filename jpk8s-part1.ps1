# User input parameters"
# ====================="
. "./UserVariables.ps1"

# Configure the SSH key
ssh-keygen -m PEM -t rsa -b 4096 -no-passphrase -f ~/.ssh/id_rsa
$sshPublicKey = cat ~/.ssh/id_rsa.pub

Remove-AzResourceGroup -Name $AzRgName -Force
Remove-AzResourceGroup -Name $AzImageRgName -Force

echo "Step 1 - Preparing for the lab environment"
echo "=================================================================="
echo "Step 1a - Creating resource groups"
echo "=================================================================="

New-AzResourceGroup -Name $AzRgName -Location $AzLoc
New-AzResourceGroup -Name $AzImageRgName -Location $AzLoc

echo "Step 1b - Creating network security group rules for port 22 & 443"
echo "=================================================================="

$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
  -Name $AzNsgRule1  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22 `
  -Access "Allow"

$nsgRuleHTTPS = New-AzNetworkSecurityRuleConfig `
  -Name $AzNsgRule2  `
  -Protocol "Tcp" `
  -Direction "outbound" `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 443 `
  -Access "Allow"

echo "Step 1c - Creating the network security group"
echo "=================================================================="

$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc `
  -Name $AzNsgName `
  -SecurityRules $nsgRuleSSH,$nsgRuleHTTPS

echo "Step 1d - Creating Subnet and VNet"
echo "=================================================================="

$subnetConfig = New-AzVirtualNetworkSubnetConfig `
  -Name $AzSubnet `
  -AddressPrefix 10.10.1.0/24 `
  -NetworkSecurityGroup $nsg

$virtualNetwork = New-AzVirtualNetwork `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc `
  -Name $AzVNet `
  -AddressPrefix 10.10.0.0/16 `
  -Subnet $subnetConfig

echo "Step 1e - Creating the model VM (to create the template from)"
echo "=================================================================="

$pip = New-AzPublicIpAddress `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc `
  -AllocationMethod Dynamic `
  -IdleTimeoutInMinutes 4 `
  -Name "$AzModelVM$(Get-Random)"

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface `
  -Name $AzModelVMNic `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc `
  -SubnetId $virtualNetwork.Subnets[0].Id `
  -PublicIpAddressId $pip.Id

# Define a credential object
$securePassword = ConvertTo-SecureString 'MyP@55w0rd' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azuser", $securePassword)


# Create a virtual machine configuration
$vmConfig = New-AzVMConfig `
  -VMName $AzModelVM `
  -VMSize $AzVMSize | `
Set-AzVMOperatingSystem `
  -Linux `
  -ComputerName $AzModelVM `
  -Credential $cred | `
Set-AzVMSourceImage `
  -PublisherName "Canonical" `
  -Offer "UbuntuServer" `
  -Skus "18.04-LTS" `
  -Version "latest" | `
Add-AzVMNetworkInterface `
  -Id $nic.Id

New-AzVM `
  -ResourceGroupName $AzRgName `
  -Location $AzLoc -VM $vmConfig

Get-AzPublicIpAddress -ResourceGroupName $AzRgName | Select "IpAddress"

echo "Step 2 - Performing Docker & Kubernetes installation"
echo "=================================================================="

Invoke-AzVMRunCommand `
   -ResourceGroupName $AzRgName `
   -VMName $AzModelVM `
   -CommandId "RunShellScript" `
   -ScriptPath "./DockerK8SInstall.bash"

#Read-Host -Prompt 'CONTINUE?'

echo "Step 3 - Creating a boot image"
echo "=================================================================="

Stop-AzVM -ResourceGroupName $AzRgName -Name $AzModelVM -Force
Set-AzVm -ResourceGroupName $AzRgName -Name $AzModelVM -Generalized

$vm = Get-AzVM -Name $AzModelVM -ResourceGroupName $AzRgName
$imageConfig = New-AzImageConfig -Location $AzLoc -SourceVirtualMachineId $vm.Id
$image = New-AzImage -Image $imageConfig -ImageName $AzCustomImageName -ResourceGroupName $AzImageRgName

Get-AzImage -ResourceGroupName $AzImageRgName

Remove-AzVM -Name $AzModelVM `
      -ResourceGroupName $AzRgName `
      -Force

# Define a credential object
$securePassword = ConvertTo-SecureString 'MyP@55w0rd' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azuser", $securePassword)

For ($i=1; $i -le $NumOfMasterNode; $i++) {
    # Create a virtual network card (without public IP address)
    $nic0 = New-AzNetworkInterface `
      -Name $AzQualifier"master"$i"Nic" `
      -ResourceGroupName $AzRgName `
      -Location $AzLoc `
      -SubnetId $virtualNetwork.Subnets[0].Id

    # Create a virtual machine using the custom image

    $vmConfig0 = New-AzVMConfig `
      -VMName $AzQualifier"master"$i `
      -VMSize $AzVMSize | `
    Set-AzVMOperatingSystem `
      -Linux `
      -ComputerName $AzQualifier"master"$i `
      -Credential $cred | `
    Set-AzVMSourceImage `
      -Id $image.Id | `
    Add-AzVMNetworkInterface `
      -Id $nic0.Id

    Add-AzVMSshPublicKey `
     -VM $vmconfig `
     -KeyData $sshPublicKey `
     -Path "/home/azuser/.ssh/authorized_keys"

    New-AzVM `
      -ResourceGroupName $AzRgName `
      -Location $AzLoc -VM $vmConfig0
    }

For ($i=1; $i -le $NumOfWorkerNode; $i++) {
    # Create a virtual network card (without public IP address)
    $nic0 = New-AzNetworkInterface `
      -Name $AzQualifier"worker"$i"Nic" `
      -ResourceGroupName $AzRgName `
      -Location $AzLoc `
      -SubnetId $virtualNetwork.Subnets[0].Id

    # Create a virtual machine using the custom image

    $vmConfig0 = New-AzVMConfig `
      -VMName $AzQualifier"worker"$i `
      -VMSize $AzVMSize | `
    Set-AzVMOperatingSystem `
      -Linux `
      -ComputerName $AzQualifier"worker"$i `
      -Credential $cred | `
    Set-AzVMSourceImage `
      -Id $image.Id | `
    Add-AzVMNetworkInterface `
      -Id $nic0.Id

    Add-AzVMSshPublicKey `
     -VM $vmconfig `
     -KeyData $sshPublicKey `
     -Path "/home/azuser/.ssh/authorized_keys"

    New-AzVM `
      -ResourceGroupName $AzRgName `
      -Location $AzLoc -VM $vmConfig0
    }
