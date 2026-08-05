#!/usr/bin/env bash
set -Eeuo pipefail

image_name="${1:-tf2-summon:local}"
container_name="tf2-summon-contract-${RANDOM}-$$"
container_runtime="${CONTAINER_RUNTIME:-docker}"
summon_exact="${SUMMON_EXACT:-0}"
rcon_password="summon-rcon-test"
wait_status_file=""

report_failure() {
  local status="$1"
  local line="$2"
  local command="$3"

  trap - ERR
  echo "Image contract failed with status ${status} at line ${line}: ${command}" >&2
  if "${container_runtime}" container inspect "${container_name}" >/dev/null 2>&1; then
    "${container_runtime}" logs "${container_name}" >&2 || true
  fi
  exit "${status}"
}

case "${summon_exact}" in
  0)
    port_args=(-p 27015/tcp -p 27015/udp -p 27020/udp)
    enable_fake_ip=0
    ;;
  1)
    port_args=(-p 27015:27015/tcp -p 27015:27015/udp -p 27020:27020/udp)
    enable_fake_ip=1
    ;;
  *)
    echo "SUMMON_EXACT must be 0 or 1" >&2
    exit 1
    ;;
esac

command -v "${container_runtime}" >/dev/null 2>&1 || {
  echo "Container runtime not found: ${container_runtime}" >&2
  exit 1
}

cleanup() {
  "${container_runtime}" rm -f "${container_name}" >/dev/null 2>&1 || true
  if [ -n "${wait_status_file}" ]; then
    rm -f "${wait_status_file}"
  fi
}
trap 'report_failure "$?" "$LINENO" "$BASH_COMMAND"' ERR
trap cleanup EXIT

test "$("${container_runtime}" image inspect --format '{{.Config.User}}' "${image_name}")" = "tf2"
test "$("${container_runtime}" image inspect --format '{{.Config.WorkingDir}}' "${image_name}")" = "/home/tf2/server"
test "$("${container_runtime}" image inspect --format '{{json .Config.Entrypoint}}' "${image_name}")" = '["./entrypoint.sh"]'
test "$("${container_runtime}" image inspect --format '{{json .Config.Cmd}}' "${image_name}")" = '["+sv_pure","1","+map","cp_badlands","+maxplayers","24"]'

