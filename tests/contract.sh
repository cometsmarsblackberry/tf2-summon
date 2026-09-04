#!/usr/bin/env bash
set -Eeuo pipefail

image_name="${1:-tf2-summon:local}"
server_arch="${2:-i386}"
container_name="tf2-summon-contract-${RANDOM}-$$"
container_runtime="${CONTAINER_RUNTIME:-docker}"
summon_exact="${SUMMON_EXACT:-0}"
rcon_password="summon-rcon-test"
wait_status_file=""

case "${server_arch}" in
  i386)
    srcds_exec=srcds_run
    server_binary=/home/tf2/server/srcds_linux
    elf_class=1
    ;;
  amd64)
    srcds_exec=srcds_run_64
    server_binary=/home/tf2/server/srcds_linux64
    elf_class=2
    ;;
  *)
    echo "Server architecture must be i386 or amd64" >&2
    exit 1
    ;;
esac

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
test "$("${container_runtime}" image inspect --format '{{index .Config.Labels "tf2.server.architecture"}}' "${image_name}")" = "${server_arch}"
image_tf2_server_version="$(
  "${container_runtime}" image inspect \
    --format '{{index .Config.Labels "tf2.server.version"}}' "${image_name}"
)"
if [[ ! "${image_tf2_server_version}" =~ ^(unknown|[1-9][0-9]*)$ ]]; then
  echo "Invalid tf2.server.version image label: ${image_tf2_server_version}" >&2
  exit 1
fi
if [ -n "${TF2_SERVER_VERSION:-}" ]; then
  test "${image_tf2_server_version}" = "${TF2_SERVER_VERSION}"
fi
"${container_runtime}" image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "${image_name}" \
  | grep -Fxq "SRCDS_EXEC=${srcds_exec}"
"${container_runtime}" image inspect --format '{{range .Config.Env}}{{println .}}{{end}}' "${image_name}" \
  | grep -Fxq "SUMMON_START_MAP="

# The quoted script expands variables inside the container, not in this shell.
# shellcheck disable=SC2016
"${container_runtime}" run --rm --entrypoint bash \
  -e EXPECTED_SERVER_BINARY="${server_binary}" \
  -e EXPECTED_ELF_CLASS="${elf_class}" \
  -e EXPECTED_TF2_SERVER_VERSION="${image_tf2_server_version}" \
  "${image_name}" -lc '
  set -Eeuo pipefail
  trap "status=\$?; echo \"Static image contract failed at line \${LINENO}: \${BASH_COMMAND}\" >&2; exit \${status}" ERR

  test -x /home/tf2/server/rcon
  test -x "${EXPECTED_SERVER_BINARY}"
  command -v awk >/dev/null
  command -v od >/dev/null
  command -v setsid >/dev/null
  command -v timeout >/dev/null
  command -v wget >/dev/null
  test "$(od -An -t u1 -j 4 -N 1 "${EXPECTED_SERVER_BINARY}" | tr -d " ")" = "${EXPECTED_ELF_CLASS}"
  test -e /home/tf2/.steam/sdk64/steamclient.so
  test -d /home/tf2/server/tf
  installed_tf2_server_version="$(
    sed -n "s/^ServerVersion=//p" /home/tf2/server/tf/steam.inf | tr -d "\r"
  )"
  test -n "${installed_tf2_server_version}"
  if [ "${EXPECTED_TF2_SERVER_VERSION}" != unknown ]; then
    test "${installed_tf2_server_version}" = "${EXPECTED_TF2_SERVER_VERSION}"
  fi
  test -f /home/tf2/server/tf/maps/cp_badlands.bsp
  test "$(find /home/tf2/server/tf/maps -maxdepth 1 -type f -name "*.bsp" | wc -l)" -eq 1
  test -f /home/tf2/server/tf/addons/metamod.vdf
  test -d /home/tf2/server/tf/addons/sourcemod
  test -f /home/tf2/server/tf/addons/sourcemod/plugins/summon.smx
  test -f /home/tf2/server/tf/addons/sourcemod/plugins/mapdownloader.smx
  test -f /home/tf2/server/tf/addons/sourcemod/configs/summon_owner_commands.cfg
  grep -Fqx "    \"changelevel\"" /home/tf2/server/tf/addons/sourcemod/configs/summon_owner_commands.cfg
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
    07cf5bc1b35a1f1ed8adfa833d82a4b581f2be320492d87cc552d102c5f5517b /home/tf2/server/tf/addons/sourcemod/plugins/summon.smx \
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

# Confirm that the configured wrapper launched the requested SRCDS ELF rather
# than merely carrying both server architectures in the image.
# shellcheck disable=SC2016
"${container_runtime}" exec "${container_name}" bash -lc '
  expected_binary="$1"
  for process_exe in /proc/[0-9]*/exe; do
    if [ "$(readlink "${process_exe}" 2>/dev/null || true)" = "${expected_binary}" ]; then
      exit 0
    fi
  done
  echo "Running SRCDS process not found: ${expected_binary}" >&2
  exit 1
' bash "${server_binary}"

plugin_output="$("${rcon[@]}" 'sm plugins list')"
grep -Fqi 'Summon' <<<"${plugin_output}"
grep -Fqi 'Map Downloader' <<<"${plugin_output}"

owner_commands_output="$("${rcon[@]}" 'sm_summon_reload_owner_commands')"
grep -Eq 'Loaded [1-9][0-9]* reservation-owner commands\.' <<<"${owner_commands_output}"

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
echo "Image contract passed with ${container_runtime} (server_arch=${server_arch}, SUMMON_EXACT=${summon_exact}): ${image_name}"
