# Copilot (Think Deeper) Response

I created a PowerShell 7 script below that provisions the Kubernetes the Hard Way VM topology on Hyper‑V, creates VHDX files with Microsoft‑recommended settings (1MB block size, 4K physical sector), uses Generation 2 VMs, and attaches the Debian ISO at `E:\Hyper-V\ISOs\debian-12.12.0-amd64-netinst.iso` so each VM boots to the installer.

## Overview

This script assumes the Kubernetes the Hard Way topology (bastion, three controller nodes, three worker nodes) as used in the tutorial [GitHub](https://github.com/kelseyhightower/kubernetes-the-hard-way).
It applies Microsoft best practices for Linux on Hyper‑V: Generation 2 VMs and tuned VHDX creation (1MB block size) [Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/best-practices-for-running-linux-on-hyper-v).
It also respects Debian support guidance for Hyper-V guests [Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-debian-virtual-machines-on-hyper-v) and uses the
`New-VHD` parameters documented in the Hyper-V PowerShell module [Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-debian-virtual-machines-on-hyper-v).

## Assumptions and variables

- **ISO path:** `E:\Hyper-V\ISOs\debian-12.12.0-amd64-netinst.iso` (as requested).
- **Storage root:** `E:\Hyper-V` (VHDs and VM configs).
- **Virtual switch:** script will use an existing External switch if present, otherwise create an Internal switch named `kthw-switch`.
- **Defaults:** controllers = 4GB/2 vCPU; workers = 2GB/2 vCPU; bastion = 2GB/2 vCPU (adjustable in variables).

## PowerShell 7 script

```powershell
# Requires: PowerShell 7, Hyper-V role installed, run as Administrator
$isoPath = "E:\Hyper-V\ISOs\debian-12.12.0-amd64-netinst.iso"
$storeRoot = "E:\Hyper-V"
$vhdFolder = Join-Path $storeRoot "VHDs"
$vmFolder = Join-Path $storeRoot "VMs"
New-Item -Path $vhdFolder, $vmFolder -ItemType Directory -Force | Out-Null

# Topology
$bastion = @{ Name = "bastion"; CPU = 2; MemoryGB = 2; DiskGB = 20 }
$controllers = 0..2 | ForEach-Object { @{ Name = "controller-$_" ; CPU = 2; MemoryGB = 4; DiskGB = 40 } }
$workers = 0..2 | ForEach-Object { @{ Name = "worker-$_"     ; CPU = 2; MemoryGB = 2; DiskGB = 40 } }
$nodes = @($bastion) + $controllers + $workers

# Ensure a virtual switch exists (prefer External)
$vSwitch = (Get-VMSwitch -SwitchType External -ErrorAction SilentlyContinue | Select-Object -First 1).Name
if (-not $vSwitch) {
    $vSwitch = "kthw-switch"
    if (-not (Get-VMSwitch -Name $vSwitch -ErrorAction SilentlyContinue)) {
        New-VMSwitch -Name $vSwitch -SwitchType Internal | Out-Null
    }
}

# Create VMs
$macPrefix = "00-15-5D"  # Hyper-V OUI
$index = 1
foreach ($node in $nodes) {
    $vmName = $node.Name
    $vhdPath = Join-Path $vhdFolder "$vmName.vhdx"
    $sizeBytes = [int64]$node.DiskGB * 1GB

    # Create VHDX with recommended block size and 4K physical sector
    New-VHD -Path $vhdPath -SizeBytes $sizeBytes -Dynamic -BlockSizeBytes 1MB -PhysicalSectorSizeBytes 4096

    # Create VM (Generation 2) and attach VHD
    New-VM -Name $vmName -MemoryStartupBytes ($node.MemoryGB * 1GB) -Generation 2 -VHDPath $vhdPath -SwitchName $vSwitch | Out-Null

    # CPU and network
    Set-VMProcessor -VMName $vmName -Count $node.CPU
    $mac = "{0}-{1:X2}-{2:X2}-{3:X2}" -f $macPrefix, ($index -band 0xFF), (($index -shr 8) -band 0xFF), (($index -shr 16) -band 0xFF)
    Set-VMNetworkAdapter -VMName $vmName -StaticMacAddress $mac

    # Attach ISO and set boot order to DVD first; enable Secure Boot with Linux template
    Add-VMDvdDrive -VMName $vmName -Path $isoPath
    $dvd = Get-VMDvdDrive -VMName $vmName
    Set-VMFirmware -VMName $vmName -BootOrder $dvd -EnableSecureBoot $true -SecureBootTemplate "MicrosoftUEFICertificateAuthority"

    # Increment index for MAC generation
    $index++
}

Write-Host "Provisioning complete. Start the VMs from Hyper-V Manager or use Start-VM <name>."
```

## Notes and references

- **Topology** follows Kubernetes the Hard Way layout [GitHub](https://github.com/kelseyhightower/kubernetes-the-hard-way).
- **Generation 2** and VHDX tuning (1MB block size) are Microsoft recommendations for Linux gueses [Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/best-practices-for-running-linux-on-hyper-v).
- **Debian** guidance for Hyper-V is noted in Microsoft docs; do not install the legacy Microsoft LIS package for supported Debian releases [Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-debian-virtual-machines-on-hyper-v).
- `New-VHD` parameters used are documented in the Hyper-V PowerShell module [Microsoft Learn](https://learn.microsoft.com/en-us/powershell/module/hyper-v/new-vhd).

Adjust CPU/memory/disk sizes to match your host capacity before running.

___

Response generated on 2025-11-07