# The quoted script expands variables inside the container, not in this shell.
# shellcheck disable=SC2016
"${container_runtime}" run --rm --entrypoint bash "${image_name}" -lc '
  set -Eeuo pipefail
  trap "status=\$?; echo \"Static image contract failed at line \${LINENO}: \${BASH_COMMAND}\" >&2; exit \${status}" ERR

  test -x /home/tf2/server/rcon
  test -d /home/tf2/server/tf
  test -f /home/tf2/server/tf/maps/cp_badlands.bsp
  test "$(find /home/tf2/server/tf/maps -maxdepth 1 -type f -name "*.bsp" | wc -l)" -eq 1
  test -f /home/tf2/server/tf/addons/metamod.vdf
  test -d /home/tf2/server/tf/addons/sourcemod
  test -f /home/tf2/server/tf/addons/sourcemod/plugins/summon.smx
  test -f /home/tf2/server/tf/addons/sourcemod/plugins/mapdownloader.smx
  test -f /home/tf2/server/tf/addons/sourcemod/extensions/rip.ext.so
  test -f /home/tf2/server/tf/cfg/summon_reset.cfg
  test -f /home/tf2/server/tf/cfg/rgl_6s_5cp_match.cfg
  test -f /home/tf2/server/tf/cfg/etf2l_6v6_5cp.cfg
  test -f /home/tf2/server/tf/cfg/fbtf_6v6_5cp.cfg
  test -f /home/tf2/server/tf/cfg/ozfortress_6v6_5cp.cfg
  test -f /home/tf2/server/tf/cfg/ultitrio_match.cfg
  test -f /home/tf2/server/tf/addons/sourcemod/plugins/disabled/nextmap.smx
  test -f /home/tf2/server/tf/addons/sourcemod/plugins/disabled/config_checker.smx
  test -f /home/tf2/server/tf/addons/sourcemod/plugins/disabled/rglupdater.smx

  printf "%s  %s\n" \
    bc56591d3abc55c7b9f164f8e9ca4d49c7cdd9f363049a65d19eee0ee0d9d380 /home/tf2/server/tf/addons/sourcemod/plugins/mapdownloader.smx \
    afb269af47a8dde925b85ac039159ab8540237dfec44cba6a851f7c944ba1877 /home/tf2/server/tf/addons/sourcemod/plugins/summon.smx \
    | sha256sum -c -

  ldd /home/tf2/server/rcon | tee /tmp/rcon-ldd
  ! grep -Fq "not found" /tmp/rcon-ldd

  cfg_list="$(sh -lc "ls -1 /home/tf2/server/tf/cfg/*.cfg 2>/dev/null || true")"
  grep -Fq "/home/tf2/server/tf/cfg/summon_reset.cfg" <<<"${cfg_list}"
  grep -Fq "/home/tf2/server/tf/cfg/rgl_6s_5cp_match.cfg" <<<"${cfg_list}"
'

"${container_runtime}" run -d \
  --name "${container_name}" \
  --rm \
  "${port_args[@]}" \
  -e SERVER_PASSWORD=join-test \
  -e RCON_PASSWORD="${rcon_password}" \
  -e STV_PASSWORD=stv-test \
  -e 'SERVER_HOSTNAME=Summon Contract Test' \
  -e STV_NAME=SourceTV \
  -e 'STV_TITLE=Summon Contract SourceTV' \
  -e ENABLE_FAKE_IP="${enable_fake_ip}" \
  -e DOWNLOAD_URL=https://fastdl.example.invalid/ \
  -e SM_MAP_DOWNLOAD_BASE=https://fastdl.example.invalid/maps/ \
  -e DEMOS_TF_APIKEY= \
  -e LOGS_TF_APIKEY= \
  -e MOTD_URL=https://example.invalid/motd/contract \
  -e 'SM_ADMINS=STEAM_0:1:12345,STEAM_0:0:67890' \
  "${image_name}" \
  +map cp_badlands >/dev/null

rcon=(
  "${container_runtime}" exec "${container_name}"
  /home/tf2/server/rcon
  -H 127.0.0.1
  -p 27015
  -P "${rcon_password}"
)

deadline=$((SECONDS + 60))
status_output=""
until status_output="$("${rcon[@]}" status 2>/dev/null)"; do
  if (( SECONDS >= deadline )); then
    "${container_runtime}" logs "${container_name}" >&2 || true
    echo "RCON did not become ready within 60 seconds" >&2
    exit 1
  fi
  sleep 1
done

grep -Fq "hostname: Summon Contract Test" <<<"${status_output}"
grep -Eq 'map[[:space:]]*:[[:space:]]*cp_badlands' <<<"${status_output}"

plugin_output="$("${rcon[@]}" 'sm plugins list')"
grep -Fqi 'Summon' <<<"${plugin_output}"
grep -Fqi 'Map Downloader' <<<"${plugin_output}"

"${rcon[@]}" 'sm_reserve_owner "76561198000000000"' >/dev/null
"${rcon[@]}" 'sm_reserve_owner_name "Contract Owner"' >/dev/null
"${rcon[@]}" 'sm_reserve_number "42"' >/dev/null
"${rcon[@]}" 'sm_reserve_ends_at "2000000000"' >/dev/null
"${rcon[@]}" 'sm_reserve_backend_url "https://example.invalid"' >/dev/null
"${rcon[@]}" 'sm_reserve_api_key "contract-key"' >/dev/null
"${rcon[@]}" 'sm_config summon_reset' >/dev/null

# The quoted script expands variables inside the container, not in this shell.
# shellcheck disable=SC2016
"${container_runtime}" exec "${container_name}" bash -lc '
  set -Eeuo pipefail
  trap "status=\$?; echo \"Runtime configuration contract failed at line \${LINENO}: \${BASH_COMMAND}\" >&2; exit \${status}" ERR
  grep -Fq "hostname \"Summon Contract Test\"" /home/tf2/server/tf/cfg/server.cfg
  grep -Fq "rcon_password \"summon-rcon-test\"" /home/tf2/server/tf/cfg/server.cfg
  grep -Fq "tv_name \"SourceTV\"" /home/tf2/server/tf/cfg/server.cfg
  grep -Fq "tv_title \"Summon Contract SourceTV\"" /home/tf2/server/tf/cfg/server.cfg
  grep -Fq "tv_password \"stv-test\"" /home/tf2/server/tf/cfg/server.cfg
  grep -Fq "sm_cvar sm_map_download_base \"https://fastdl.example.invalid/maps/\"" /home/tf2/server/tf/cfg/server.cfg
  test -f /home/tf2/server/tf/cfg/sourcemod/sm_autoreload.cfg
  test ! -e /home/tf2/server/tf/cfg/sm_autoreload.cfg
  grep -Fxq "https://example.invalid/motd/contract" /home/tf2/server/tf/cfg/motd.txt
  grep -Fq "\"STEAM_0:1:12345\" \"99:z\"" /home/tf2/server/tf/addons/sourcemod/configs/admins_simple.ini
  grep -Fq "\"STEAM_0:0:67890\" \"99:z\"" /home/tf2/server/tf/addons/sourcemod/configs/admins_simple.ini
  test -d /home/tf2/server/tf/addons/sourcemod/logs
  test -d /home/tf2/server/tf/logs
'

# Reproduce the pinned client's unbounded authentication wait. The entrypoint
# must keep PID 1's shutdown bounded even when its best-effort RCON helper hangs.
# The quoted script expands SERVER_DIR inside the container, not in this shell.
# shellcheck disable=SC2016
"${container_runtime}" exec "${container_name}" bash -lc '
  mv "${SERVER_DIR}/rcon" "${SERVER_DIR}/rcon-real"
  printf "#!/bin/sh\nsleep 60\n" > "${SERVER_DIR}/rcon"
  chmod 755 "${SERVER_DIR}/rcon"
'

wait_status_file="$(mktemp)"
"${container_runtime}" wait "${container_name}" >"${wait_status_file}" &
wait_pid=$!
"${container_runtime}" stop -t 10 "${container_name}" >/dev/null
wait "${wait_pid}"
wait_status="$(cat "${wait_status_file}")"
if [ "${wait_status}" != "0" ]; then
  echo "Container returned status ${wait_status} after graceful stop" >&2
  "${container_runtime}" logs "${container_name}" >&2 || true
  exit 1
fi
rm -f "${wait_status_file}"
wait_status_file=""

deadline=$((SECONDS + 10))
while "${container_runtime}" container inspect "${container_name}" >/dev/null 2>&1; do
  if (( SECONDS >= deadline )); then
    echo "Container was not removed after graceful stop" >&2
    exit 1
  fi
  sleep 1
done

trap - EXIT
echo "Image contract passed with ${container_runtime} (SUMMON_EXACT=${summon_exact}): ${image_name}"
