#!/usr/bin/env bash
###################################################################
# Quake3e_Render - https://github.com/froschgrosch/Quake3e_render #
# Licensed under GNU GPLv3. - File: transcode.sh                  #
###################################################################

## FUNCTION DECLARATION ##

function set_configfile() {
    # index of -1 is the q3config.cfg that is already installed beforehand

    if [[ $renderConfig -eq $(< "./zz_transcode/cfg_$fs_game") ]] # no need to change anything
    then
        #echo "Correct file $renderConfig already in place, nothing to swap!"
        return
    elif [[ $renderConfig -eq -1 ]]
    then
        #echo 'Put back old config (-1)'

        if [ -f "./$fs_game/q3config.cfg.bak" ]; then
            rm "./$fs_game/q3config.cfg" 2>/dev/null
            mv "./$fs_game/q3config.cfg.bak" "./$fs_game/q3config.cfg"
        fi
    elif [[ $renderConfig -ge 0 && $fs_game == ${cfg_games[$renderConfig]} ]]
    then
        #echo "Put config $renderConfig"

        if [ ! -f "./$fs_game/q3config.cfg.bak" ]; then
            mv "./$fs_game/q3config.cfg" "./$fs_game/q3config.cfg.bak"
        fi

        cp -f "./zz_config/q3cfg/$fs_game/${cfg_filenames[$renderConfig]}.cfg" "./$fs_game/q3config.cfg"
    else
        echo 'Invalid conditions for config swapping. Nothing was changed.'
        echo "Requested for fs_game: $fs_game"; echo "Requested config index: $renderConfig"; echo "Current Index: $(< "./zz_transcode/cfg_$fs_game")"
        return
    fi

    # write config file status
    echo $renderConfig > "./zz_transcode/cfg_$fs_game"
}

function init_configfiles() {
    clear_configfiles

    for fs_game in "${cfg_allowedGames[@]}"
    do
        echo '-1' > "./zz_transcode/cfg_$fs_game"
    done
}

function clear_configfiles() {
    rm -f ./zz_transcode/cfg_* 2>/dev/null
    for fs_game in "${cfg_allowedGames[@]}"
    do
        if [ -f "./$fs_game/q3config.cfg.bak" ]; then
            rm "./$fs_game/q3config.cfg" 2>/dev/null
            mv "./$fs_game/q3config.cfg.bak" "./$fs_game/q3config.cfg"
        fi
    done
}

function exit_transcodesession() {
    case $(jq -r '.exitBehaviour.value' ./zz_config/transcode.json) in
        0) # exit with pause
            read -n 1 -s -r -p 'Press any key to continue...'
            exit 0
        ;;

        1) # exit without pause
            exit 0
        ;;

        2) # shutdown with timeout
            timeout=$(jq -r '.exitBehaviour.shutdownTimeout' ./zz_config/transcode.json)

            echo "Shutting down in $timeout seconds."
            read -t $timeout -n 1 -s -r -p 'Press any key to shut down immediately (Ctrl + C to cancel)...'

            systemctl poweroff
        ;;

        *)
            exit 0
        ;;
    esac
}

## INITIALIZATION ##

# check if all external dependencies are available
jq --version 1> /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo 'Error: jq is not available! Please refer to README.md'
    exit 1
fi

if [ ! -x ./zz_tools/UDT_json ]; then
    echo 'Error: UDT_json is not available at the expected path! Please refer to README.md'
    exit 1
fi

# check if q3 binary is present and executable
if [ ! -x ./quake3e.x64 ]; then
    echo 'Error: The Quake 3 binary is not present and executable at required path!'; echo 'Please place quake3e.x64 in the current directory.'
    exit 1
fi

