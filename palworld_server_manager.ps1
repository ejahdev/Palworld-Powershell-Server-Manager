cls

# Check if the script is already running as administrator or not
$isAdmin = ([Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544"
if (-not $isAdmin) {
    # Relaunch the script with administrative privileges
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`"" -Verb RunAs
    Exit
}

$steamCMD = "C:\steamcmd" # Insert path to steamcmd
$PalworldFolder = "C:\YOUR\SERVER\PATH" # Insert path to PALSERVER

$autoUpdate = $true # Set True or False if you want to auto-update your server during restarts

$restart_interval = 86400 # 86400 - 24 hours in seconds
$backup_interval = 3600 # Backup interval in seconds, 3600 is 1 Hour
$restart_warning = 60 # int in seconds before server restart a warning messsage is broadcasted to players

$arrconPath = "C:\ARRCON.exe" # Set to ARRCON.exe path
$rconHost = "127.0.0.1" # change to your rcon host if not local
$rconPort = "27025" # change to your desired port if not default
$rconPassword = "YOUR_PASSWORD_HERE" # Insert rcon password
$broadcast_message = "SERVER_RESTARTING_IN_60_SECONDS!" # Change as desired

$log_file = "Palworld_ServerLog.txt" # Creates log file in the same path as ps1 script

$warning_sent = $false # do NOT change - makes sure the warning message doesnt send multiples

function check_program {
    while ($true) {
        $PalworldServer = Get-Process PalServer -ErrorAction SilentlyContinue
        if ($PalworldServer -eq $null){
            Write-Host "["$(Get-Date)"] " "Server Not Running. Starting Server."; "["+$(Get-Date)+"] " + "Server Not Running. Starting Server." | Out-File -FilePath "$PSScriptRoot\$log_file" -Append
            start_server
        } else {
            Write-Host "["$(Get-Date)"] " "Server Running Normally."; "["+$(Get-Date)+"] " + "Server Running Normally." | Out-File -FilePath "$PSScriptRoot\$log_file" -Append
        }

        Start-Sleep -Seconds 60
        $server_timer = $server_timer + 60
        $backup_timer = $backup_timer + 60

        if ($server_timer -ge ($restart_interval - $restart_warning) -and -not $warning_sent) {
            # Broadcast a warning message to users
            Write-Host "["$(Get-Date)"] " "Broadcasting warning message to users."; "["+$(Get-Date)+"] " + "Broadcasting warning message to users." | Out-File -FilePath "$PSScriptRoot\$log_file" -Append
            Broadcast-Message $broadcast_message
            $warning_sent = $true
        }

        if ($server_timer -ge $restart_interval) {
            Write-Host "["$(Get-Date)"] " "Restarting Server."; "["+$(Get-Date)+"] " + "Restarting Server." | Out-File -FilePath "$PSScriptRoot\$log_file" -Append
            Stop-Process -Name "PalServer-Win64-Test-Cmd" -ErrorAction SilentlyContinue
            Stop-Process -Name "PalServer" -ErrorAction SilentlyContinue
            $server_timer=0
            
            if($autoUpdate){
                $serverVersionCheck = (("$steamCmd\steamcmd.exe +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +app_info_update 1 +app_status 2394010 +quit" | 
                Select-String "^ - install state:")).Line -replace '^[^:]*:\s*', ''

                if ($serverVersionCheck -like "*update*"){
                    Write-Host "["$(Get-Date)"] " "Server Has an Update. Update Starting."; "["+$(Get-Date)+"] " + "Server Has an Update. Update Starting." | Out-File -FilePath "$PSScriptRoot\$log_file" -Append
                    "$steamCmd\steamcmd.exe +login anonymous +app_update 2394010 validate +quit"
                } else {
                    Write-Host "["$(Get-Date)"] " "No Update Available. Starting Server."; "["+$(Get-Date)+"] " + "No Update Available. Starting Server." | Out-File -FilePath "$PSScriptRoot\$log_file" -Append
                }
            }
            start_server
            $warning_sent = $false
        }

        if ($backup_timer -ge $backup_interval) {
            Write-Host "["$(Get-Date)"] " "Backup Timer Reached. Starting Server Backup."; "["+$(Get-Date)+"] " + "Backup Timer Reached. Starting Server Backup." | Out-File -FilePath "$PSScriptRoot\$log_file" -Append
            $backup_timer = 0
            backup_server
        }
    }
}

function start_server {
    if($autoUpdate){
        $serverVersionCheck = (("$steamCmd\steamcmd.exe +@ShutdownOnFailedCommand 1 +@NoPromptForPassword 1 +login anonymous +app_info_update 1 +app_status 2394010 +quit" | 
        Select-String "^ - install state:")).Line -replace '^[^:]*:\s*', ''

        if ($serverVersionCheck -like "*update*"){
            Write-Host "["$(Get-Date)"] " "Server Has an Update. Update Starting."; "["+$(Get-Date)+"] " + "Server Has an Update. Update Starting." | Out-File -FilePath "$PSScriptRoot\$log_file" -Append
            "$steamCmd\steamcmd.exe +login anonymous +app_update 2394010 validate +quit"
        } else {
            Write-Host "["$(Get-Date)"] " "No Update Available. Starting Server."; "["+$(Get-Date)+"] " + "No Update Available. Starting Server." | Out-File -FilePath "$PSScriptRoot\$log_file" -Append
        }
    }

    Start-Process -FilePath "$PalworldFolder\PalServer.exe" -ArgumentList "-useperfthreads -NoAsyncLoadingThread -UseMultithreadForDS"
    Write-Host "["$(Get-Date)"] " "Server Started."; "["+$(Get-Date)+"] " + "Server Started." | Out-File -FilePath "$PSScriptRoot\$log_file" -Append
    check_program
}

function backup_server {
    if (!(Test-Path -PathType Container "$PalworldFolder\Pal\Saved\SaveGames\Backups")){ 
        New-Item -ItemType Directory -Path "$PalworldFolder\Pal\Saved\SaveGames\Backups" -ErrorAction Stop
    }
    $date_time = Get-Date -format 'yyyy_MM-dd_dddd_hh_mm_tt'
    # Perform the Robocopy operation
    try {
        $robocopyArgs = @(
            "$PalworldFolder\Pal\Saved\SaveGames\0",
            "$PalworldFolder\Pal\Saved\SaveGames\Backups\$date_time",
            "/mir", "/b", "/r:0", "/copyall", "/dcopy:dat",
            "/xd", "'$Recycle.bin', 'system volume information'",
            "/xf", "'thumbs.db'",
            "/NFL", "/NDL", "/NJH", "/NJS", "/nc", "/ns", "/np",
            "/COPY:DAT"
        )
        Start-Process -FilePath "robocopy.exe" -ArgumentList $robocopyArgs -Wait -NoNewWindow -ErrorAction Stop

        # Get the destination folder path
        $destinationFolder = "$PalworldFolder\Pal\Saved\SaveGames\Backups\$date_time"

        # Update the "Date Modified" attribute of the destination folder
        (Get-Item $destinationFolder).LastWriteTime = Get-Date

        Write-Host "["$(Get-Date)"] " "Server Backup Complete."; "["+$(Get-Date)+"] " + "Server Backup Complete." | Out-File -FilePath "$PSScriptRoot\$log_file" -Append
    } 
    catch {
        Write-Host "Error occurred during Robocopy: $_"
    }

}

function Broadcast-Message {
    $message = $args[0]
    # Send RCON message using ARRCON.exe
    & $arrconPath -H $rconHost -P $rconPort -p $rconPassword "broadcast $message"
}

# Start the main loop
check_program