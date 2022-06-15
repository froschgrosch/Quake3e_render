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

```text
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
|   |   |---merge/
|   |   |---merge_ffmpeglogs/
|   |---profiles/
|       | Custom profile files, eg.
|       |---preview_RA3.json
|       |---preview_RA3_q3config.cfg
|         ...
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
  - When set to 2, *session.json* will be compressed with the *xz* algorithm and moved to the *zz_render\logs\\* directory
- `"fontScale" : { "target": 1, "referenceResolution" : [1920, 1080] }`
  - The console font will be scaled if renderScale is enabled. `target` is the target size at the resolution specified in `renderResolution`.
- `"exitBehaviour" : 1`
  - This setting controls what happens when the demo list reaches its end.
  - It is also possible to trigger a stop after a specific demo has finished rendering. Set `stopAfterCurrent = true` for the demo inside the *session.json* file.
  - Possible settings are:
    - `0` - Exit without further pausing.
    - `1` - Pause, and then exit. This is the default (and old) behaviour.
    - `2` - Shut down the computer.
  - The timeout for the shutdown is specified in the `shutdownTimeout` setting.
- `"demoSorting" : 1`
  - If set to `1`, demos will be sorted by date for the render list creation. Otherwise, they are sorted by name.

## Application configuration

- `"outputPath" : ".\\render_output"`
  - The path where the script will put finished video files. The path can be absolute or relative to your quake3 installation.
- `"skipKeywords" : [ "SKIP" ]`
  - If the demo starts with one of these keywords, it will be skipped in rendering. Useful if you don't want to render a demo twice.
- `"validGames" : [ "baseq3" ]`
  - Put a list of the installed mods here. If the demo's fs_game isn't in here, it will be skipped.
- `"validDemoFormats" : [ ".dm_68" ]`
  - Put a list of the valid demo formats here.
- `"ffmpegPipeFormats" : [ "\"-preset medium -crf 23 -vcodec libx264 -flags +cgop -pix_fmt yuv420 -bf 2 -codec:a aac -strict -2 -b:a 160k -r:a 22050 -movflags faststart\"" , "x264 crf23 medium"]`
  - Here the different ffmpeg configurations are stored. You can put one for sofware rendering and one for hardware rendering, for example.
  - The first element of the array is the actual line for `cl_aviPipeFormat`, the second element is the description that will be displayed when checking settings.
- `"renderScaleMode" : 3`
  - Sets the r_renderScale mode that quake3e should use.
  - [Here is the section in the Quake3e docs](https://github.com/ec-/Quake3e/blob/master/docs/quake3e.htm#L218)
- `"shutdownTimeout" : 30`
  - Specifies the shutdown timeout. This is how much time you will have from when you are notified that your computer is about to shut down until it actually does it.
- `"confirmSession" : 0`
  - If set to 1, the application will wait for confirmation before it starts rendering after creating the render list. Useful if you often edit *session.json* manually.

## Render profiles

The application now supports different rendering profiles, with the idea being to have different config files for different use cases (eg. one for rendering low quality previews, one for 4k etc.) which can have custom `q3config.cfg` files for each profile.

Please note that only one render profile (notably for one mod only) can be used in one session. So if you have demos for multiple mods only the one with the mod in the render profile will be using the render profile, as it only applies to one mod.

A config override file contains all the *user* settings that will be overridden. Settings not included will stay at the default value specified in the config file as before. One such override file might look like this.

### preview_RA3.json

``` JSON
{
    "mergeRender" : 0,
    "renderScale" : { "enabled": 1, "resolution" : [960, 540] },
    "framerate": 30,
    "ffmpegMode" : 0,
    "fontScale" : { "target": 2, "referenceResolution" : [1920, 1080] },
    "demoSorting": 0
}
```

The information regarding each render profile needs to be stored in `config.json`. The render profile that is to be used will be selected with the `renderProfile` setting. The feature can also be disabled entirely by setting `renderProfile` to `-1`.

`config.json` contains various information related to the render profile selection. The render profiles are stored in an array. It is also specified here if and how the config swapping should be dealt with. The following code example illustrates how a valid render profile specification looks. *(Note that JSON doesn't actually support comments, they are just for clarification)*

``` JSON
"renderProfile" : 0, // this selects the first one
// other stuff
"renderProfiles" : [
    { 
        "profileName" : "preview_LQ (RA3)",
        "configFile" : "preview_RA3_config.json",
        "q3config_override" : true,
        "q3config_file" : "preview_RA3_q3config.cfg",
        "game" : "arena"
    }
]
```
