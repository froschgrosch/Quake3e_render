. .\functions.ps1

function Set-ConfigFile ($i, $gamename) {
    # index of -1 is the q3config.cfg that is already installed beforehand

    if ($i -eq $currentConfigFiles.$gamename) { # no need to change anything
        #Write-Output "Correct file $i already in place, nothing to swap!"
        return
    }
    elseif ($i -eq -1) { # put back old config
        #Write-Output 'Put back old config (-1)'
        if (Test-Path -PathType Leaf -Path ".\$gamename\q3config.cfg.bak"){
            Remove-Item -Path ".\$gamename\q3config.cfg"
            Rename-Item -Path ".\$gamename\q3config.cfg.bak" -NewName 'q3config.cfg'
        }    
        $currentConfigFiles.$gamename = -1
    }
    elseif ($i -ge 0 -and $gamename -eq $config.configSwapping.list[$i][1]) { # if requested config file is valid for game, proceed with swapping
        #Write-Output "Put config $i"
        if (-not (Test-Path -PathType Leaf -Path ".\$gamename\q3config.cfg.bak")){
            Rename-Item -Path ".\$gamename\q3config.cfg" -NewName 'q3config.cfg.bak'
        }
        $cfgname = $config.configSwapping.list[$i][0]
        Copy-Item -Path ".\zz_config\q3cfg\$gamename\$cfgname.cfg" -Force -Destination ".\$gamename\q3config.cfg"

        $currentConfigFiles.$gamename = $i
    }
}

# check if a list was already created
if (-not (Test-Path -PathType Leaf -Path '.\zz_transcode\demoList.json')){
    Write-Output 'ERROR: No demo list found!' 'Please create one using ".\prepare.ps1".' ' '
    pause
    exit 1
}

$demoList = Read-Json .\zz_transcode\demoList.json

# display and confirm demo list
Write-Output 'The following list of demos will be transcoded.'
Show-DemoList $($demoList | Where-Object -Property 'transcoded' -eq $false) -ExcludeProperty @('transcoded')
if (-not (Get-UserConfirmation 'Do you want to continue?')){
    exit 0
}


$config = Read-Json .\zz_config\transcode.json

# check if the q3 config files have already been modified
if ($config.configSwapping.enabled) {
    if (Test-Path -PathType Leaf -Path '.\zz_transcode\currentConfigFiles.json') { # use existing file
        $currentConfigFiles = Read-Json '.\zz_transcode\currentConfigFiles.json'
    }
    else { # create new one
        $currentConfigFiles = New-Object -TypeName PSCustomObject
        foreach ($game in $config.configSwapping.allowedGames) {
            Add-ToObject -inputObject $currentConfigFiles -name $game -value (-1)
        }
        $currentConfigFiles | ConvertTo-Json | Out-File -Force .\zz_transcode\currentConfigFiles.json
    }
}

:transcodingLoop foreach ($demo in $demoList){
    $cleanName = $demo.Name.Replace('.dm_68','')

    if ($demo.transcoded) { # demo was already transcoded
        Write-Output "Skipping $cleanName... (was already transcoded earlier)"
        continue :transcodingLoop
    }
    Write-Output "Now transcoding $cleanName..."

    $fs_game = $demo.fs_game
    $tempName = $demo.tempName
    
    # swap config if applicable
    if ($config.configSwapping.enabled){
        Set-ConfigFile $demo.renderConfig $fs_game
        $currentConfigFiles | ConvertTo-Json | Out-File -Force .\zz_transcode\currentConfigFiles.json
    }
    
    Copy-Item -Force -Path ".\zz_transcode\input\$cleanName.dm_68" -Destination ".\$fs_game\demos\$tempName.dm_68"

    $q3e_args = @(
        "+set fs_game $fs_game",
        '+set nextdemo quit',
        '+set in_nograb 1',
        "+demo $tempName"
        "+video-pipe $tempName"
    )
    
    Start-Process -Wait -ArgumentList $q3e_args -FilePath .\quake3e.x64.exe
    
    Remove-Item ".\$fs_game\demos\$tempName.dm_68"
    Remove-Item ".\$fs_game\videos\$tempName.mp4-log.txt"
    Move-Item ".\$fs_game\videos\$tempName.mp4" ".\zz_transcode\output\$cleanName.mp4"

    $demo.transcoded = $true

    # mark demo as finished
    $demoList | ConvertTo-Json | Out-File .\zz_transcode\demoList.json
    if ($demo.stopAfterCurrent){
        # todo: implement other options (shutdown etc.)
        exit
    }
}

# clean up swapped config files
# todo - possible improvement: only clean up files that were actually changed

if ($config.configSwapping.enabled) {
    foreach($game in $config.configSwapping.allowedGames) {
        #Write-Output "cleanup $game"
        Set-ConfigFile (-1) $game
    }
    Remove-Item .\zz_transcode\currentConfigFiles.json
}

Remove-Item .\zz_transcode\demoList.json
Write-Output ' ' 'Demo transcoding is finished.'
pause
