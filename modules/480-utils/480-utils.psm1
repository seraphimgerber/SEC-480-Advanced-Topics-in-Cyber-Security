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

function New-Network([string] $esxi, [string] $switchName, [string] $portGroupName) {

    do {
        $vmhost = Get-VMHost -Name $esxi -ErrorAction SilentlyContinue
        if (-not $vmhost) {
            Write-Host -ForegroundColor Red "ESXi host '$esxi' not found. Try again."
            $esxi = Read-Host "Enter ESXi host"
        }
    } while (-not $vmhost)

    $vswitch = Get-VirtualSwitch -VMHost $vmhost -Name $switchName -ErrorAction SilentlyContinue
    if (-not $vswitch) {
        $vswitch = New-VirtualSwitch -VMHost $vmhost -Name $switchName
        Write-Host -ForegroundColor Green "Virtual switch '$switchName' created."
    } else {
        Write-Host -ForegroundColor Yellow "Virtual switch '$switchName' already exists."
    }

    $pg = Get-VirtualPortGroup -VMHost $vmhost -Name $portGroupName -ErrorAction SilentlyContinue
    if (-not $pg) {
        New-VirtualPortGroup -VirtualSwitch $vswitch -Name $portGroupName | Out-Null
        Write-Host -ForegroundColor Green "Port group '$portGroupName' created on '$switchName'."
    } else {
        Write-Host -ForegroundColor Yellow "Port group '$portGroupName' already exists."
    }
}

function Get-IP([string] $vmName) {

    do {
        $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host -ForegroundColor Red "VM '$vmName' not found. Try again."
            $vmName = Read-Host "Enter VM name"
        }
    } while (-not $vm)

    $adapter = Get-NetworkAdapter -VM $vm | Select-Object -First 1
    $ip = $vm.Guest.IPAddress[0]

    if ($adapter) {
        Write-Host -ForegroundColor Green "VM:  $($vm.Name)"
        Write-Host -ForegroundColor Green "MAC: $($adapter.MacAddress)"
        Write-Host -ForegroundColor Green "IP:  $ip"
    } else {
        Write-Host -ForegroundColor Red "No network adapter found on '$vmName'."
    }
}

function Start-MyVM([string] $vmName) {

    do {
        $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host -ForegroundColor Red "VM '$vmName' not found. Try again."
            $vmName = Read-Host "Enter VM name"
        }
    } while (-not $vm)

    if ($vm.PowerState -eq "PoweredOn") {
        Write-Host -ForegroundColor Yellow "VM '$vmName' is already powered on."
    } else {
        Start-VM -VM $vm | Out-Null
        Write-Host -ForegroundColor Green "VM '$vmName' has been powered on."
    }
}

function Stop-MyVM([string] $vmName) {

    do {
        $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host -ForegroundColor Red "VM '$vmName' not found. Try again."
            $vmName = Read-Host "Enter VM name"
        }
    } while (-not $vm)

    if ($vm.PowerState -eq "PoweredOff") {
        Write-Host -ForegroundColor Yellow "VM '$vmName' is already powered off."
    } else {
        Stop-VM -VM $vm -Confirm:$false | Out-Null
        Write-Host -ForegroundColor Green "VM '$vmName' has been powered off."
    }
}

function Set-Network([string] $vmName, [string] $network, [int] $adapterIndex = 0) {

    do {
        $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host -ForegroundColor Red "VM '$vmName' not found. Try again."
            $vmName = Read-Host "Enter VM name"
        }
    } while (-not $vm)

    do {
        $net = Get-VirtualNetwork -Name $network -ErrorAction SilentlyContinue
        if (-not $net) {
            Write-Host -ForegroundColor Red "Network '$network' not found. Try again."
            $network = Read-Host "Enter network name"
        }
    } while (-not $net)

    $adapter = Get-NetworkAdapter -VM $vm | Select-Object -Index $adapterIndex
    if (-not $adapter) {
        Write-Host -ForegroundColor Red "No adapter found at index $adapterIndex on '$vmName'."
        return
    }

    Set-NetworkAdapter -NetworkAdapter $adapter -NetworkName $network -Confirm:$false | Out-Null
    Write-Host -ForegroundColor Green "Adapter $adapterIndex on '$vmName' set to '$network'."
}

function Set-WindowsIP([string] $vmName, [string] $ip, [string] $subnet, [string] $gateway, [string] $dns, [string] $guestUser) {

    do {
        $vm = Get-VM -Name $vmName -ErrorAction SilentlyContinue
        if (-not $vm) {
            Write-Host -ForegroundColor Red "VM '$vmName' not found. Try again."
            $vmName = Read-Host "Enter VM name"
        }
    } while (-not $vm)

    $securePass = Read-Host "Enter guest password for '$vmName'" -AsSecureString
    $plainPass = [System.Net.NetworkCredential]::new("", $securePass).Password

   $script = "netsh interface ip set address name=`"Ethernet0 2`" static $ip $subnet $gateway`nnetsh interface ip set dns name=`"Ethernet0 2`" static $dns"
    Invoke-VMScript -VM $vm -ScriptText $script -GuestUser $guestUser -GuestPassword $plainPass -ScriptType Bat
    Write-Host -ForegroundColor Green "Static IP $ip set on '$vmName'."
}
