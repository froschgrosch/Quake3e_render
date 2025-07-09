# quake3_render

A Powershell application to aid in converting Quake3 demos to video files, rewritten because the old codebase was a huge mess.

## Installation

### Downloads

- **ffmpeg**
  - [Download from *ffmpeg.org*](http://ffmpeg.org/download.html)
  - Required files:
    - ffmpeg.exe
- **UberDemoTools**
  - [Download from *GitHub*](https://github.com/mightycow/uberdemotools)
  - Required files:
    - UDT_json.exe

### File / folder structure

It is recommended to create a separate Quake 3 installation dedicated to demo rendering.

```text
Your Q3 folder
|---baseq3/
|   ... other mod folders
|
|---zz_transcode/
|   |
|   |---input/
|   |---output/
|   |---currentConfigFiles.json // only if feature is enabled
|   |---demoList.json
|
|---zz_tools/
|   |---UDT_json.exe
|
|---zz_config/
|   |
|   |---prepare.json
|   |---transcode.json
|   |---q3cfg/
|       |
|       |---arena/
|       |   |
|       |   |---00_preview.cfg
|       |       ... other config files
|       |
|       |---osp/
|           |
|           |---00_q3msk_4K.cfg
|       ...and so on
|
|---ffmpeg.exe
|
|---quake3e.x64.exe
```
