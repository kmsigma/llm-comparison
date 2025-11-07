# ChatGPT Response
Here is a PowerShell 7 script that will create one or more VMs in Hyper‑V on Windows, set them to boot from the Debian ISO located at `E:\Hyper-V\ISOs\debian-12.12.0-amd64-netinst.iso`, and apply recommended settings for Linux VMs per the Microsoft documentation (for example using Gen2, disable secure boot, use a SCSI controller for the VHDX, use a “Hyper-V” synthetic network adapter, etc.). I’ll include comments so you can adjust names, counts, sizing, etc.

**Important:** This script provides the VM provisioning portion only. It does not install Kubernetes or configure the VMs for the Kubernetes the Hard Way procedure from kubernetes‑the‑hard‑way — it simply provisions the virtual machines to then boot the Debian installer.

Also ensure you run PowerShell 7 *as Administrator* and that the Hyper-V role is installed and your host machine has sufficient resources.

```powershell
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
```

## Notes & Explanation of key settings:

- We are choosing Generation 2 VMs (`-Generation 2`) which is recommended for modern Linux on Hyper-V (but some older distributions may require Gen1). The Microsoft doc notes that some Linux installs on Gen2 may require disabling Secure Boot. 
Microsoft Learn
+1

- We disable Secure Boot for Gen2 VMs (`Set-VMFirmware … -EnableSecureBoot Off`) to avoid boot issues with unsupported Secure Boot templates for Linux. [Microsoft Learn (1)](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-ubuntu-virtual-machines-on-hyper-v?utm_source=chatgpt.com) [Microsoft Learn (2)](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/best-practices-for-running-linux-on-hyper-v?utm_source=chatgpt.com)

- We give each VM a synthetic network adapter (not legacy) as recommended for Linux guests on Hyper-V. [Microsoft Learn (1)](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/supported-ubuntu-virtual-machines-on-hyper-v?utm_source=chatgpt.com) [Microsoft Learn (2)](https://learn.microsoft.com/en-us/troubleshoot/windows-server/virtualization/linux-virtual-machine-issue-hyper-v?utm_source=chatgpt.com)

- We use a fixed size VHDX (via `-NewVHDSizeBytes`) – though dynamic is fine, Microsoft indicates for performance you might choose fixed. [Microsoft Learn (1)](https://learn.microsoft.com/en-us/windows-server/administration/performance-tuning/role/hyper-v-server/linux-virtual-machine-considerations?utm_source=chatgpt.com) [Microsoft Learn (2)](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/best-practices-for-running-linux-on-hyper-v?utm_source=chatgpt.com)
- We attach the ISO via `Add-VMDvdDrive` so the VM boots the installer.
- The script sets automatic start/stop behavior which is optional but helpful.
- You’ll need to adjust memory, CPU, disk size, switch name, etc. to match your host hardware and networking environment.

## To adapt for the “Kubernetes the Hard Way” scenario:

- The repo from Kelsey Hightower describes using four machines (1 jump/control + 3 worker). [GitHub](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- You might want naming like `k8s-jump`, `k8s-control`, `k8s-worker1`, `k8s-worker2`. You can adapt the naming logic accordingly or call the script multiple times with different prefixes.
- After installation of Debian on each VM, you’ll follow the Kubernetes-the-Hard-Way instructions manually or via your automation pipeline.
