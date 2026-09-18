#!/usr/bin/env bash
###################################################################
# Quake3e_Render - https://github.com/froschgrosch/Quake3e_render #
# Licensed under GNU GPLv3. - File: prepare.sh                    #
###################################################################

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

## PROGRAM START ##

# check if a list was already created
ls ./zz_transcode/input/*.json 2> /dev/null
if [ $? -eq 0 ]
then
    echo 'The preceding list of demos were already prepared for transcoding earlier.'
    read -p 'Do you want to discard the list and create a new one? [Y/n] ' -n 1
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

# read default config to associative array
declare -A defaultConfig

while IFS=$'\t' read -r key value; do
    defaultConfig["$key"]="$value"
done < <(jq -r '.games.defaultConfig | to_entries[] | "\(.key)\t\(.value)"' ./zz_config/prepare.json)

# main preparation loop
for file in ./zz_transcode/input/*.dm_68; do
    file=$(basename -a $file)
    file=${file/.dm_68/}

    echo "Checking $file..."

    # check if video already exists
    if [ -f "./zz_transcode/output_video/$file.mp4" ]
    then
        read -p 'This demo was already transcoded at some point. Would you like to transcode it again? [y/N] ' -n 1; echo
        if [[ $REPLY =~ ^[Yy]$ ]];
        then
            rm "./zz_transcode/output_video/$file.mp4"
        else
            mv "./zz_transcode/input/$file" ./zz_transcode/output_demo/
            continue
        fi
    fi

    # get demo data
    udtoutput=$(zz_tools/UDT_json -a=g -c "./zz_transcode/input/$file.dm_68")
    if [[ $? -ne 0 ]]
    then
        echo 'Return code of UDT_json is not 0! Demo will be moved to output folder without transcoding.'; echo

        mv "./zz_transcode/input/$file.dm_68" ./zz_transcode/output_demo/
        continue
    fi

    # unfortunately, UDT_json does not exit with error code 1 when the demo is invalid.
    # this statement checks if there is exactly one gamestate, and if there are players and configstrings in the demo
    if [[ $(echo $udtoutput | jq '(.gameStates[].players | length == 0) or (.gameStates | length != 1) or (.gameStates[].configStringValues | length == 0)') == true ]]
    then
        echo 'Something is wrong with this demo file (Not exactly one gamestate, or no players or configStrings).'
        echo; echo "UDT_json output of $file:"

        echo "$udtoutput" | jq .
        echo 'Moving to output folder.'; echo

        mv "./zz_transcode/input/$file.dm_68" ./zz_transcode/output_demo/
        continue
    fi

    # check if fs_game is valid
    fs_game=$(echo "$udtoutput" | jq -r .gameStates[0].configStringValues.gamename)

    if [[ ! " ${allowedGames[*]} " =~ [[:space:]]${fs_game}[[:space:]] ]]
    then
        echo "fs_game of demo is not valid ($fs_game)!"
        continue
    fi

    echo 'Adding to renderlist.'

    # write demo data file
    jq -n \
    --arg fs_game "$fs_game" \
    --arg renderConfig "${defaultConfig[$fs_game]}" \
    '{
        stopAfterThis: false,
        renderConfig: $renderConfig,
        fs_game: $fs_game
    }' > "./zz_transcode/input/$file.json"
done

echo 'Demo preprocessing is finished.'
exit 0
