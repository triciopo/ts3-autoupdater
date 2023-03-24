#!/usr/bin/env bash
#
# ts3-autoupdater - A simple bash script to auto-update a TeamSpeak Server.
#
# Usage: ./update.sh [-d SERVER_DIR] [-b BACKUP_DIR]
#
# Options:
# -d SERVER_DIR -> Specify the server directory. Default: script's directory.
# -b BACKUP_DIR  -> Specify the backup folder. Default: script's directory/backups.
#

[[ -v debug ]] && set -x

server_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
backup_dir="$server_dir/backups"

trap \
  "{ cleanup ;}" \
  SIGINT SIGTERM ERR EXIT

#---- Delete temporary dl dir (if it exists)
function cleanup() { if [[ -d $tmpdir ]]; then rm -rf "$tmpdir"; fi; }

#---- Get newest ts3 server download url 
function getURL() {
  if uname -m | grep '64'; then
    url="https://files.teamspeak-services.com/releases/server/$version/teamspeak3-server_linux_amd64-$version.tar.bz2"
  else
	url="https://files.teamspeak-services.com/releases/server/$version/teamspeak3-server_linux_x86-$version.tar.bz2"
  fi
	update
}

#---- Check for updates
function check() {
  cd "$server_dir" || exit 1
  version=$(curl -Ls 'https://www.teamspeak.com/versions/server.json' | jq -r 'first(.[] | .[] | .version)')
  readonly version
  if [[ -f "CHANGELOG" ]]; then
    case $(grep -F "$version" "CHANGELOG" >/dev/null; echo $?) in
      0)
        printf "[%s] Server already running on the latest version ($version).\n" "$(date +%c)" 
        ;;
      1)
        printf "[%s] New version $version found. Updating...\n" "$(date +%c)"
    	  getURL
        ;;
      *)
    	  exit 1 ;;
      esac
  else
    printf "[%s] Could not find current server version.\n" "$(date +%c)" >&2
    exit 1
  fi
}

#---- Update ts3 server
function update() {
  if pgrep -f ts3server &> /dev/null 2>&1; then
    printf "[%s] Stopping TS3 Server...\n" "$(date +%c)"
    pkill -f ts3server
  fi
  if [[ ! -d $backup_dir ]]; then
    printf "[%s] Creating backup dir $OPTARG\n" "$(date +%c)"
    mkdir "$backup_dir" || exit 1
  fi
  #Backup old server
  tar --exclude='backups' --overwrite -cf "$backup_dir"/"$(date +%F)".tar -- *
  # Download and install new update
  tmpdir=$(mktemp -d /tmp/ts3auto.XXXXX)
  curl -Ls "$url" -o "$tmpdir"/ts3.tar.bz2 
  tar -xf "$tmpdir"/ts3.tar.bz2 -C "$tmpdir"
  cp -a "$tmpdir"/teamspeak3-server_linux_amd64/. .
  ./ts3server_startscript.sh start
  printf "[%s] Update complete. Backup saved on: $backup_dir\n" "$(date +%c)"
}

# Options
while getopts ":d:b:" opt; do
  case $opt in
    d)
      server_dir=$(realpath "$OPTARG")
      if [[ ! -d $server_dir ]]; then
        printf "[%s] Could not find working folder.\n" "$(date +%c)" >&2 && exit 1 
      fi ;;
    b) backup_dir="$OPTARG" ;;
    *) printf "[%s] Invalid argument -%s\n" "$(date +%c)" "$OPTARG" >&2 && exit 1 ;;
  esac
done

check
