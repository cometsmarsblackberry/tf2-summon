#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d "${TMPDIR:-/tmp}/tf2-summon-entrypoint.XXXXXX")"
trap 'rm -rf -- "${test_root}"' EXIT

# The entrypoint only calls main when executed, so sourcing it exposes the
# startup-map helpers without trying to launch SRCDS.
# shellcheck disable=SC1091
source "${repo_dir}/docker/base/entrypoint.sh"

wget_mode=valid
wget_calls_file=""
wget_url_file=""

fail() {
  echo "Entrypoint test failed: $*" >&2
  exit 1
}

# Replace the outer watchdog in unit tests while preserving the command it
# wraps. Production continues to use GNU timeout.
# Older ShellCheck releases report indirect mock calls as SC2317; newer ones
# report the function declaration as SC2329.
# shellcheck disable=SC2317,SC2329
timeout() {
  while [[ "${1:-}" == --* ]]; do
    shift
  done
  shift # duration
  "$@"
}

# Build a small, structurally valid Source BSP. The first lump is one byte at
# offset 1036; the other 63 lump descriptors and map revision are zeroed.
write_valid_bsp() {
  local path="$1"
  local version="${2:-20}"
  local first_lump_offset="${3:-1036}"

  {
    printf 'VBSP'
    case "$version" in
      20) printf '\024\000\000\000' ;;
      19) printf '\023\000\000\000' ;;
      *) fail "unsupported fixture version: ${version}" ;;
    esac
    case "$first_lump_offset" in
      1036) printf '\014\004\000\000' ;;
      4096) printf '\000\020\000\000' ;;
      *) fail "unsupported fixture lump offset: ${first_lump_offset}" ;;
    esac
    printf '\001\000\000\000'
    head -c 8 /dev/zero
    head -c 1008 /dev/zero
    head -c 4 /dev/zero
    printf '\000'
  } >"${path}"
}

# Replace the process-group wrapper in unit tests. The dedicated signal test
# below exercises the real setsid/timeout process topology.
# shellcheck disable=SC2317,SC2329
setsid() {
  "$@"
}

# Mock wget in-process. It runs in the background in production and tests, so
# call metadata is recorded in files rather than shell variables.
# shellcheck disable=SC2317,SC2329
wget() {
  local argument
  local output_file=""

  printf 'call\n' >>"${wget_calls_file}"
  printf '%s' "${!#}" >"${wget_url_file}"
  for argument in "$@"; do
    case "${argument}" in
      --output-document=*) output_file="${argument#*=}" ;;
    esac
  done
  [ -n "${output_file}" ] || fail "wget output path was not provided"
  [[ "${output_file}" == "${SERVER_DIR}/tf/maps/."*.bsp.tmp.* ]] \
    || fail "download was not staged beside the final map: ${output_file}"
  [ ! -e "${SERVER_DIR}/tf/maps/${SUMMON_START_MAP}.bsp" ] \
    || fail "final map existed before the atomic install"

  case "${wget_mode}" in
    valid)
      write_valid_bsp "${output_file}"
      ;;
    partial_failure)
      printf 'VBSPpartial' >"${output_file}"
      return 1
      ;;
    short)
      printf 'VBSP' >"${output_file}"
      ;;
    invalid_magic)
      write_valid_bsp "${output_file}"
      printf 'NOPE' | dd of="${output_file}" conv=notrunc status=none
      ;;
    unsupported_version)
      write_valid_bsp "${output_file}" 19
      ;;
    invalid_lump_range)
      write_valid_bsp "${output_file}" 20 4096
      ;;
    *)
      fail "unknown wget mode: ${wget_mode}"
      ;;
  esac
}

new_case() {
  local case_name="$1"

  SERVER_DIR="${test_root}/${case_name}/server"
  mkdir -p "${SERVER_DIR}/tf/maps"
  SM_MAP_DOWNLOAD_BASE="https://fastdl.example.test/maps/"
  SUMMON_START_MAP="cp_process_f12"
  srcds_args=(+sv_pure 1 +map cp_badlands +maxplayers 24)
  wget_mode=valid
  wget_calls_file="${SERVER_DIR}/wget.calls"
  wget_url_file="${SERVER_DIR}/wget.url"
  : >"${wget_calls_file}"
  : >"${wget_url_file}"
}

wget_call_count() {
  wc -l <"${wget_calls_file}" | tr -d '[:space:]'
}

