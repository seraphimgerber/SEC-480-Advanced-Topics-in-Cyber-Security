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

function Get-480Config([string] $config_path)
{
    Write-Host "Reading " $config_path
    $conf=$null
    if(Test-Path $config_path)
    {
        $conf = (Get-Content -Raw -Path $config_path | ConvertFrom-Json)
        $msg = "Using Configuration at {0}" -f $config_path
        Write-Host -ForegroundColor Green $msg
    } else {
        Write-Host -ForegroundColor Yellow "No configuration"
    }
    return $conf
}

function select-vm([string] $folder)