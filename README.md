# quake3_render

A Powershell application to aid in demo rendering. Run with *Right-click\Run with powershell* as some paths in the script are relative.

## Installation

### Downloads

- **ffmpeg**
    - [Download from *ffmpeg.org*](http://ffmpeg.org/download.html)
    - Required files:
        - ffmpeg.exe 
        - ffprobe.exe
- **UberDemoTools**
    - [Download from *Github*](https://github.com/mightycow/uberdemotools)
    - Required files:
        - UDT_json.exe
- **7-zip** command line version
    - [Download from *7-zip.org*](https://7-zip.org/download.html)
    - Required files:
        - 7za.exe

### File / folder structure

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
|   |---ffprobe.exe
|
|---ffmpeg.exe
|
|---quake3e.x64.exe
|---quake3e_render.ps1

```
    
## User configurable params

- `"mergeRender" : 0`
    - When set to 1, all rendered demos will be merged into one video file with ffmpeg.
- `"renderScale" : { "enabled": 0, "resolution" : [3840, 2160] }`
    - When `enabled` is set to 1, the cvar r_renderScale will be enabled. It enables rendering at resolutions greater than screen resolution. Requires `r_fbo 1`. The resolution is specified in the `resolution` array.
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
- `"fontScale" : { "target": 1, "referenceResolution" : [1920, 1080] }`
    - The console font will be scaled if renderScale is enabled. `target` is the target size at the resolution specified in `renderResolution`.
-  `"exitBehaviour" : 1`
    - This setting controls what happens when the demo list reaches its end.
    - There also is a way to trigger a stop after a specific demo has finished rendering. Set `stopAfterCurrent = true` for the demo inside the *session.json* file.
    - Possible settings are:
        - `0` - Exit without further pausing.
        - `1` - Pause, and then exit. This is the default (and old) behaviour.
        - `2` - Log out the windows user. 
        - `3` - Shut down the computer.
    - The timeout for the settings `2` and `3` is specified in the `shutdownTimeout` setting.

## Application configuration

- `"outputPath" : ".\\render_output"`
    - The path where the script will put finished video files. The path can be absolute or relative to your quake3 installation.
- `"skipKeywords" : [ "SKIP" ]`
    - If the demo starts with one of these keywords, it will be skipped in rendering. Useful if you don't want to render a demo twice.
- `"validGames" : [ "baseq3" ]`
    - Put a list of the installed mods here. If the demo's fs_game isn't in here, it will be skipped.
- `"validDemoFormats" : [ ".dm_68" ]`
    - Put a list of the valid demo formats here.
- `"ffmpegPipeFormats" : [ "\"-preset medium -crf 23 -vcodec libx264 -flags +cgop -pix_fmt yuv420 -bf 2 -codec:a aac -strict -2 -b:a 160k -r:a 22050 -movflags faststart\"" , "x264 crf23 medium]`
    - Here the different ffmpeg configurations are stored. You can put one for sofware rendering and one for hardware rendering, for example. 
    - The first element of the array is the actual line for `cl_aviPipeFormat`, the second element is the description that will be displayed when checking settings.
- `"renderScaleMode" : 3`
    - Sets the r_renderScale mode that quake3e should use.
    - [Here is the section in the Quake3e docs](https://github.com/ec-/Quake3e/blob/master/docs/quake3e.htm#L218)
-  `"shutdownTimeout" : 30`
    - Specifies the shutdown timeout for exit options 2 and 3. This is how much time you will have from when you are notified that your computer is about to shut down until it actually does it.
