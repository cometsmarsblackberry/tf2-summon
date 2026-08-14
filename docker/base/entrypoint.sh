#!/bin/bash

START_MAP_FALLBACK="cp_badlands"
START_MAP_HEADER_BYTES=1036
START_MAP_MIN_BYTES=$((START_MAP_HEADER_BYTES + 1))
START_MAP_MAX_BYTES=$((512 * 1024 * 1024))
# Leave enough of the agent's 90-second readiness deadline for SRCDS itself.
# timeout's five-second kill grace makes the worst case approximately 30 seconds.
START_MAP_DOWNLOAD_TIMEOUT=25
START_MAP_DOWNLOAD_PID=""
START_MAP_DOWNLOAD_PGID=""
START_MAP_DOWNLOAD_FILE=""

is_safe_map_name() {
  [[ "$1" =~ ^[A-Za-z0-9_]{1,64}$ ]]
}

is_valid_bsp() {
  local bsp_file="$1"
  local bsp_size
  local bsp_magic
  local bsp_version

  [ -f "$bsp_file" ] || return 1
  bsp_size="$(stat -c '%s' -- "$bsp_file" 2>/dev/null)" || return 1
  [ "$bsp_size" -ge "$START_MAP_MIN_BYTES" ] || return 1
  [ "$bsp_size" -le "$START_MAP_MAX_BYTES" ] || return 1
  bsp_magic="$(od -An -t x1 -N 4 -- "$bsp_file" 2>/dev/null | tr -d '[:space:]')" || return 1
  [ "$bsp_magic" = "56425350" ] || return 1
  bsp_version="$(od -An -t u4 -j 4 -N 4 -- "$bsp_file" 2>/dev/null | tr -d '[:space:]')" || return 1
  [ "$bsp_version" = "20" ] || return 1

  # A Source BSP header contains 64 sixteen-byte lump descriptors. Requiring a
  # populated lump and checking every populated range prevents a short file
  # with only a forged VBSP prefix from replacing the bundled fallback map.
  od -An -v -t u4 -j 8 -N 1024 -- "$bsp_file" 2>/dev/null |
    awk -v size="$bsp_size" -v header="$START_MAP_HEADER_BYTES" '
      BEGIN { lumps = 0; populated = 0 }
      {
        for (field = 1; field + 3 <= NF; field += 4) {
          lump_offset = $field
          lump_length = $(field + 1)
          lumps++
          if (lump_length > 0) {
            populated++
            if (lump_offset < header || lump_offset + lump_length > size) {
              exit 1
            }
          }
        }
      }
      END { if (lumps != 64 || populated == 0) exit 1 }
    '
}

run_start_map_download() {
  local output_file="$1"
  local download_url="$2"
  local original_file_limit
  local original_core_limit
  local download_file_limit=$(((START_MAP_MAX_BYTES + 1023) / 1024))
  local download_status

  original_file_limit="$(ulimit -S -f)" || return 1
  original_core_limit="$(ulimit -S -c)" || return 1
  if [ "$original_file_limit" != "unlimited" ] &&
    [ "$original_file_limit" -lt "$download_file_limit" ]; then
    download_file_limit="$original_file_limit"
  fi
  ulimit -S -f "$download_file_limit" || return 1
  ulimit -S -c 0 || {
    ulimit -S -f "$original_file_limit" || true
    return 1
  }

  # Run timeout directly in the background so shutdown can signal it while the
  # shell is waiting. The child inherits the temporary file-size ceiling.
  setsid timeout --signal=TERM --kill-after=5s "$START_MAP_DOWNLOAD_TIMEOUT" \
    wget --quiet --timeout=30 --tries=1 --max-redirect=5 \
      --output-document="$output_file" -- "$download_url" &
  START_MAP_DOWNLOAD_PID=$!
  START_MAP_DOWNLOAD_PGID="$START_MAP_DOWNLOAD_PID"
  START_MAP_DOWNLOAD_FILE="$output_file"

  if ! ulimit -S -f "$original_file_limit" ||
    ! ulimit -S -c "$original_core_limit"; then
    cancel_start_map_download
    return 1
  fi

  if wait "$START_MAP_DOWNLOAD_PID"; then
    download_status=0
  else
    download_status=$?
  fi
  START_MAP_DOWNLOAD_PID=""
  START_MAP_DOWNLOAD_PGID=""
  START_MAP_DOWNLOAD_FILE=""
  return "$download_status"
}

