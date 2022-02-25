# github/froschgrosch/RA3-demo-formatter
 
$output = $true
$demoFolder = "$PSScriptRoot\demos"
$minSize = "100kb" #delete demos below size threshold



$reiterateFolder = $true

while ($reiterateFolder) {
    $reiterateFolder = $false
    $files = Get-ChildItem $demoFolder | Sort-Object -Property Name
    foreach ($f in $files){
        $processingType = 0

        # regex to recognize q3e style named demos
        if ($f.Name -match 'demo-\d{8}-\d{6}.dm_68') { $processingType = 1; } # assume unsplit
        elseif ($f.Name -match 'demo-\d{8}-\d{6}_SPLIT_\d.dm_68') { $processingType = 2; } # split

        if ($processingType -eq 1 -or $processingType -eq 2) { 
 
            #echo "Processing $f..."
            
            $json = $null
            $json = .\tools\UDT_json.exe -c "$demoFolder\$f" | ConvertFrom-Json
            
            if (!$json)
            { 
                echo "UDT failed on $f!"
                #return;
            }

            # Special condition for multi-map demos
            if($processingType -eq 1 -and $json.gameStates.Length -gt 1) {
                $reiterateFolder = $true
                
                if ($output) {
                    echo "Splitting $f..." ''
                }
                
                .\tools\UDT_splitter.exe "$demoFolder\$f" -q


                Remove-Item -Path "$demoFolder\$f"

             } else {
 
                $demoTaker = $json.gameStates.demoTakerCleanName.Replace(' ','')
                $map = $json.matchStats.map

                $playersString = ''
                foreach($player in $json.gameStates.players){
                    if ($player.clientNumber -ne $json.gameStates.demoTakerClientNumber){
                        $playersString = $playersString + '-vs-' + $player.cleanName.Replace(' ','')
                    }
                }
 

                $year = $f.Name.Substring(5,4)
                $month = $f.Name.Substring(9,2)
                $day = $f.Name.Substring(11,2)

                $hour = $f.Name.Substring(14,2)
                $min = $f.Name.Substring(16,2)
                $sec = $f.Name.Substring(18,2)

                
                $filenameNew = "$demoTaker(POV)$playersString-$map-$year-$month-$day_$hour-$min-$sec.dm_68"


                if ($output) {
                    echo "Old: $f" "New: $filenameNew" ''
                }

                Rename-Item -Path "$demoFolder\$f" -NewName $filenameNew
             }
        } else {
            if ($output){
              echo "Skipping $f..." #''
            }
        }
    }
}

Get-ChildItem $demoFolder | Where-Object { $_.Length -lt $minSize} | Remove-Item

if ($output) {pause} # no need to pause if there are no logs to read