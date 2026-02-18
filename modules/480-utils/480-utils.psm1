function 480Banner()
{  
    Write-Host "Hello 480!"
}

function 480Connect([string] $server)
{
    $conn = $global:DefaultVIServer
    #checking if we are already connected
    if ($conn){
        $msg = "Already connected to: {0}" -f $conn

        Write-Host -ForegroundColor Green $msg
    }else {
        $conn = Connect-VIServer -Server $server
        #if check fails, Connect-VIServer handles exception
    }
}

function New-LinkedClone([string] $vmName, [string] $snapshotName, [string] $newName, [string] $esxi, [string] $datastore, [string] $network) {
    
    do {
        $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host -ForegroundColor Red "VM '$vmName' not found. Try again."
            $vmName = Read-Host "Enter VM name"
        }
    } while (-not $vm)

    do {
        $snapshot = Get-Snapshot -VM $vm -Name $snapshotName -ErrorAction SilentlyContinue
        if (-not $snapshot) {
            Write-Host -ForegroundColor Red "Snapshot '$snapshotName' not found. Try again."
            $snapshotName = Read-Host "Enter snapshot name"
        }
    } while (-not $snapshot)

    do {
        $ds = Get-Datastore -Name $datastore -ErrorAction SilentlyContinue
        if (-not $ds) {
            Write-Host -ForegroundColor Red "Datastore '$datastore' not found. Try again."
            $datastore = Read-Host "Enter datastore name"
        }
    } while (-not $ds)

    do {
        $vmhost = Get-VMHost -Name $esxi -ErrorAction SilentlyContinue
        if (-not $vmhost) {
            Write-Host -ForegroundColor Red "ESXi host '$esxi' not found. Try again."
            $esxi = Read-Host "Enter ESXi host"
        }
    } while (-not $vmhost)

    do {
        $net = Get-VirtualNetwork -Name $network -ErrorAction SilentlyContinue
        if (-not $net) {
            Write-Host -ForegroundColor Red "Network '$network' not found. Try again."
            $network = Read-Host "Enter network name"
        }
    } while (-not $net)

    $newvm = New-VM -LinkedClone -Name $newName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
    $newvm | New-Snapshot -Name "base"
    Get-NetworkAdapter -VM $newvm | Remove-NetworkAdapter -Confirm:$false
    New-NetworkAdapter -VM $newvm -NetworkName $network -StartConnected -Type Vmxnet3
    Write-Host -ForegroundColor Green "Linked clone '$newName' created."
}

function New-FullClone([string] $vmName, [string] $snapshotName, [string] $newName, [string] $esxi, [string] $datastore, [string] $network) {

    do {
        $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host -ForegroundColor Red "VM '$vmName' not found. Try again."
            $vmName = Read-Host "Enter VM name"
        }
    } while (-not $vm)

    do {
        $snapshot = Get-Snapshot -VM $vm -Name $snapshotName -ErrorAction SilentlyContinue
        if (-not $snapshot) {
            Write-Host -ForegroundColor Red "Snapshot '$snapshotName' not found. Try again."
            $snapshotName = Read-Host "Enter snapshot name"
        }
    } while (-not $snapshot)

    do {
        $ds = Get-Datastore -Name $datastore -ErrorAction SilentlyContinue
        if (-not $ds) {
            Write-Host -ForegroundColor Red "Datastore '$datastore' not found. Try again."
            $datastore = Read-Host "Enter datastore name"
        }
    } while (-not $ds)

    do {
        $vmhost = Get-VMHost -Name $esxi -ErrorAction SilentlyContinue
        if (-not $vmhost) {
            Write-Host -ForegroundColor Red "ESXi host '$esxi' not found. Try again."
            $esxi = Read-Host "Enter ESXi host"
        }
    } while (-not $vmhost)

    do {
        $net = Get-VirtualNetwork -Name $network -ErrorAction SilentlyContinue
        if (-not $net) {
            Write-Host -ForegroundColor Red "Network '$network' not found. Try again."
            $network = Read-Host "Enter network name"
        }
    } while (-not $net)

    $tempName = "{0}.linked-temp" -f $vmName
    $linkedvm = New-VM -LinkedClone -Name $tempName -VM $vm -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $ds
    $newvm = New-VM -Name $newName -VM $linkedvm -VMHost $vmhost -Datastore $ds
    $newvm | New-Snapshot -Name "base"
    $linkedvm | Remove-VM -Confirm:$false
    Get-NetworkAdapter -VM $newvm | Remove-NetworkAdapter -Confirm:$false
    New-NetworkAdapter -VM $newvm -NetworkName $network -StartConnected -Type Vmxnet3
    Write-Host -ForegroundColor Green "Full clone '$newName' created."
}