cancel_start_map_download() {
  local download_pid="${START_MAP_DOWNLOAD_PID:-}"
  local download_pgid="${START_MAP_DOWNLOAD_PGID:-}"
  local attempt

  if [ -n "$download_pgid" ]; then
    if ! kill -TERM -- "-$download_pgid" 2>/dev/null; then
      # setsid may not have established the new group yet. The known wrapper
      # PID remains safe to signal during that narrow launch window.
      kill -TERM "$download_pid" 2>/dev/null || true
    fi
    for ((attempt = 0; attempt < 20; attempt++)); do
      kill -0 -- "-$download_pgid" 2>/dev/null || break
      sleep 0.1
    done
    if kill -0 -- "-$download_pgid" 2>/dev/null; then
      kill -KILL -- "-$download_pgid" 2>/dev/null || true
    fi
  elif [ -n "$download_pid" ]; then
    kill -TERM "$download_pid" 2>/dev/null || true
  fi
  if [ -n "$download_pid" ]; then
    wait "$download_pid" 2>/dev/null || true
  fi
  START_MAP_DOWNLOAD_PID=""
  START_MAP_DOWNLOAD_PGID=""
  if [ -n "${START_MAP_DOWNLOAD_FILE:-}" ]; then
    rm -f -- "$START_MAP_DOWNLOAD_FILE"
    START_MAP_DOWNLOAD_FILE=""
  fi
}

download_start_map() {
  local map_name="$1"
  local maps_dir="${SERVER_DIR}/tf/maps"
  local map_file="${maps_dir}/${map_name}.bsp"
  local download_base="${SM_MAP_DOWNLOAD_BASE:-}"
  local download_file

  if is_valid_bsp "$map_file"; then
    echo "*** Startup map ${map_name} is already available ***"
    return 0
  fi

  if [ -z "$download_base" ]; then
    echo "*** Cannot download startup map ${map_name}: SM_MAP_DOWNLOAD_BASE is empty ***" >&2
    return 1
  fi

  download_file="$(mktemp "${maps_dir}/.${map_name}.bsp.tmp.XXXXXX")" || {
    echo "*** Cannot create a temporary file for startup map ${map_name} ***" >&2
    return 1
  }

  echo "*** Downloading startup map ${map_name} before launching TF2 ***"
  if ! run_start_map_download \
    "$download_file" "${download_base%/}/${map_name}.bsp"; then
    echo "*** Failed to download startup map ${map_name} ***" >&2
    rm -f -- "$download_file"
    return 1
  fi

  if ! is_valid_bsp "$download_file"; then
    echo "*** Downloaded startup map ${map_name} is not a valid BSP ***" >&2
    rm -f -- "$download_file"
    return 1
  fi

  if ! chmod 0644 -- "$download_file"; then
    echo "*** Failed to set permissions on startup map ${map_name} ***" >&2
    rm -f -- "$download_file"
    return 1
  fi
  if ! mv -f -- "$download_file" "$map_file"; then
    echo "*** Failed to install startup map ${map_name} ***" >&2
    rm -f -- "$download_file"
    return 1
  fi

  echo "*** Startup map ${map_name} is ready ***"
}

set_start_map_argument() {
  local map_name="$1"
  local index
  local -a normalized_args=()

  for ((index = 0; index < ${#srcds_args[@]}; index++)); do
    if [ "${srcds_args[$index]}" = "+map" ]; then
      if ((index + 1 < ${#srcds_args[@]})); then
        index=$((index + 1))
      fi
      continue
    fi
    normalized_args+=("${srcds_args[$index]}")
  done

  srcds_args=("${normalized_args[@]}" "+map" "$map_name")
}

prepare_start_map() {
  local requested_map="${SUMMON_START_MAP:-}"
  local selected_map="$START_MAP_FALLBACK"

  # An empty value preserves the image's existing command-line behavior. This
  # makes the variable safe to deploy before all hosts have pulled this image.
  [ -n "$requested_map" ] || return 0

  if ! is_safe_map_name "$requested_map"; then
    echo "*** Invalid SUMMON_START_MAP; using ${START_MAP_FALLBACK} ***" >&2
  elif download_start_map "$requested_map"; then
    selected_map="$requested_map"
  else
    echo "*** Startup map ${requested_map} is unavailable; using ${START_MAP_FALLBACK} ***" >&2
  fi

  set_start_map_argument "$selected_map"
}

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
  trap '' SIGTERM
  echo "*** Stopping ***"
  if [ -n "${START_MAP_DOWNLOAD_PID:-}" ] ||
    [ -n "${START_MAP_DOWNLOAD_FILE:-}" ]; then
    cancel_start_map_download
    # SRCDS has not started yet, so there is no RCON shutdown grace to honor.
    exit 0
  fi
  # Authentication can still block in no-wait mode, so do not let the RCON
  # request consume Summon's ten-second container stop deadline.
  "${SERVER_DIR}/rcon" -H "${IP/0.0.0.0/127.0.0.1}" -p "${PORT}" -P "${RCON_PASSWORD}" --nowait quit </dev/null >/dev/null 2>&1 &
  sleep 5
  exit 0
}

generate_motd() {
  if [ -n "$MOTD_URL" ]; then
    local motd_file="${SERVER_DIR}/tf/cfg/motd.txt"
    echo "$MOTD_URL" > "$motd_file"
    export MOTD="cfg/motd.txt"
  fi
}

main() {
  trap 'quit' SIGTERM

  generate_motd
  auto_envsubst
  generate_admins

  srcds_args=("$@")
  prepare_start_map

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
    "${srcds_args[@]}" & wait "$!"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
