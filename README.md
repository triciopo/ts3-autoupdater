# TS3-Autoupdater
> A simple TS3 Server Auto Updater.

ts3-autoupdater is a simple bash script that automates the process of updating your Teamspeak 3 server. You can run the script manually or set it up to run automatically using crontab or systemd.

## Setting up
Download the script using curl by running the following command in your terminal:

```bash
$ curl -Ls https://raw.githubusercontent.com/triciopo/ts3-autoupdater/master/update.sh -o update.sh
```
Make the script executable by running the following command:
```bash
$ chmod +x update.sh
```
### Using crontab:
To install using crontab, follow these steps:
```bash
$ crontab -e
```
Add the following line to the file:
```bash
# This will make the script run once a week (on sunday).
0 0  *  *  SUN  /bin/bash  /path/to/updater.sh >> path/to/updater.log 2>&1
```

Checkout [crontab guru](https://crontab.guru) for easy crontab configuration.

## Options
The following options are available:
```bash
Usage: update.sh [-h] [-d SERVER_DIR] [-b BACKUP_DIR]

Options:
-h, --help                   Show this help message and exit.
-d, --directory              Specify the server directory.
-b, --backup                 Specify the backup directory. 
```
Example:
```bash
./update.sh --directory /opt/teamspeak3/server --backup /opt/teamspeak3/backups
```

This will update the TeamSpeak 3 server installed in /opt/teamspeak3/server and save a backup of the server in /opt/teamspeak3/backups before updating.