wget_last_url() {
  cat "${wget_url_file}"
}

assert_start_map() {
  local expected="$1"
  local index
  local count=0
  local actual=""

  for ((index = 0; index < ${#srcds_args[@]}; index++)); do
    if [ "${srcds_args[$index]}" = "+map" ]; then
      count=$((count + 1))
      actual="${srcds_args[$((index + 1))]:-}"
    fi
  done
  [ "${count}" -eq 1 ] || fail "expected one +map argument, found ${count}: ${srcds_args[*]}"
  [ "${actual}" = "${expected}" ] \
    || fail "startup map was ${actual}, expected ${expected}: ${srcds_args[*]}"
}

assert_no_staged_downloads() {
  if compgen -G "${SERVER_DIR}/tf/maps/.*.bsp.tmp.*" >/dev/null; then
    fail "a staged download was left behind in ${SERVER_DIR}/tf/maps"
  fi
}

new_case empty_signal
SUMMON_START_MAP=""
prepare_start_map
assert_start_map cp_badlands
[ "$(wget_call_count)" -eq 0 ] || fail "empty startup map triggered a download"

new_case bundled_badlands
SUMMON_START_MAP=cp_badlands
write_valid_bsp "${SERVER_DIR}/tf/maps/cp_badlands.bsp"
prepare_start_map
assert_start_map cp_badlands
[ "$(wget_call_count)" -eq 0 ] || fail "bundled badlands triggered a download"

new_case existing_map
write_valid_bsp "${SERVER_DIR}/tf/maps/cp_process_f12.bsp"
prepare_start_map
assert_start_map cp_process_f12
[ "$(wget_call_count)" -eq 0 ] || fail "an existing map triggered a download"

new_case valid_download
prepare_start_map
assert_start_map cp_process_f12
[ "$(wget_call_count)" -eq 1 ] || fail "valid map was not downloaded exactly once"
[ "$(wget_last_url)" = "https://fastdl.example.test/maps/cp_process_f12.bsp" ] \
  || fail "unexpected download URL: $(wget_last_url)"
is_valid_bsp "${SERVER_DIR}/tf/maps/cp_process_f12.bsp" \
  || fail "valid map was not atomically installed"
[ "$(stat -c '%a' "${SERVER_DIR}/tf/maps/cp_process_f12.bsp")" = "644" ] \
  || fail "installed map permissions were not 0644"
assert_no_staged_downloads

new_case valid_download_without_base_slash
SM_MAP_DOWNLOAD_BASE="https://fastdl.example.test/maps"
prepare_start_map
[ "$(wget_last_url)" = "https://fastdl.example.test/maps/cp_process_f12.bsp" ] \
  || fail "base URL without slash was joined incorrectly: $(wget_last_url)"
assert_start_map cp_process_f12

for mode in partial_failure short invalid_magic unsupported_version invalid_lump_range; do
  new_case "${mode}"
  wget_mode="${mode}"
  prepare_start_map
  assert_start_map cp_badlands
  [ ! -e "${SERVER_DIR}/tf/maps/cp_process_f12.bsp" ] \
    || fail "${mode} installed an invalid final BSP"
  assert_no_staged_downloads
done

new_case missing_download_base
export SM_MAP_DOWNLOAD_BASE=""
prepare_start_map
assert_start_map cp_badlands
[ "$(wget_call_count)" -eq 0 ] || fail "empty download base invoked wget"
assert_no_staged_downloads

invalid_names=(
  "../cp_process"
  "workshop/cp_process"
  "cp-process"
  "cp_process.bsp"
  "cp process"
  $'cp_process\nquit'
  "$(printf 'a%.0s' {1..65})"
)
for invalid_name in "${invalid_names[@]}"; do
  new_case invalid_name
  SUMMON_START_MAP="${invalid_name}"
  prepare_start_map
  assert_start_map cp_badlands
  [ "$(wget_call_count)" -eq 0 ] || fail "unsafe map name invoked wget: ${invalid_name}"
  assert_no_staged_downloads
done

new_case append_map_argument
write_valid_bsp "${SERVER_DIR}/tf/maps/cp_process_f12.bsp"
srcds_args=(+sv_pure 1 +maxplayers 24)
prepare_start_map
assert_start_map cp_process_f12

new_case duplicate_map_arguments
write_valid_bsp "${SERVER_DIR}/tf/maps/cp_process_f12.bsp"
srcds_args=(+map cp_badlands +sv_pure 1 +map koth_product_rcx +maxplayers 24)
prepare_start_map
assert_start_map cp_process_f12
[[ " ${srcds_args[*]} " == *" +sv_pure 1 "* ]] || fail "+sv_pure was lost while normalizing +map"
[[ " ${srcds_args[*]} " == *" +maxplayers 24 "* ]] || fail "+maxplayers was lost while normalizing +map"

new_case maximum_size_validation
write_valid_bsp "${SERVER_DIR}/tf/maps/cp_process_f12.bsp"
original_max_bytes="$START_MAP_MAX_BYTES"
START_MAP_MAX_BYTES=1024
if is_valid_bsp "${SERVER_DIR}/tf/maps/cp_process_f12.bsp"; then
  fail "BSP larger than the configured maximum was accepted"
fi
START_MAP_MAX_BYTES="$original_max_bytes"

new_case interrupted_download_cleanup
staged_file="${SERVER_DIR}/tf/maps/.cp_process_f12.bsp.tmp.signal"
download_pid_file="${SERVER_DIR}/download.pid"
cancel_started_at=$SECONDS
bash -c '
  set -Eeuo pipefail
  source "$1"
  START_MAP_DOWNLOAD_FILE="$2"
  : >"$START_MAP_DOWNLOAD_FILE"
  setsid timeout --signal=TERM --kill-after=30s 30s \
    bash -c '\''trap "" TERM; exec sleep 30'\'' &
  START_MAP_DOWNLOAD_PID=$!
  START_MAP_DOWNLOAD_PGID="$START_MAP_DOWNLOAD_PID"
  printf "%s" "$START_MAP_DOWNLOAD_PGID" >"$3"
  trap quit TERM
  (sleep 0.2; kill -TERM "$$") &
  wait "$START_MAP_DOWNLOAD_PID"
  exit 99
' entrypoint-signal-test "${repo_dir}/docker/base/entrypoint.sh" "$staged_file" "$download_pid_file"
cancel_elapsed=$((SECONDS - cancel_started_at))
[ "$cancel_elapsed" -le 3 ] || fail "download cancellation took ${cancel_elapsed}s"
[ ! -e "$staged_file" ] || fail "interrupted staged download was not removed"
download_pgid="$(cat "$download_pid_file")"
if kill -0 -- "-$download_pgid" 2>/dev/null; then
  fail "interrupted download process group ${download_pgid} is still running"
fi

new_case enforced_download_size_limit
mock_bin="${SERVER_DIR}/mock-bin"
mkdir -p "$mock_bin"
# The following single-quoted strings intentionally belong to the generated
# stub rather than this test process.
# shellcheck disable=SC2016
{
  printf '%s\n' '#!/usr/bin/env bash'
  printf '%s\n' 'set -Eeuo pipefail'
  printf '%s\n' 'ulimit -S -c >"$CORE_LIMIT_FILE"'
  printf '%s\n' 'output_file=""'
  printf '%s\n' 'for argument in "$@"; do'
  printf '%s\n' '  case "$argument" in --output-document=*) output_file="${argument#*=}" ;; esac'
  printf '%s\n' 'done'
  printf '%s\n' 'head -c 8192 /dev/zero >"$output_file" 2>/dev/null'
} >"${mock_bin}/wget"
chmod 0755 "${mock_bin}/wget"
unset -f setsid timeout wget
PATH="${mock_bin}:${PATH}"
CORE_LIMIT_FILE="${SERVER_DIR}/wget.core-limit"
export PATH
export CORE_LIMIT_FILE
START_MAP_MAX_BYTES=2048
oversized_file="${SERVER_DIR}/tf/maps/.cp_process_f12.bsp.tmp.oversized"
if run_start_map_download \
  "$oversized_file" "https://fastdl.example.test/maps/cp_process_f12.bsp" 2>/dev/null; then
  fail "real download process exceeded its file-size limit successfully"
fi
[ "$(cat "$CORE_LIMIT_FILE")" = "0" ] || fail "download process inherited a nonzero core limit"
[ "$(stat -c '%s' "$oversized_file")" -le "$START_MAP_MAX_BYTES" ] \
  || fail "download file exceeded the configured size ceiling"

echo "Entrypoint startup-map tests passed"
