<#
Removal / Reset Script for the copilot-thinkdepper script
#>
$VMNames  = "bastion", "controller-0", "controller-1", "controller-2", "worker-0", "worker-1", "worker-2"
$VMNames += "kthw-*"

$VMs = Get-VM -Name $VMNames -ErrorAction SilentlyContinue
( $VMs ).HardDrives.Path | ForEach-Object { Remove-Item -Path $_ -Force -ErrorAction SilentlyContinue }
$VMs | Remove-VM -Force -ErrorAction SilentlyContinue
