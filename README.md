
# PalWorld Server Manager Script<br>
<br><br>
### It handles:<br>
 - Daily Auto Restarts<br>
 - Hourly Backups<br>
 - Broadcast Warning to player using ARRCON.EXE<br>
 - Auto Update check on start and restarts<br>
   - If "$autoUpdate = $true", it checks and applies update if available<br>
<br><br>
### dependancies:<br>
 - Windows Powershell<br>
 - [ARRCON.EXE](https://github.com/radj307/ARRCON)<br><br><br>

### The script does elevate to Administrator to leverage "ROBOCOPY" for the backups.



