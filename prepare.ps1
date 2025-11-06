###################################################################
# Quake3e_Render - https://github.com/froschgrosch/Quake3e_render #
# Licensed under GNU GPLv3. - File: prepare.ps1                   #
###################################################################

. .\functions.ps1
## PROGRAM START ##

$config = Read-Json .\zz_config\prepare.json

# check if a list was already created
if (Test-Path -PathType Leaf -Path '.\zz_transcode\demoList.json'){
    $demoList = Read-Json .\zz_transcode\demoList.json

    Write-Output 'The following demo list was already created earlier.'
    Show-DemoList $demoList

    if(Get-UserConfirmation 'Do you want to create a new one?'){
        Remove-Item .\zz_transcode\demoList.json
    }
    else {
        exit
    }
}

# create empty array
$demoList = @()

$inputFiles = Get-ChildItem  .\zz_transcode\input | Where-Object -Property Extension -EQ '.dm_68'

if ($null -eq $inputFiles) {
    Write-Output 'ERROR: No valid input files found!' 'Please check .\zz_transcode\input\'
    pause
    exit
}

:preparationLoop foreach ($file in $inputFiles) {
    Write-Output "Checking $($file.name)..."
    
    # check if video already exists
    $outputPathName = ".\zz_transcode\output_video\$($file.Name.Replace('.dm_68','.mp4'))"
    if (Test-Path -PathType Leaf -Path $outputPathName) {
        if (Get-UserConfirmation 'This demo was already transcoded at some point. Would you like to transcode it again?'){
            Remove-Item $outputPathName
        }
        continue :demoLoop
    }

    # check if fs_game is valid
    $udtoutput = $(.\zz_tools\UDT_json.exe -a=g -c "..\zz_transcode\input\$file" | ConvertFrom-Json).gamestates[0]
    $fs_game = $udtoutput.configStringValues.fs_game
    if (-not $config.games.allowed.Contains($fs_game)) {
        Write-Output """$fs_game"" is not a valid game!" ' '
        continue :demoLoop
    }

    # demo is valid, ready for further processing
    Write-Output 'Adding to renderlist.' ' '
    
    $demoObject = New-Object -TypeName PSObject
    #static values
    Add-ToObject $demoObject 'transcoded' $false
    Add-ToObject $demoObject 'stopAfterCurrent' $false
    Add-ToObject $demoObject 'renderConfig' $config.games.defaultConfig.$fs_game

    #dynamic values
    Add-ToObject $demoObject 'name'     $file.Name
    Add-ToObject $demoObject 'tempName' $(-join $((48..57) + (65..90) + (97..122) | Get-Random -Count 11 | ForEach-Object {[char]$_}))
    Add-ToObject $demoObject 'fs_game'  $fs_game

    # add demo to list
    $demoList += $demoObject
}

$demoList | ConvertTo-Json | Out-File .\zz_transcode\demoList.json

Write-Output 'Demo preprocessing is finished.' 'Please check the final output:'
Show-DemoList $demoList -ExcludeProperty @('transcoded','stopAfterCurrent')
pause