# list input files
# todo: improve readability for user
ls -1 ./zz_transcode/input/*.json 2> /dev/null
if [ $? -eq 0 ]
then
    echo 'The preceding list of demos will be transcoded.'
    read -n 1 -s -r -p 'Press any key to continue (Ctrl + C to cancel)...'
    echo # for newline
else
    echo 'ERROR: No prepared demos found! Please prepare some using prepare.sh!'
    exit 1
fi

# check if config swapping is enabled
configSwapping=$(jq '.configSwapping.enabled' ./zz_config/transcode.json)

if [[ $configSwapping == true ]]
then
    # read config swapping data
    readarray -t cfg_games < <(jq -r '.configSwapping.list[][1]' ./zz_config/transcode.json)
    readarray -t cfg_filenames < <(jq -r '.configSwapping.list[][0]' ./zz_config/transcode.json)

    readarray -t cfg_allowedGames < <(jq -r '.configSwapping.allowedGames[]' ./zz_config/transcode.json)

    # check q3cfg file status
    ls ./zz_transcode/cfg_* 1> /dev/null 2>&1
    if [ $? -eq 0 ]
    then
    #echo 'there is an existing status'

        # check if the loaded status matches with the present files
        for game in "${cfg_allowedGames[@]}"
        do
            status=$(cat "./zz_transcode/cfg_$game" 2> /dev/null)
            #echo "$game $status"

            # If (status != -1 AND file is missing) OR (status == -1 AND file exists)
            if [[ ( "$status" -ne -1 && ! -f "./$game/q3config.cfg.bak" ) || ( "$status" -eq -1 && -f "./$game/q3config.cfg.bak" ) ]]
            then
                init_configfiles
                break
            fi
        done
    else
        init_configfiles
    fi
fi

# get process priority

# this jq expression clamps the output between 0 and 19 when the input is an integer (non-root users can only increase the process niceness (reduce priority))
# if any other data type is inputted, the output defaults to 0 (default priority)
ffmpegPriority=$(jq '.ffmpegPriority | if (type == "number" and . == (. | floor)) then (if . < 0 then 0 elif . > 19 then 19 else . end) else 0 end' ./zz_config/transcode.json)


## PROGRAM START ##

# main loop
for demo in ./zz_transcode/input/*.json
do
    name=$(basename -a $demo)
    name=${name/.json/}

    echo "Now transcoding $name..."

    fs_game=$(jq -r .fs_game "$demo")

    # put config file if swapping is enabled
    if [[ $configSwapping == true ]]
    then
        renderConfig=$(jq -r .renderConfig "$demo")
        set_configfile
    fi

    cp "./zz_transcode/input/$name.dm_68" "./$fs_game/demos/temp_transcode.dm_68"

    # start quake3e with desired priority - the child processes will inherit it
    nice -n $ffmpegPriority ./quake3e.x64 +set ttycon 0 +set fs_game "$fs_game" +set fs_homepath "$PWD" +set nextdemo 'quit' +set in_nograb 1 +demo 'temp_transcode.dm_68' +video-pipe 'temp_transcode' &>/dev/null

    rm "./$fs_game/demos/temp_transcode.dm_68"

    rm "./$fs_game/videos/temp_transcode.mp4-log.txt"
    mv -f "./$fs_game/videos/temp_transcode.mp4" "./zz_transcode/output_video/$name.mp4"

    # set date on video file
    touch -d "$(date -Rr "./zz_transcode/input/$name.dm_68")" "./zz_transcode/output_video/$name.mp4"

    # move demo file to output_folder
    mv "./zz_transcode/input/$name.dm_68" ./zz_transcode/output_demo/

    if [[ $(jq .stopAfterThis "$demo") == true ]]
    then
        echo 'Demo transcoding is being paused.'; echo 'You can resume by invoking "./transcode.sh" again.'
        rm "$demo"
        exit_transcodesession
    fi

    # delete data file
    rm "$demo"
done

if [[ $configSwapping == true ]]
then
    clear_configfiles
fi

echo "Demo transcoding is finished."
exit_transcodesession
