{
    "_meta": {
        "version": "1.0",
        "strict": false,
        "description": "Sample configuration settings for PlexBackup.ps1."
    },
    "Mode": {
        "_meta": {
            "set": "Backup,Continue,Restore",
            "default": "Backup"
        },
        "value": null
    },
    "Type": {
        "_meta": {
            "set": ",7zip,Robocopy",
            "default": ""
        },
        "value": "7zip"
    },
    "PlexAppDataDir": {
        "_meta": {
            "default": "$env:LOCALAPPDATA\\Plex Media Server"
        },
        "value": null
    },
    "BackupRootDir": {
        "value": "D:\\PlexBackup"
    },
    "BackupDirPath": {
        "value": null
    },
    "TempZipFileDir": {
        "_meta": {
            "default": "$env:TEMP"
        },
        "hasValue": false,
        "value": null
    },
    "PlexRegKey": {
        "value": null
    },
    "ExcludePlexAppDataDirs": {
        "_meta": {
            "default": ["Diagnostics","Crash Reports","Updates","Logs"]
        },
        "value": null
    },
    "ExcludePlexAppDataFiles": {
        "_meta": {
            "default": ["*.bif"]
        },
        "value": null
    },
    "SpecialPlexAppDataSubDirs": {
        "_meta": {
            "default": ["Plug-in Support\\Data\\com.plexapp.system\\DataItems\\Deactivated"]
        },
        "value": null
    },
    "PlexServiceNameMatchString": {
        "_meta": {
            "default": "^Windows Push Notifications"
        },
        "hasValue": false,
        "value": null
    },
    "PlexServerExeFileName": {
        "_meta": {
            "default": "Plex Media Server.exe"
        },
    "value": "workpace.exe"
    },
    "PlexServerExePath": {
        "value": null
    },
    "Keep": {
        "_meta": {
            "range": "0-[int]::MaxValue",
            "default": "3"
        },
        "value": 2
    },
    "Retries": {
        "_meta": {
            "range": "0-[int]::MaxValue",
            "default": "5"
        },
        "value": null
    },
    "RetryWaitSec": {
        "_meta": {
            "range": "0-[int]::MaxValue",
            "default": "10"
        },
        "value": null
    },
    "Log": {
        "value": true
    },
    "LogAppend": {
        "value": null
    },
    "LogFile": {
        "value": null
    },
    "ErrorLog": {
        "value": true
    },
    "ErrorLogAppend": {
        "value": null
    },
    "ErrorLogFile": {
        "value": null
    },
    "Shutdown": {
        "value": null
    },
    "Inactive": {
        "value": null
    },
    "Force": {
        "value": null
    },
    "SendMail": {
        "_meta": {
            "set": "Never,Always,OnError,OnSuccess,OnBackup,OnBackupError,OnBackupSuccess,OnRestore,OnRestoreError,OnRestoreSuccess",
            "default": "Never"
        },
        "value": null
    },
    "From": {
        "value": null
    },
    "To": {
        "value": null
    },
    "SmtpServer": {
        "value": "smtp.gmail.com"
    },
    "Port": {
        "_meta": {
            "range": "0-[int]::MaxValue",
            "default": "0"
        },
        "value": 587
    },
    "UseSsl": {
        "value": true
    },
    "CredentialFile": {
        "value": null
    },
    "PromptForCredential": {
        "value": true
    },
    "SaveCredential": {
        "value": true
    },
    "Anonymous": {
        "value": null
    },
    "SendLogFile": {
        "_meta": {
            "set": "Never,OnError,OnSuccess,Always",
            "default": "Never"
        },
        "value": null
    },
    "ArchiverPath": {
        "_meta": {
            "default": "$env:ProgramFiles\\7-Zip\\7z.exe"
        },
        "value": null
    }
}
