# RA3-demo-formatter
A small powershell script to format the names of demos manually recorded with Q3E.

This Powershell program renames demos from the *demo-yyyymmdd-hhmmss.dm_68* to *player(POV)-vs-player-vs-player-map-yyyy-mm-dd_-hh-mm-ss.dm_68*. 
It utilizes [mightycow's](https://github.com/mightycow) awesome UberDemoTools for parsing.

Demos that do not follow the Quake3e demo name formatting will be ignored. The script is tweaked to work with Rocket Arena 3 Demos because those do not auto-name properly when recorded. 

## Usage
- Set the *$demoFolder* variable to the path of your demos. By default the script will look in the *demos* folder next to itself.
- Open Powershell, navigate to the script folder and run *./formatter.ps1*
- The demos in the folder will be renamed.
