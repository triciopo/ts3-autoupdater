#!/usr/bin/env bash
[[ -v debug ]] && set -x

trap \
  "{ cleanup ;}" \
  SIGINT SIGTERM ERR EXIT

function cleanup() { if [[ -d $tmpdir ]]; then rm -rf $tmpdir; fi; }

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
  readonly version=$(curl -Ls 'https://www.teamspeak.com/versions/server.json' | jq -r 'first(.[] | .[] | .version)')
  case $(grep -F "$version" "CHANGELOG" >/dev/null; echo $?) in
    0)
      printf "[%s] Server already running on the latest version ($version).\n" "$(date +%c)"
      ;;
  	1)
      printf "[%s] New version $version found. Updating...\n" "$(date +%c)"
	    getURL
      ;;
    *)
	    exit 1
      ;;
  esac
}

#---- Update ts3 server
function update() {
  if pgrep -f ts3server &> /dev/null 2>&1; then
    printf "[%s] Stopping TS3 Server...\n" "$(date +%c)"
    ./ts3server_startscript.sh stop
  fi
  if [[ ! -d "backups" ]]; then
    mkdir backups
  fi
  #Backup folder
  tar --exclude='backups' --overwrite -cf backups/$(date +%F).tar *
  # Download and install new update
  tmpdir=$(mktemp -d /tmp/ts3auto.XXXXX)
  curl -Ls $url -o $tmpdir/ts3.tar.bz2 
  tar -xf $tmpdir/ts3.tar.bz2 -C $tmpdir
  cp -a $tmpdir/teamspeak3-server_linux_amd64/. .
  printf "[%s] Update complete. Backup saved on: $(pwd)/backup\n" "$(date +%c)"
}

cd "$(dirname "$0")" || exit
check
