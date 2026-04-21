$csv = Import-Csv -Path "C:\ansible\planets.csv"
$credFile = "C:\credentials\user_passwords.csv"
$domain = "BLUE1.local"
$accountsOU = "OU=Accounts,OU=BLUE1,DC=BLUE1,DC=LOCAL"
$groupsOU = "OU=Groups,OU=Accounts,OU=BLUE1,DC=BLUE1,DC=LOCAL"

"Username,Password,Group,Planet" | Out-File -FilePath $credFile -Encoding utf8 -Force

$groups = $csv | Select-Object -ExpandProperty Type -Unique
foreach ($group in $groups) {
    $groupName = $group -replace ' ', '-'
    $exists = Get-ADGroup -Filter { Name -eq $groupName } -ErrorAction SilentlyContinue
    if (-not $exists) {
        New-ADGroup `
            -Name $groupName `
            -GroupScope Global `
            -GroupCategory Security `
            -Path $groupsOU `
            -Description "Planet type: $group"
        Write-Host "Created group: $groupName"
    } else {
        Write-Host "Group already exists: $groupName"
    }
}

foreach ($row in $csv) {
    $planetName = $row."Planet Name"
    $type = $row.Type
    $groupName = $type -replace ' ', '-'

    $username = $planetName -replace '[^a-zA-Z0-9]', ''
    $password = $planetName.Replace(' ', '') + '!'
    $securePass = ConvertTo-SecureString $password -AsPlainText -Force

    $exists = Get-ADUser -Filter { SamAccountName -eq $username } -ErrorAction SilentlyContinue
    if (-not $exists) {
        New-ADUser `
            -Name $planetName `
            -SamAccountName $username `
            -UserPrincipalName "$username@$domain" `
            -Path $accountsOU `
            -AccountPassword $securePass `
            -Enabled $true
        Write-Host "Created user: $username"
    } else {
        Write-Host "User already exists: $username"
    }

    try {
        Add-ADGroupMember -Identity $groupName -Members $username
        Write-Host "Added $username to $groupName"
    } catch {
        Write-Host "Could not add $username to $groupName : $_"
    }

    "$username,$password,$groupName,$planetName" | Out-File -FilePath $credFile -Encoding utf8 -Append
}

Write-Host "Done! Credentials saved to $credFile"
