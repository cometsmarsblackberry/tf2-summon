#!/bin/bash

generate_admins() {
  local admins_file="${SERVER_DIR}/tf/addons/sourcemod/configs/admins_simple.ini"
  if [ -n "$SM_ADMINS" ]; then
    mkdir -p "$(dirname "$admins_file")"
    echo "// Generated from SM_ADMINS environment variable" > "$admins_file"
    IFS=',' read -ra STEAM_IDS <<< "$SM_ADMINS"
    for steam_id in "${STEAM_IDS[@]}"; do
      steam_id=$(echo "$steam_id" | xargs)
      [ -n "$steam_id" ] && echo "\"$steam_id\" \"99:z\"" >> "$admins_file"
    done
  fi
}

auto_envsubst() {
  local template_dir="${SERVER_DIR}/tf/cfg"
  local suffix=".template"

  find "$template_dir" -follow -type f -name "*$suffix" -print | while read -r template; do
    output_file="${template%"$suffix"}"
    envsubst < "${template}" > "${output_file}"
  done
}

faketty() {
  # https://stackoverflow.com/questions/1401002/how-to-trick-an-application-into-thinking-its-stdout-is-a-terminal-not-a-pipe/60279429#60279429
  tmp=$(mktemp)
  [ "$tmp" ] || return 99
  cmd="$(printf '%q ' "$@")"'; echo $? > '$tmp
  script -qfc "/bin/sh -c $(printf "%q " "$cmd")" /dev/null
  [ -s "$tmp" ] || return 99
  err=$(cat "$tmp")
  rm -f "$tmp"
  return "$err"
}

quit() {
  echo "*** Stopping ***"
  # The pinned client sends the command but returns nonzero in no-wait mode.
  "${SERVER_DIR}/rcon" -H "${IP/0.0.0.0/127.0.0.1}" -p "${PORT}" -P "${RCON_PASSWORD}" --nowait quit || true
  sleep 5
  exit 0
}

trap 'quit' SIGTERM

generate_motd() {
  if [ -n "$MOTD_URL" ]; then
    local motd_file="${SERVER_DIR}/tf/cfg/motd.txt"
    echo "$MOTD_URL" > "$motd_file"
    export MOTD="cfg/motd.txt"
  fi
}

generate_motd
auto_envsubst
generate_admins

# enablefakeip switch
if [ "$ENABLE_FAKE_IP" = "1" ]; then
  fake_ip_args=(-enablefakeip)
else
  fake_ip_args=()
fi

steam_account_args=()
if [ -n "${SERVER_TOKEN}" ]; then
  steam_account_args=(+sv_setsteamaccount "${SERVER_TOKEN}")
fi

faketty "${SERVER_DIR}/${SRCDS_EXEC}" \
  -game tf \
  -secured \
  "${fake_ip_args[@]}" \
  -steam_dir "${HOME}/.steam/steamcmd" \
  -steamcmd_script "${HOME}/tf2.txt" \
  -autoupdate \
  "${steam_account_args[@]}" \
  -ip "${IP}" \
  -port "${PORT}" \
  +clientport "${CLIENT_PORT}" \
  -steamport "${STEAM_PORT}" \
  +tv_port "${STV_PORT}" \
  -strictportbind \
  -norestart \
  "$@" & wait "$!"
