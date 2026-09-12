#!/usr/bin/env bash
###################################################################
# Quake3e_Render - https://github.com/froschgrosch/Quake3e_render #
# Licensed under GNU GPLv3. - File: prepare.sh                    #
###################################################################

## PROGRAM START ##

# check if a list was already created
ls ./zz_transcode/input/*.json 1> /dev/null 2>&1
if [ $? -eq 0 ]
then
    read -p 'Another demo list was already created earlier. Do you want to create a new one? [Y/n] ' -n 1
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo; echo 'Exiting.'
        exit 1
    fi
    echo; echo 'Creating new demo list.'
    rm ./zz_transcode/input/*.json
fi

# check if input folder is empty
ls ./zz_transcode/input/*.dm_68 1> /dev/null 2>&1
if [ $? -eq 2 ]
then
    echo 'ERROR: No valid input files found!' 'Please check ./zz_transcode/input/'
    exit 1
fi

# check if there are any allowed games
readarray -t allowedGames < <(jq -rc '.games.allowed.[]' ./zz_config/prepare.json 2> /dev/null)

if [[ ${#allowedGames[@]} -eq '0' ]]
then
    echo 'Error: No mods specified in the config file'; echo 'Please specify at least one valid mod in the config file.'
    exit 1
fi

demoList=()

for file in ./zz_transcode/input/*.dm_68; do
    file=$(basename -a $file)
    file=${file/.dm_68/}

    echo "Checking $file..."

    # check if video already exists
    if [ -f "./zz_transcode/output_video/$file.mp4" ]
    then
        read -p 'This demo was already transcoded at some point. Would you like to transcode it again? [Y/n] ' -n 1
        if [[ $REPLY =~ ^[Nn]$ ]];
        then
            echo
            continue
        else
            echo
            rm "./zz_transcode/output_video/$file.mp4"
        fi
    fi

    # check if fs_game is valid
    udtoutput=$(zz_tools/UDT_json -a=g -c "./zz_transcode/input/$file.dm_68")

    #echo $udtoutput | jq

    fs_game=$(echo "$udtoutput" | jq -r .gameStates[0].configStringValues.gamename)

    if [[ ! " ${allowedGames[*]} " =~ [[:space:]]${fs_game}[[:space:]] ]]
    then
        echo "fs_game of demo is not valid ($fs_game)!"
        continue
    fi

    echo 'Adding to renderlist.'

    # this starts another jq instance every loop, can this be avoided?
    renderConfig=$(jq -c --arg game "$fs_game" '.games.defaultConfig[$game]' ./zz_config/prepare.json)

    # write demo data file
    jq -n \
    --arg fs_game "$fs_game" \
    --arg renderConfig "$renderConfig" \
    '{
        stopAfterThis: false,
        renderConfig: $renderConfig,
        fs_game: $fs_game
    }' > "./zz_transcode/input/$file.json"

done

echo 'Demo preprocessing is finished.'
exit 0
