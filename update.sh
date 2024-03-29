#!/usr/bin/env bash
#===================================================================================
# ts3-autoupdater - A simple bash script to auto-update a TeamSpeak Server.
#
# Usage: ./update.sh [-h] [-d SERVER_DIR] [-b BACKUP_DIR]
#
# Options:
# -h, --help -> Show help message and exit.
# -d, --directory SERVER_DIR -> Specify the server directory. Default: script's directory.
# -b, --backup BACKUP_DIR  -> Specify the backup folder. Default: SERVER_DIR/backups.
#===================================================================================

[[ -v debug ]] && set -x
set -e

server_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
backup_dir="$server_dir/backups"

trap \
  "{ cleanup ;}" \
  SIGINT SIGTERM ERR EXIT

#---- Delete temporary dl dir (if it exists)
function cleanup() { if [[ -d $tmpdir ]]; then rm -rf "$tmpdir"; fi; }

#---- Get newest ts3 server download url 
function get_url() {
  if uname -m | grep '64'; then
    url="https://files.teamspeak-services.com/releases/server/$latest_version/teamspeak3-server_linux_amd64-$latest_version.tar.bz2"
  else
    url="https://files.teamspeak-services.com/releases/server/$latest_version/teamspeak3-server_linux_x86-$latest_version.tar.bz2"
  fi
  update
}

#---- Check for updates
function check() {
  cd "$server_dir" || exit 1
  latest_version=$(curl -Ls 'https://www.teamspeak.com/versions/server.json' | jq -r 'first(.[] | .[] | .version)')
  readonly latest_version
  if [[ -f "ts3server" ]]; then
    current_version=$(./ts3server | sed -n 's/.*TeamSpeak 3 Server \([0-9.]\+\).*/\1/p;q')
    readonly current_version
    if [[ $current_version = "$latest_version" ]]; then
      printf "[%s] Server already running on the latest version ($latest_version).\n" "$(date +%c)"
      exit 0
    else
      printf "[%s] New version $latest_version found. Updating...\n" "$(date +%c)"
      get_url
    fi
  else
    printf "[%s] ERROR: Could not find current server version.\n" "$(date +%c)" >&2
    exit 1
  fi
}

#---- Update ts3 server
function update() {
  if pgrep -f ts3server &> /dev/null 2>&1; then
    printf "[%s] Stopping TS3 Server...\n" "$(date +%c)"
    pkill -f ts3server
  fi
  if [[ "$backp" = false ]]; then
    backup_dir="$server_dir/backups"
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

#---- Show help
function help() {
  cat << EOF
Usage: $(basename "$0") [-h] [-d SERVER_DIR] [-b BACKUP_DIR]

Options:
-h, --help                   Show this help message and exit.
-d, --directory              Specify the server directory. 
-b, --backup                 Specify the backup directory
EOF
}

#---- Parse arguments
backp=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      help
      exit 0
      ;;
    -d|--directory)
      if [[ $# -lt 2 ]]; then
        printf "ERROR: Missing argument for %s\n" "$1" >&2
        help
        exit 1
      fi
      server_dir="$2"
      if [[ ! -d "$server_dir" ]]; then
        printf "ERROR: Could not find server directory.\n" >&2
        exit 1
      fi
      shift
      ;;
    -b|--backup)
      if [[ $# -lt 2 ]]; then
        printf "ERROR: Missing argument for %s\n" "$1" >&2
        help
        exit 1
      fi
      backup_dir="$2"
      backp=true
      shift
      ;;
    *)
      printf "ERROR: Invalid option %s\n" "$1" >&2
      help
      exit 1
      ;;
  esac
  shift
done

check
