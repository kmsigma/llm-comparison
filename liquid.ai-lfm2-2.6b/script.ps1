# Import necessary modules
Import-Module Hyper-V

# Configuration Variables
$vmName = "Debian12VM"
$vhdPath = "$env:USERPROFILE\Documents\Hyper-V\VMs\vm_$vmName.vhdx"
$isoPath = "E:\Hyper-V\ISOs\debian-12.12.0-amd64-netinst.iso"
$vmSizeGB = 32 # Recommended size for Debian 12
$osType = "Linux"
$osVersion = "Debian 12.12.0"

# Step 1: Create a new Virtual Hard Disk (VHD)
Write-Host "Creating a new Virtual Hard Disk..."
New-VMHardDisk -Name "vm_$vmName" -Size $vmSizeGB -DriveType VHD -InitialSize $vmSizeGB -File $vhdPath

# Step 2: Create a new Virtual Machine
Write-Host "Creating a new Virtual Machine..."
New-VM -Name $vmName -MemoryBytes 2048 -ProcessorCount 2 -OSType Linux -OsImage $isoPath -VHDPath $vhdPath -VMSize $vmSizeGB -EnableLiveUpgrade -EnableStorageReplication -EnableStorageSpaces -EnableDynamicMemory -EnableDynamicNetworking

# Step 3: Configure VM Settings
Write-Host "Configuring VM settings..."
Set-VM -Name $vmName -VMName $vmName -VMDescription "Debian 12 VM"

# Set recommended settings for Debian
Set-VMProperty -Name $vmName -Name "virtualMachineSettings" -Value @{
    "virtualMachineSettings" = @{
        "virtualMachineIdleTimeInMinutes" = 30
        "virtualMachineMaxDiskSpaceGB" = 100
        "virtualMachineNetworkAdapterPriority" = 100
        "virtualMachineNetworkAdapterType" = "NAT"
        "virtualMachineNetworkAdapterName" = "VM-NAT"
        "virtualMachineNetworkAdapterIPAddress" = "192.168.56.101/24"
        "virtualMachineNetworkAdapterSubnetMask" = "255.255.255.0"
        "virtualMachineNetworkAdapterGateway" = "192.168.56.1"
        "virtualMachineNetworkAdapterDnsServer" = "8.8.8.8"
        "virtualMachineNetworkAdapterDnsServerList" = @("8.8.4.4")
        "virtualMachineNetworkAdapterPortForwarding" = $false
    }
}

# Optional: Set up network adapters
Set-VMNetworkAdapter -Name "VM-NAT" -Enabled $true -IPConfiguration @{"IPAddress" = "192.168.56.101", "SubnetMask" = "255.255.255.0"}

# Step 4: Start the VM
Write-Host "Starting the VM..."
Start-VM -Name $vmName

# Optional: Wait for VM to start
Start-Sleep -Seconds 60

Write-Host "VM '$vmName' has been started successfully."