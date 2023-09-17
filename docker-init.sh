#!/bin/bash
login_help() {
  sleep 1 
  LISTEN=$(netstat -antp 2>/dev/null |grep login|awk '{print $4}')
  echo ""
  echo "1. Make sure to setup a SSH tunnel first, from a machine with a browser to the docker host machine." 
  echo "ssh -L $LISTEN:$LISTEN $HOSTNAME"
  echo
  echo "2. Then paste the URL above into the browser (i.e. LOGIN|<url>|)"
  echo
  echo "The auth.tpz (license) will be in a subdirectory ./auth/ on the host."
  echo "Make sure this file is mounted (or copied) to /opt/TopazVideoAIBETA/models in the container at runtime."
  echo
}

login() {
  login_help&
  /opt/TopazVideoAIBETA/bin/login
  auth_file="${TVAI_MODEL_DIR}/auth.tpz"
  [ -f "${auth_file}" ] || {
    echo "Authentication failed: auth.tpz not minted by the login program"
    exit 1
  }
  cp "${auth_file}" /auth/
  echo "Success: auth file now present on the host in ./auth/"
}

case $1 in
  login) login ;;
  *) exec "$@" ;;
esac

