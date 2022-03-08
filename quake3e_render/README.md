# quake3_render

A Powershell application to aid in demo rendering. Run with *Right-click\Run with powershell* as some paths in the script are relative. At the moment, only demos in the **.dm_68** format are supported.

## Installation.

Put the script file and a recent version of [ffmpeg](http://ffmpeg.org/download.html) and [quake3e](https://github.com/ec-/Quake3e/releases/tag/latest) in your quake3 folder. Create the directories *render_input*, *render_output* and *zz_render*. Inside the *zz_render* folder, create a folder *merge_rendetemp* and a folder *tools*. Download [myt's UberDemoTools](https://github.com/mightycow/uberdemotools) for command line, and put UDT_json.exe in the *zz_render/tools* folder you just created. 

Now it is time to configure the application. To do that, you edit *config.json.txt* in *zz_render*.

## User configurable params

```
mergeRender = 0 # ( 1 | 0 )          # When set to 1, all rendered demos will be merged into one videofile with ffmpeg.

renderScale = 0 # ( 1 | 0 )          # When set to 1, the cvar r_renderScale will be enabled. It enables rendering at resolutions greater than screen resolution.
renderResolution = @("3840","2160")  # Set render width and height respectively.
framerate = 60                       # Set the output framerate.

ffmpegMode = 0                       # Select index of the ffmpeg pipe format mode, which is stored in the $ffmpegModes variable. 

keepLog = 0 # ( 1 | 0 )              # When set to 1, the ffmpeg encoding logs will be copied to the output path.
```

## Application configuration

```
outputPath = ".\render_output"     # The path where the script will put finished video files. The path can be absolute or relative to your quake3 installation.
skipKeywords = @("SKIP")           # If the demo starts with one of these keywords, it will be skipped in rendering. Useful if you don't want to render a demo twice.
validGames = @("baseq3")           # Put a list of the installed mods here. If the demo's fs_game isn't in here, it will be skipped.

ffmpegModes = @("-preset medium -crf 23 -vcodec libx264 -flags +cgop -pix_fmt yuv420 -bf 2 -codec:a aac -strict -2 -b:a 160k -r:a 22050 -movflags faststart")
# Here the different ffmpeg configurations are stored. You can put one for sofware rendering and one for hardware rendering, for example. 
```
