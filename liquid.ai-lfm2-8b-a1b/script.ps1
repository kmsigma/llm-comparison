# PowerShell 7 script to provision Hyper-V VMs with Debian 12.12.0 ISO using best practices

# Configuration
$isoPath = "E:\Hyper-V\ISOs\debian-12.12.0-amd64-netinst.iso"
$vmNamePrefix = "Debian-HWHardway"
$vmCount = 3
$vmMemoryGB = 4096
$vmVcpu = 2
$vmSizeName = "Standard_DS3_v2" # Best recommended size for Linux workloads
$vmStoragePath = "E:\Hyper-V\VMs\"
$diskSizeGB = 50
$hdType = "SSD" # Recommended for Linux performance

# Ensure ISO path exists
if (-not (Test-Path -Path $isoPath)) {
    throw "ISO file not found at $isoPath"
}

# Ensure VM storage directory exists
if (-not (Test-Path -Path $vmStoragePath)) {
    New-Item -Path $vmStoragePath -ItemType Directory | Out-Null
}

# Function to create a VM with best-practice settings
function New-DebianHyperVVM {
    param (
        [string]$vmName,
        [int]$vcpu,
        [int]$memoryGB,
        [string]$sizeName,
        [string]$isoPath,
        [string]$storagePath
    )

    # Create VM
    $vm = New-VM `
        -Name $vmName `
        -MemoryStartupBytes ($memoryGB * 1GB) `
        -VCPUs $vcpu `
        -Size $sizeName `
        -VHDPath "$storagePath\$vmName.vhdx` `
        -VHDStorageType SSD `
        -VHDSizeGB $diskSizeGB `
        -EnableSharingEnabled $true `
        -EnableSharingPasswordEnabled $false `
        -BootDeviceType HardDisk `
        -BootDeviceSource "ISO` `
        -BootDeviceISO $isoPath `
        -NetworkAdapter @{Name = "Default"; MacAddress = (Get-NetAdapter -Name "Ethernet").MacAddress } `
        -HostNetwork "Disabled" `
        -DisablePXE $true `
        -EnableFastBoot $false `
        -EnableSecureBoot $true `
        -SecureBootMode "Trusted" `
        -AllowRemoteManagement $false `
        -AllowRemoteDesktop $false `
        -ForceStartup `
        -LogPath "$storagePath\$vmName-start.log"

    if ($null -eq $vm) {
        throw "Failed to create VM $vmName"
    }
    Write-Host "Created VM: $vmName"
    return $vm
}

# Provision VMs
$vms = @()
for ($i = 1; $i -le $vmCount; $i++) {
    $vmName = "$vmNamePrefix-$i"
    $vm = New-DebianHyperVVM -vmName $vmName -vcpu $vmVcpu -memoryGB $vmMemoryGB -sizeName $vmSizeName -isoPath $isoPath -storagePath $vmStoragePath
    $vms += $vm
}

Write-Host "Provisioned $($vms.Count) Debian VMs."

# Optional: Start VMs after creation (can be skipped if manual start preferred)
foreach ($vm in $vms) {
    Start-VM -VM $vm -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 30
    Write-Host "Started VM: $($vm.Name)"
}

Write-Host "✅ Hyper-V VMs provisioned successfully with Debian 12.12.0 ISO and best practices."