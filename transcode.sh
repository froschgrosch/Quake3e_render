#!/usr/bin/env bash
###################################################################
# Quake3e_Render - https://github.com/froschgrosch/Quake3e_render #
# Licensed under GNU GPLv3. - File: transcode.sh                  #
###################################################################

## FUNCTION DECLARATION ##

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
            echo 'Shutdown with timeout (to be implemented)'
            exit 0
        ;;

        *)
            exit 0
        ;;
    esac
}

## PROGRAM START ##

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


# main loop
for demo in ./zz_transcode/input/*.json
do
    name=$(basename -a $demo)
    name=${name/.json/}

    echo "Now transcoding $name..."

    fs_game=$(jq -r .fs_game "$demo")

    cp "./zz_transcode/input/$name.dm_68" "./$fs_game/demos/temp_transcode.dm_68"

    ./quake3e.x64 +set fs_game "$fs_game" +set fs_homepath "$PWD" +set nextdemo 'quit' +set in_nograb 1 +demo 'temp_transcode.dm_68' +video-pipe 'temp_transcode' &> /dev/null

    rm "./$fs_game/demos/temp_transcode.dm_68"

    rm "./$fs_game/videos/temp_transcode.mp4-log.txt"
    mv "./$fs_game/videos/temp_transcode.mp4" "./zz_transcode/output_video/$name.mp4"

    # set date on video file
    touch -d "$(date -Rr "./zz_transcode/input/$name.dm_68")" "./zz_transcode/output_video/$name.mp4"

    # move demo file to output_folder
    mv "./zz_transcode/input/$name.dm_68" ./zz_transcode/output_demo/

    if [[ $(jq .stopAfterThis "$demo") == true ]] then
        echo 'Demo transcoding is being paused.'; echo 'You can resume by invoking "./transcode.sh" again.'
        mv $demo ./zz_transcode/output_demo/
        exit_transcodesession
    fi

    # can be deleted alternatively
    mv $demo ./zz_transcode/output_demo/

done

echo "Demo transcoding is finished."
exit_transcodesession
