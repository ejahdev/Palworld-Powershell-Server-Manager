
# PalWorld Server Manager Script<br>
<br><br>
Major credits to u/SpasticSquirr3l<br> 
(this script is my edited version from his reddit post https://www.reddit.com/r/Palworld/comments/1adj6t9/selfhost_server_autostartrebootupdate/ that I added a couple of features to.)<br><br>
### What it handles:<br>
 - Daily Auto Restarts<br>
 - Hourly Backups<br>
 - Broadcast Warning to player using ARRCON.EXE<br>
 - Auto Update check on start and restarts<br>
   - If "$autoUpdate = $true", it checks and applies update if available<br>
 - Discord webhook status updates
   - Ability to tag a specific role if update found, so users know to update client<br>
<br><br>
### Dependencies:<br>
 - Windows Powershell<br>
 - [ARRCON.EXE](https://github.com/radj307/ARRCON)<br><br><br>

### The script does elevate to Administrator to leverage "ROBOCOPY" for the backups.



