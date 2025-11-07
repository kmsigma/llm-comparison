# Liquid AI (LFM2-1.2B)

Certainly! Below is a PowerShell 7 script that automates the provisioning of virtual machines on Hyper-V, setting them to boot with the recommended Debian ISO from the specified path. The script uses the System.ManagementToolkit.Hypervisor module to interact with Hyper-V APIs. If you don't have this module installed, you can install it using:

```powershell
Install-Module -Name System.ManagementToolkit.Hypervisor -Scope CurrentUser -Force
```

Here's the script:

```powershell
# Define the paths
$hypervRootPath = "E:\Hyper-V"
$isoPath = "E:\Hyper-V\ISOs\debian-12.12.0-amd64-netinst.iso"
$vmName = "MyVM"
$vmSize = "Standard_DS3_v2" # Adjust as needed

# Ensure the hyper-v root directory exists
if (-not (Test-Path $hypervRootPath)) {
    New-Item -Path $hypervRootPath -ItemType Directory -Force | Out-Null
}

# Create the VM configuration file
$configPath = Join-Path -Path $hypervRootPath -ChildPath "$vmName-\$vmSize-$vmName.dcx"
$configContent = @"
<VirtualMachine Name="$vmName-$vmSize-$vmName.dcx">
    <ImageSource>
        <WindowsArchitecture Version="16.x"/>
        <WindowsVersion Version="21H"/>
        <ProvisioningProfile Name="Default" ExecutionModel="Dynamic">
            <DiskPartition>
                <DiskPartitionSource Type="VHD">
                    <VolumeSize>2048</VolumeSize>
                    <DiskPartitionFormat>VHDX</DiskPartitionFormat>
                    <DiskPartitionProperties>
                        <DiskPartitionProperty Name="InitializeMode">Automatic</DiskPartitionProperty>
                    </DiskPartitionProperties>
                </DiskPartition>
            </DiskPartition>
        </WindowsArchitecture>
        <CPUCount>1</CPUCount>
        <Memory>2048</Memory>
        <Storage>20GB</Storage>
        <NetworkInterfaceType>NetworkInterface</NetworkInterfaceType>
        <VirtualNetworkName>Default</VirtualNetworkName>
        <VirtualNetworkHostName>Default</VirtualNetworkHostName>
        <VirtualMachineHardwareAccelerator>Intel VT-x</VirtualMachineHardwareAccelerator>
        <VirtualDiskDrive>
            <DriveType>GUID>
            <FileSystem>NTFS</FileSystem>
            <DiskSize>2048</DiskSize>
            <DiskPartitionSize>2048</DiskPartitionSize>
            <DiskPartitionMode>VOLUMETRY</DiskPartitionMode>
        </VirtualDiskDrive>
    </ImageSource>
    <Settings>
        <Setting Name="BootOrder">
            <Value>Debian ISO</Value>
        </Setting>
    </Settings>
</VirtualMachine>
"@

# Create the VM configuration file
New-Item -Path $configPath -ItemType File -Force -Value $configContent

# Create the VM
$vm = New-HyperVMVirtualMachine -Name $vmName -RootDirectory $hypervRootPath -ConfigurationPath $configPath -Size $vmSize -Image $isoPath -Settings @{
    BootOrder = "Debian ISO"
}

# Start the VM
Start-VM -VM $vm

# Wait for the VM to start
Start-Sleep -Seconds 30

# Remove the VM configuration file after it starts
Remove-Item -Path $configPath -Force

Write-Host "VM $vmName has been created and started successfully."
```

## Explanation:

1. **Path Definitions:** The script defines the paths for the Hyper-V root directory and the Debian ISO file.
2. **Hyper-V Root Directory Creation:** Ensures the Hyper-V root directory exists.
3. **VM Configuration File:** Creates a YAML-formatted configuration file for the VM, including recommended settings for a Debian ISO.
4. **VM Creation:** Uses the New-HyperVMVirtualMachine cmdlet to create the VM with the specified configuration.
5. **VM Start:** Starts the VM and waits for it to complete.
6. **Cleanup:** Removes the VM configuration file after the VM starts.

## Notes:

- **VM Size:** Adjust the `vmSize` variable to match your requirements (e.g., `Standard_BUILD_X86_64`, `Standard_DS3_v3`).
- **CPU Count:** Adjust the `CPUCount` variable if you need more or fewer CPUs.
- **Memory:** Adjust the `Memory` variable to set the RAM size.
- **Network Interface:** The script sets the network interface type to `NetworkInterface`. You can change this if needed.
- **Virtual Network:** The script uses a default virtual network. You can customize this if required.

Make sure you have the necessary permissions to create and manage Hyper-V VMs in your environment. Run the script with appropriate privileges (e.g., as an administrator).
