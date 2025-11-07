<#
------------------------------------------------------------------------------------------------------------------
Grade: **** (4/5)
Summary: Great framework, but has at least one significant error.

Script Feedback:

    The script has two main issues: hardcoded paths and a misuse of the Set-VMFirmware cmdlet.  Those are annotated
below with individual commentary.

    This script could be improved with checking for existence of the VMs and VHDs before attempting to create them.
As it stands, re-running the script will result in errors if either already exist.  Adding checks and handling
those cases would make the script more robust.

    Since this script is intended to be run "once" to provision a set of VMs, I see no reason to not check for and 
prompt for deletion of existing VMs/VHDs if they are pre-existing.

    In a similar vein, the output is nullified in several places, but not when creating the VHDs.  For consistency,
I would nullify everything and provide a summary at the end or return a PowerShell object representing the created VMs.
The added benefit here is two-fold:
    1) The output could be used to "undo" the provisioning with Remove-VM for the VMs and
       Remove-Item for the VHDs.
    2) The output of the VMs could be used to easily start the VMs with Start-VM.

    The script doesn't address snapshots at all.  I'm not a fan of automatic snapshotting and prefer to disable it.

    Although the naming is good for the roles of the VMs, adding a prefix would help visibility within the Hyper-V Manager.

Style:
    As a personal preference, I do not like camel-case variable names in PowerShell scripts.  I prefer
using title case as it's more in line with the PowerShell cmdlet naming conventions and what I've
seen in most PowerShell scripts.  In reality, this is a minor stylistic point.

    Similarly, I prefer to use the full parameter names instead of relying on positional parameters. Again, 
this is a stylistic point, but I believe it provides better readability and offers better for educational purposes.

#>


# Requires: PowerShell 7, Hyper-V role installed, run as Administrator
$isoPath = "E:\Hyper-V\ISOs\debian-12.12.0-amd64-netinst.iso"
<# 
Original:

$storeRoot = "E:\Hyper-V"
$vhdFolder = Join-Path $storeRoot "VHDs"
$vmFolder = Join-Path $storeRoot "VMs"
New-Item -Path $vhdFolder, $vmFolder -ItemType Directory -Force | Out-Null

Commentary
    Arbitrarily creating a set of folders for the virtual machines and virtual hard disks is bad form.  This information
is already stored in the VMHost information.  A better approach would be to query the VMHost for its default paths
and use those paths instead of hardcoding them.

    The vmFolder variable is not used in the script, so it can be removed entirely.

Replacement:
#>

$vmHost = Get-VMHost
$vhdFolder = $vmHost.VirtualHardDiskPath

<# end commentary #>

# Topology
<# Original:

$bastion = @{ Name = "bastion"; CPU = 2; MemoryGB = 2; DiskGB = 20 }
$controllers = 0..2 | ForEach-Object { @{ Name = "controller-$_" ; CPU = 2; MemoryGB = 4; DiskGB = 40 } }
$workers = 0..2 | ForEach-Object { @{ Name = "worker-$_"     ; CPU = 2; MemoryGB = 2; DiskGB = 40 } }
$nodes = @($bastion) + $controllers + $workers

Commentary:
    The names are funcitonal, but adding a prefix would help grouping and identification within Hyper-V Manager.

Replacement:
#>

$vmPrefix = "kthw-"
$bastion = @{ Name = "$( $vmPrefix )bastion"; CPU = 2; MemoryGB = 2; DiskGB = 20 }
$controllers = 0..2 | ForEach-Object { @{ Name = "$( $vmPrefix )controller-$_" ; CPU = 2; MemoryGB = 4; DiskGB = 40 } }
$workers = 0..2 | ForEach-Object { @{ Name = "$( $vmPrefix )worker-$_"     ; CPU = 2; MemoryGB = 2; DiskGB = 40 } }
$nodes = @($bastion) + $controllers + $workers

<# end commentary #>

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

    <# Original: 
    # Create VHDX with recommended block size and 4K physical sector
    New-VHD -Path $vhdPath -SizeBytes $sizeBytes -Dynamic -BlockSizeBytes 1MB -PhysicalSectorSizeBytes 4096

    # Create VM (Generation 2) and attach VHD
    New-VM -Name $vmName -MemoryStartupBytes ($node.MemoryGB * 1GB) -Generation 2 -VHDPath $vhdPath -SwitchName $vSwitch | Out-Null

    Commentary:
        Why are we not capturing the output of the New-VHD and using it in the New-VM?  We should be.  If we do this,
    then we can just output the VM object at the end of the script.

    Replacement:
    #>

    # Create VHDX with recommended block size and 4K physical sector
    $vhd = New-VHD -Path $vhdPath -SizeBytes $sizeBytes -Dynamic -BlockSizeBytes 1MB -PhysicalSectorSizeBytes 4096

    # Create VM (Generation 2) and attach VHD
    New-VM -Name $vmName -MemoryStartupBytes ($node.MemoryGB * 1GB) -Generation 2 -VHDPath $vhd.Path -SwitchName $vSwitch


    # CPU and network
    Set-VMProcessor -VMName $vmName -Count $node.CPU
    $mac = "{0}-{1:X2}-{2:X2}-{3:X2}" -f $macPrefix, ($index -band 0xFF), (($index -shr 8) -band 0xFF), (($index -shr 16) -band 0xFF)
    Set-VMNetworkAdapter -VMName $vmName -StaticMacAddress $mac

    # Attach ISO and set boot order to DVD first; enable Secure Boot with Linux template
    Add-VMDvdDrive -VMName $vmName -Path $isoPath
    $dvd = Get-VMDvdDrive -VMName $vmName
    
    <# Original:
    Set-VMFirmware -VMName $vmName -BootOrder $dvd -EnableSecureBoot $true -SecureBootTemplate "MicrosoftUEFICertificateAuthority"

    Commentary:
        The Set-VMFirmware's EnableSecureBoot parameter does not accept $true or $false.  It requires "on" or "off".

    Replacement:
    #>

    Set-VMFirmware -VMName $vmName -BootOrder $dvd -EnableSecureBoot On -SecureBootTemplate "MicrosoftUEFICertificateAuthority"

    <# end commentary #>

    <# Commentary:
        We are completely ignoring automatic snapshots here and I would disable them.
    
    Replacement:
    #>

    Set-Vm -Name $vmName -AutomaticCheckpointsEnabled $false

    <# end commentary #>

    # Increment index for MAC generation
    $index++
}

Write-Host "Provisioning complete. Start the VMs from Hyper-V Manager or use Start-VM <name>."