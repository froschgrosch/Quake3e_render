# Powershell application to aid in demo rendering.
# https://github.com/froschgrosch/quake3-scripts

$config = Get-Content .\zz_render\config.json | ConvertFrom-Json

$currentDuration = 0
$outputPath = $config.application.outputPath

# === CHECK SETTINGS ===

$echo = "mergeRender = " + $config.user.mergeRender + "; keepLog = " + $config.user.keepLog + "; ffmpegMode = " + $config.user.ffmpegMode + "; framerate = " + $config.user.framerate + "; renderScale = " + $config.user.renderScale.enabled
if ($config.user.renderScale.enabled) { $echo += "; resolution = " + $config.user.renderScale.resolution}
Write-Output "Starting quake3e_render.ps1 with the following settings:" $echo
do { $msgboxResult = Read-Host "Are those settings correct? (y/n) "} while(-not @("y","n").Contains($msgboxResult))
if ($msgboxResult -eq "n") { exit }
Write-Output " "

# === APPLICATION === 

if ($mergeRender){
    Remove-Item .\zz_render\merge_rendertemp\*.mp4
    
    if (Test-Path -PathType Leaf "$outputPath\merge_demolist.txt"){ Remove-Item "$outputPath\merge_demolist.txt" }
    Write-Output "ffconcat version 1.0" | Out-File -Encoding ascii .\zz_render\mergerenderlist.txt
}


:demoLoop foreach($file in $(Get-ChildItem .\render_input\ | Sort-Object -Property LastWriteTime)){

    $demoName = $file.Name.Remove($file.Name.Length - 6, 6)
    Write-Output "Demo: $demoName"

    # Skip conditions
    
    foreach ($skipKeyword in $config.application.skipKeywords){
        #Write-Output "checking for $skipKeyword"
        if ( $file.Name.StartsWith($skipKeyword) ){
            Write-Output "Contains ""$skipKeyword"", skipping..." " "
            continue demoLoop
        }
    }
  
    if ($(Test-Path -PathType Leaf "$outputPath\$demoName.mp4") -and -not $config.user.mergeRender) {

        do { $msgboxResult = Read-Host "This demo was already rendered at some point. Would you like to render again? (y/n)"} while(-not @("y","n").Contains($msgboxResult))

        if ($msgboxResult -eq "n"){
			Write-Output " "
            continue demoLoop
        } else {
            Remove-Item "$outputPath\$demoName.mp4"
        }
    }

    $demoData = .\zz_render\tools\UDT_json.exe -c "..\..\render_input\$demoName.dm_68" | ConvertFrom-Json
    $game = $demoData.gameStates[0].configStringValues.fs_game

    if (-not  $file.Extension -eq ".dm_68" -or -not $config.application.validGames.Contains($game)){
        Write-Output "Not a valid demo, skipping..." " "
        continue demoLoop
    }

    
    # Render
    $captureName = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 11 | ForEach-Object {[char]$_})
	
    if ($config.user.mergeRender) {
        Write-Output "file merge_rendertemp/$captureName.mp4" | Out-File -Append -Encoding ascii .\zz_render\mergerenderlist.txt
    }


    Write-Output "Rendering... (capturename: $captureName)"

    Copy-Item ".\render_input\$demoName.dm_68" ".\$game\demos\$captureName.dm_68"
    
    $q3e_args = @(
        "+set fs_game $game",
        "+set nextdemo quit",
        "+seta in_nograb 1",
        "+seta r_renderScale " +    $config.user.renderScale.enabled
        "+seta r_renderWidth " +    $config.user.renderScale.resolution[0],
        "+seta r_renderHeight " +   $config.user.renderScale.resolution[1],
        "+seta cl_aviPipeFormat " + $config.application.ffmpegPipeFormats[$config.user.ffmpegMode],
        "+seta cl_aviFrameRate " +  $config.user.framerate,
        "+demo $captureName",
        "+video-pipe $captureName"
    )

    $q3e_proc = Start-Process -PassThru -ArgumentList $q3e_args -FilePath .\quake3e.x64.exe

    $mins = $(Measure-Command {Wait-Process -InputObject $q3e_proc}).TotalMinutes


    Write-Output "Time in minutes: $mins" " "
    Start-Sleep 3
    
    if ($config.user.mergeRender){
        $ffprobeData = $(ffprobe -v error -hide_banner -of json -show_entries format ".\$game\videos\$captureName.mp4") | ConvertFrom-Json
        $timestamp = $("{0:hh\:mm\:ss}" -f $([timespan]::fromseconds($currentDuration)))

        Write-Output "$timestamp $demoName" | Out-File -Append .\zz_render\merge_demolist.txt

        $currentDuration += $ffprobeData.format.duration

        if (Test-Path -PathType Leaf "zz_render\merge_rendertemp\$captureName.mp4"){ Remove-Item  "zz_render\merge_rendertemp\$captureName.mp4" }
        Move-Item -Force ".\$game\videos\$captureName.mp4" "zz_render\merge_rendertemp\$captureName.mp4"

    } else {
        Move-Item -Force ".\$game\videos\$captureName.mp4" "$outputPath\$demoName.mp4"
    }
    
    if($config.user.keepLog -and -not $config.user.mergeRender){
        Move-Item -Force ".\$game\videos\$captureName.mp4-log.txt" "$outputPath\$demoName.log"
    } else {
        Remove-Item ".\$game\videos\$captureName.mp4-log.txt"
    }

    Remove-Item ".\$game\demos\$captureName.dm_68"
    #Remove-Item ".\render_input\$demoName.dm_68"

    Start-Sleep 3
}

# Merge with ffmpeg

if ($config.user.mergeRender){
    Write-Output "Merging with ffmpeg..."
    .\ffmpeg.exe -y -f concat -safe 0 -i zz_render\mergerenderlist.txt -c copy "$outputPath\merge_output.mp4"
    
    Move-Item .\zz_render\merge_demolist.txt "$outputPath\merge_demolist.txt"
    Remove-Item .\zz_render\mergerenderlist.txt
    Remove-Item .\zz_render\merge_rendertemp\*.mp4
}

Write-Output "Rendering finished."

#shutdown -s -t 60
pause
