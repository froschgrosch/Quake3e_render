# Powershell application to aid in demo rendering.
# https://github.com/froschgrosch/quake3-scripts


# === FUNCTION DECLARATIONS ===
function truncateFilename($file) { # Remove the extension from the filename string 
    return $file.Name.Remove($file.Name.Length - $file.Extension.Length, $file.Extension.Length);
}

function YNquery($prompt){ # Do a yes/no query and return $true/$false 
    do { 
        $msgboxResult = Read-Host "$prompt (y/n) "
    } while(-not @("y","n").Contains($msgboxResult))

    if ($msgboxResult -eq "y"){
        return $true; 
    } else {
        return $false;
    }
}

function randomAlphanumeric($length){ # return a random alphanumeric string 
    # Characters:
    # ABCDEFGHIJKLMNOPQRSTUVWYXZabcdefghijklmnopqrstuvwxyz0123456789
    return -join ((48..57) + (65..90) + (97..122) | Get-Random -Count $length | ForEach-Object {[char]$_});
}

function writeSession { # Saves the current session to a json file 
    ConvertTo-Json -InputObject $session | Out-File .\zz_render\session.json
}


# loading config
$config = Get-Content .\zz_render\config.json | ConvertFrom-Json
$outputPath = $config.application.outputPath

$echo = "mergeRender = " + $config.user.mergeRender + "; keepFFmpegLogs = " + $config.user.keepFFmpegLogs + "; ffmpegMode = " + $config.user.ffmpegMode + "; framerate = " + $config.user.framerate + "; renderScale = " + $config.user.renderScale.enabled
if ($config.user.renderScale.enabled) { $echo += "; resolution = " + $config.user.renderScale.resolution}
Write-Output "Starting quake3e_render.ps1 with the following settings:" $echo
if ( -not $(YNquery("Are those settings correct?"))) { exit }
Write-Output " "

# === APPLICATION === 

if ($mergeRender){
    Remove-Item .\zz_render\temp\merge\*.mp4
    
    if (Test-Path -PathType Leaf "$outputPath\merge_demolist.txt"){ Remove-Item "$outputPath\merge_demolist.txt" }
    Write-Output "ffconcat version 1.0" | Out-File -Encoding ascii .\zz_render\mergerenderlist.txt
}

$skipRenderListCreation = $false
# Try to read existing session
if (Test-Path -PathType Leaf .\zz_render\session.json) {
    $session = Get-Content .\zz_render\session.json |  ConvertFrom-Json
    $skipRenderListCreation = $true
} else {
    $session = New-Object -TypeName PSObject
    $temp_date = New-Object -TypeName PSObject

    Add-Member -InputObject $temp_date -MemberType NoteProperty -Name start -Value $(Get-Date)
    Add-Member -InputObject $session -MemberType NoteProperty -Name date -Value $temp_date
}

# == Demo List Creation == 
Write-Output "Creating renderlist..." " "

