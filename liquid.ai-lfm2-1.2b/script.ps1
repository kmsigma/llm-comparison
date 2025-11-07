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