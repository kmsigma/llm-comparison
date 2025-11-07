# Liquid.ai (LFM2-2.6B)

Creating a PowerShell script to provision Hyper-V virtual machines (VMs) with Debian 12.12.0 installed from an ISO file involves several steps. Below is a comprehensive script based on the principles and practices found in the [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) GitHub repository, adapted for Hyper-V and Linux VMs using Debian.

## Prerequisites:

1. Hyper-V Enabled: Ensure Hyper-V is enabled on your Windows host.
2. PowerShell Version: Use PowerShell 7.
3. Administrative Privileges: The script requires administrative rights.
4. Debian ISO Path: The Debian ISO is located at E:\Hyper-V\ISOs\debian-12.12.0-amd64-netinst.iso.
5. Virtual Hard Disk (VHD) Creation: The script will create a new VHD and VM with recommended settings for Debian.

## Script Overview:

1. Create a New Virtual Hard Disk (VHD) with recommended settings.
2. Create a New Virtual Machine (VM) using the VHD.
3. Configure the VM with appropriate settings for Debian.
4. Install Debian from the ISO.
5. Start the VM after installation.

## PowerShell Script:

```powershell
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
```

## Explanation of Key Steps:

1. Creating a Virtual Hard Disk (VHD):

- `New-VMHardDisk` creates a new VHD with a specified size. The size of 32 GB is recommended for Debian 12 to ensure sufficient space for the OS and applications.

2. Creating a Virtual Machine:

- `New-VM` initializes a new VM using the Debian ISO. It specifies memory, processor count, and other essential parameters. The `-OSImage` parameter points to the Debian ISO.

3. Configuring VM Settings:

- `Set-VMProperty` applies properties to optimize performance and usability for Debian. This includes setting idle time, disk space limits, network configurations, and DNS settings.

4. Network Configuration:

- A NAT network adapter is configured to allow the VM to access the internet. Adjust IP addresses as needed for your environment.

5. Starting the VM:

- `Start-VM` brings the VM online. A short delay ensures the VM has enough time to initialize before proceeding.

## Additional Considerations:

- **Dynamic Memory:** While not explicitly enabled in this script, you can enable dynamic memory by adding -EnableDynamicMemory if needed.
- **Storage Spaces:** For larger storage needs, consider enabling storage spaces and configuring them appropriately.
- **Security Groups:** Implement security groups or firewall rules as required.
- **Backup and Recovery:** Regularly back up VMs and configurations.
- **Monitoring:** Use Hyper-V Manager or PowerShell cmdlets to monitor VM health and performance.

## Running the Script:

1. **Save the Script:** Save the above script to a `.ps1` file, e.g., `Provision-DebianVM.ps1`.
2. **Execute the Script:**

- Open PowerShell as Administrator.
- Navigate to the directory containing the script.
- Run the script using:

```powershell
.\Provision-DebianVM.ps1
```

- If prompted, sign the script with a digital certificate if it hasn't been signed.

## Troubleshooting:

- **Hyper-V Not Enabled:** Ensure Hyper-V is enabled via Control Panel > System and Security > System > Advanced system settings > Virtualization Feature Settings.
- **Permissions:** Run PowerShell as Administrator.
- **ISO Accessibility:** Ensure the ISO path is correct and accessible.
- **Resource Limits:** Ensure the host machine has sufficient resources (CPU, RAM, storage) to run the VM.

This script provides a foundational approach to automating the provisioning of Debian VMs on Hyper-V using PowerShell. Depending on specific requirements, further customization may be necessary.