$temp_firstdemo = $true
:createRenderList foreach($file in $(Get-ChildItem .\render_input\ | Sort-Object -Property LastWriteTime)){
    if ($skipRenderListCreation) {
        Write-Output "session.json found, skipping renderlist creation..."
        break
    } 
    
    Write-Output $(-join ("Checking """, $file.name, """..."))
    
    # Check if demo format (extension) is valid
    if ( !$($config.application.validDemoFormats.Contains($file.Extension))  ) {
        Write-Output $(-join("""", $file.Extension, """ is not a valid demo format, skipping..."))
        continue createRenderList
    }

    $temp_demoName = truncateFilename($file)

    # Check for skipKeywords
    foreach ($j in $config.application.skipKeywords){
        if ( $file.name.StartsWith($j) ){
            Write-Output "Contains ""$j"", skipping..."
            continue createRenderList
        }
    }
  
    # Check if demo was already rendered
    if ($(Test-Path -PathType Leaf "$outputPath\$temp_demoName.mp4") -and -not $config.user.mergeRender) {
        if (YNquery("This demo was already rendered at some point. Would you like to render again?")){
            Remove-Item "$outputPath\$temp_demoName.mp4"
        } else {
            Write-Output " "
            continue createRenderList
        }
    }

    $udtFilename = "..\render_input\" + $file.name
    $temp_json = .\zz_tools\UDT_json.exe -a=g -c $udtFilename | ConvertFrom-Json
    
    # Check if demo game is in the valid games list 
    if (-not $config.application.validGames.Contains($temp_json.gameStates[0].configStringValues.fs_game)){
        Write-Output $(-join ("""", $temp_json.gameStates[0].configStringValues.fs_game , """ is not a valid game, skipping...)"))
        continue createRenderList
    }

    # demo is valid, ready for further processing
    
    # add to renderlist
    Write-Output "Adding to renderlist."

    $temp_demo = New-Object -TypeName PSObject

    Add-Member -Force -InputObject $temp_demo -MemberType NoteProperty -Name captureName -Value $(randomAlphanumeric(11))
    Add-Member -Force -InputObject $temp_demo -MemberType NoteProperty -Name game -Value $temp_json.gameStates[0].configStringValues.fs_game
    Add-Member -Force -InputObject $temp_demo -MemberType NoteProperty -Name fileName -Value $file.Name
    Add-Member -Force -InputObject $temp_demo -MemberType NoteProperty -Name fileName_truncated -Value $(truncateFilename($file))
    Add-Member -Force -InputObject $temp_demo -MemberType NoteProperty -Name fileExtension -Value $file.Extension
    Add-Member -Force -InputObject $temp_demo -MemberType NoteProperty -Name renderFinished -Value $false
    


    if ($temp_firstdemo){
        $temp_firstdemo = $false
        Add-Member -InputObject $session -MemberType NoteProperty -Name demo -Value @($temp_demo)
    } else {
        $session.demo += $temp_demo
    }
    
}
 
# Save session
if ( -not $skipRenderListCreation) { # no new session created, no need to overwrite old file
    writeSession
}

Write-Output " " "Starting render..."
# == Render Loop == 
$currentDuration = 0
:renderLoop foreach($demo in $session.demo){
    
    $captureName = $demo.captureName
    $demoName = $demo.fileName_truncated
    $game = $demo.game

    if ($demo.renderFinished) { # Demo already rendered, skip it
        continue :renderLoop
    }
	
    if ($config.user.mergeRender) {
        Write-Output "file temp/merge/$captureName.mp4" | Out-File -Append -Encoding ascii .\zz_render\temp\mergelist.txt
    }

    Write-Output "Rendering ""$demoName""... (capturename: $captureName)"

    Copy-Item ".\render_input\$demoName.dm_68" ".\$game\demos\$captureName.dm_68"
    
    $q3e_args = @(
        "+set fs_game $game",
        "+set nextdemo quit",
        "+seta in_nograb 1",
        "+seta r_renderScale " +    $config.user.renderScale.enabled,
        "+seta r_renderWidth " +    $config.user.renderScale.resolution[0],
        "+seta r_renderHeight " +   $config.user.renderScale.resolution[1],
        "+seta cl_aviPipeFormat " + $config.application.ffmpegPipeFormats[$config.user.ffmpegMode],
        "+seta cl_aviFrameRate " +  $config.user.framerate,
        "+demo $captureName",
        "+video-pipe $captureName"
    )

    $q3e_proc = Start-Process -PassThru -ArgumentList $q3e_args -FilePath .\quake3e.x64.exe
    $temp_renderTime = Measure-Command {Wait-Process -InputObject $q3e_proc}

    
    Write-Output $(-join ("Time in minutes: ", $temp_renderTime.TotalMinutes)) " "
    
    $demo.renderFinished = $true
    Add-Member -InputObject $demo -MemberType NoteProperty -Name renderTime -Value $temp_renderTime
    writeSession
    
 
    Start-Sleep 3  # wait in case file is not yet free
    if ($config.user.mergeRender){
        $ffprobeData = $(ffprobe -v error -hide_banner -of json -show_entries format ".\$game\videos\$captureName.mp4") | ConvertFrom-Json
        $timestamp = $("{0:hh\:mm\:ss}" -f $([timespan]::fromseconds($currentDuration)))

        Write-Output "$timestamp $demoName" | Out-File -Append .\zz_render\temp\mergelist.txt

        $currentDuration += $ffprobeData.format.duration

        if (Test-Path -PathType Leaf "zz_render\temp\merge\$captureName.mp4"){ Remove-Item  "zz_render\temp\merge\$captureName.mp4" }
        Move-Item -Force ".\$game\videos\$captureName.mp4" "zz_render\temp\merge\$captureName.mp4"

    } else {
        Move-Item -Force ".\$game\videos\$captureName.mp4" "$outputPath\$demoName.mp4"
    }
    
    if($config.user.keepFFmpegLogs -and -not $config.user.mergeRender){
        if ($config.user.compressLogs){
            Rename-Item ".\$game\videos\$captureName.mp4-log.txt" "$captureName.log"
            .\zz_tools\7za.exe a "$game\videos\$captureName.log.gz" "$game\videos\$captureName.log" -mx=9
            Move-Item ".\$game\videos\$captureName.log.gz" "$outputPath\$demoName.log.gz"
        } else {
            Move-Item -Force ".\$game\videos\$captureName.mp4-log.txt" "$outputPath\$demoName.log"
        }
    } else {
        Remove-Item ".\$game\videos\$captureName.mp4-log.txt"
    }
    Remove-Item $(-join('.\', $game , '\demos\', $captureName, $demo.fileExtension))
}

# Merge with ffmpeg
if ($config.user.mergeRender){
    Write-Output "Merging with ffmpeg..."
    .\ffmpeg.exe -y -f concat -safe 0 -i zz_render\mergerenderlist.txt -c copy "$outputPath\merge_output.mp4"
    
    Move-Item .\zz_render\merge_demolist.txt "$outputPath\merge_demolist.txt"
    Remove-Item .\zz_render\mergerenderlist.txt
    Remove-Item .\zz_render\temp\merge\*.mp4
}

Add-Member -InputObject $session.date -MemberType NoteProperty -Name end -Value $(Get-Date)
writeSession


$temp_date_formatted = $($session.date.start | Get-Date -UFormat "%Y_%m_%d-%H_%M_%S")

if ($config.user.compressLogs){
    .\zz_tools\7za.exe a "zz_render\logs\session-$temp_date_formatted.json.gz" ".\zz_render\session.json" -mx=9
    Remove-Item ".\zz_render\session.json"
} else {
    Move-Item ".\zz_render\session.json" ".\zz_render\logs\session-$temp_date_formatted.json"
}
Write-Output "Rendering finished."

#shutdown -s -t 60
pause
