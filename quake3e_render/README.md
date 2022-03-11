# quake3_render

A Powershell application to aid in demo rendering. Run with *Right-click\Run with powershell* as some paths in the script are relative.

## Installation

### Downloads

- [ffmpeg](http://ffmpeg.org/download.html)
    - ffmpeg.exe and ffprobe.exe
- [UDT](https://github.com/mightycow/uberdemotools)
    - UDT_json.exe
- [7-zip (only required if you want to use log compression)](https://7-zip.org/download.html)
    - 7za.exe

### File structure

```
Your Q3 folder
|---baseq3/
|   ... other mod folders
|
|---render_input/
|---render_output/
|---zz_render/
|   |---config.json
|   |---logs/
|   |---temp/
|       |---merge/
|       |---merge_ffmpeglogs/
|
|---zz_tools/
|   |---UDT_json.exe
|   |---7za.exe
|
|---ffmpeg.exe
|---ffprobe.exe
|---quake3e.x64.exe
|---quake3e_render.ps1

```
    
## User configurable params


- `"mergeRender" : 0`
    - When set to 1, all rendered demos will be merged into one videofile with ffmpeg.
- `"renderScale" : { "enabled": 0, "resolution" : [3840, 2160] }`
    - When `enabled` is set to 1, the cvar r_renderScale will be enabled. It enables rendering at resolutions greater than screen resolution. Requires `r_fbo 1`. The resolution is specified in the `resolution` array
- `"framerate": 60`
    - Set the output framerate.
- `"ffmpegMode" : 0`
    - Select index of the ffmpeg pipe format mode, which is stored in `ffmpegPipeFormats` variable. 
- `"logFFmpeg" : 0`
    - When set to 1, the ffmpeg encoding logs will be moved to the output path.
    - When set to 2, the logs will be compressed and moved to the output path.
- `"logSession" : 0`
    - When set to 1, *session.json* will be moved to the *zz_render\logs\\* directory
    - When set to 2, *session.json* will be compressed and moved to the *zz_render\logs\\* directory

## Application configuration

- `"outputPath" : ".\\render_output"`
    - The path where the script will put finished video files. The path can be absolute or relative to your quake3 installation.
- `"skipKeywords" : [ "SKIP" ]`
    - If the demo starts with one of these keywords, it will be skipped in rendering. Useful if you don't want to render a demo twice.
- `"validGames" : [ "baseq3" ]`
    - Put a list of the installed mods here. If the demo's fs_game isn't in here, it will be skipped.
- `"validDemoFormats" : [ ".dm_68" ]`
    - Put a list of the valid demo formats here.
- `"ffmpegPipeFormats" : [ "\"-preset medium -crf 23 -vcodec libx264 -flags +cgop -pix_fmt yuv420 -bf 2 -codec:a aac -strict -2 -b:a 160k -r:a 22050 -movflags faststart\"" ]`
    - Here the different ffmpeg configurations are stored. You can put one for sofware rendering and one for hardware rendering, for example. 
