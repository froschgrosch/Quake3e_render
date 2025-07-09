. .\functions.ps1

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

:transcodingLoop foreach ($demo in $demoList){
    $cleanName = $demo.Name.Replace('.dm_68','')

    if ($demo.transcoded) { # demo was already transcoded
        Write-Output "Skipping $cleanName... (was already transcoded earlier)"
        continue :transcodingLoop
    }
    Write-Output "Now transcoding $cleanName..."

    $fs_game = $demo.fs_game
    $tempName = $demo.tempName
    # swap config if applicable (to be implemented)

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
# clean up config (to be implemented)

Remove-Item .\zz_transcode\demoList.json
Write-Output ' ' 'Demo transcoding is finished.'
pause
