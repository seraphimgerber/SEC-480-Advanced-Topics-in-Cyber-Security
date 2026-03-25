Import-Module '/home/xubuntu/SEC-480-Advanced-Topics-in-Cyber-Security/modules/480-utils' -Force
$vmName = Read-Host "Enter the name of the VM to clone"
$snapshotName = Read-Host "Enter the snapshot name [Base]"
if ([string]::IsNullOrWhiteSpace($snapshotName)) { $snapshotName = "Base" }
$newName = Read-Host "Enter the name for the new VM"
$esxi = Read-Host "ESXi host [192.168.3.210]"
if ([string]::IsNullOrWhiteSpace($esxi)) { $esxi = "192.168.3.210" }
$datastore = Read-Host "Datastore [datastore2-super10]"
if ([string]::IsNullOrWhiteSpace($datastore)) { $datastore = "datastore2-super10" }
$network = Read-Host "Network [480-WAN]"
if ([string]::IsNullOrWhiteSpace($network)) { $network = "480-WAN" }

$clone_type = Read-Host "Clone type? 'F'ull or 'L'inked"
while ($clone_type -ne 'F' -and $clone_type -ne 'L') {
    $clone_type = Read-Host "Invalid. Enter 'F' or 'L'"
}

if ($clone_type -eq 'L') {
    New-LinkedClone -vmName $vmName -snapshotName $snapshotName -newName $newName -esxi $esxi -datastore $datastore -network $network
} elseif ($clone_type -eq 'F') {
    New-FullClone -vmName $vmName -snapshotName $snapshotName -newName $newName -esxi $esxi -datastore $datastore -network $network
}
