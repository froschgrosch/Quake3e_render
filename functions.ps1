### Functions ###
function Get-UserConfirmation($prompt){ # Do a yes/no query and return $true/$false 
    do { 
        $msgboxResult = Read-Host "$prompt (y/n)"
    } while(-not @('y','n').Contains($msgboxResult))

    return $msgboxResult -eq 'y'
}
function Read-Json ($inputPath) {
    return Get-Content $inputPath | ConvertFrom-Json
}

function Add-ToObject ($inputObject, $name, $value) {
    Add-Member -Force -InputObject $inputObject -MemberType NoteProperty -Name $name -Value $value
}

function Add-NewProperty ($inputObject, $name){
    Add-ToObject $inputObject -name $name -value (New-Object -TypeName 'PSObject')
}

function Show-DemoList ($list) {
    $list | Select-Object -Property '*' -ExcludeProperty @('transcoded','stopAfterCurrent') | Format-Table
}
