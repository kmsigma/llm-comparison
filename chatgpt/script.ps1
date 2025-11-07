# Requires PowerShell 7+ and Hyper-V module
# Example: create 4 VMs (1 jumpbox/control + 3 workers) for “Kubernetes the Hard Way”
param(
    [int]$VmCount = 4,
    [string]$VmNamePrefix = "k8s-node",
    [string]$VmIsoPath = "E:\Hyper-V\ISOs\debian-12.12.0-amd64-netinst.iso",
    [string]$VmSwitchName = "Default Switch",   # or your external/virtual switch name
    [string]$VmVhdPathRoot = "E:\Hyper-V\VHDs",
    [string]$VmGeneration = "2",                # use Gen2
    [int]$MemoryStartupMB = 8192,               # 8 GB startup RAM (adjust as needed)
    [int]$ProcessorCount = 4,                    # number of vCPUs (adjust for host)
    [int]$VhdSizeGB = 50                          # size of virtual disk in GB
)

Import-Module Hyper-V -ErrorAction Stop

for ($i = 1; $i -le $VmCount; $i++) {
    $vmName = (“$VmNamePrefix{0:D2}” -f $i)
    $vhdPath = Join-Path $VmVhdPathRoot (“$vmName.vhdx”)
    Write-Host "`n=== Creating VM: $vmName ==="

    # Create VM
    New-VM `
        -Name $vmName `
        -MemoryStartupBytes ($MemoryStartupMB * 1MB) `
        -Generation $VmGeneration `
        -SwitchName $VmSwitchName `
        -NewVHDPath $vhdPath `
        -NewVHDSizeBytes ($VhdSizeGB * 1GB) `
        -BootDevice CD `
        -NoVHDPath | Out-Null

    # Set processor count
    Set-VMProcessor -VMName $vmName -Count $ProcessorCount

    # Recommended for Linux: disable Secure Boot (especially Gen2)
    if ($VmGeneration -eq "2") {
        Write-Host "Disabling Secure Boot for Gen2 VM (Linux compatibility)"
        Set-VMFirmware -VMName $vmName -EnableSecureBoot Off
    }

    # Configure the DVD drive to mount the ISO for installation
    Add-VMDvdDrive -VMName $vmName -Path $VmIsoPath

    # Use SCSI controller for the VHDX (default for Gen2 is SCSI)
    # (New-VM already attached the VHDX to SCSI controller for Gen2)

    # Use synthetic (Hyper-V) network adapter (remove any legacy NICs)
    # First remove any legacy network adapter
    $legacy = Get-VMNetworkAdapter -VMName $vmName | Where-Object { $_.AdapterType -eq "Legacy" }
    if ($legacy) {
        Remove-VMNetworkAdapter -VMNetworkAdapter $legacy
    }
    # Then add a default network adapter (synthetic)
    Add-VMNetworkAdapter -VMName $vmName -SwitchName $VmSwitchName

    # Set automatic start action & automatic stop action
    Set-VM -VMName $vmName -AutomaticStartAction StartIfRunning -AutomaticStopAction Save

    Write-Host "VM $vmName created: Memory=$MemoryStartupMB MB, CPU=$ProcessorCount, VHD=$VhdSizeGB GB, Generation=$VmGeneration"
}

Write-Host "`nAll VMs created. You may now start them to install Debian."
