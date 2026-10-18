#!/usr/bin/env bash
set -Eeuo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_dir}"

required_files=(
  Dockerfile
  docker-bake.hcl
  docker/base/Dockerfile
  docker/base/entrypoint.sh
  docker/base/healthcheck.sh
  docker/base/install_tf2.sh
  docker/base/maps_to_keep
  docker/base/server.cfg.template
  docker/base/tf2.txt.template
  docker/sourcemod/Dockerfile
  docker/core-addons/Dockerfile
  docker/competitive-assets/Dockerfile
  docker/sigsegv/Dockerfile
  docker/sigsegv/sigsegv_convars.cfg
  cfg/server.cfg.template
  cfg/summon_reset.cfg
  plugins/autoreload.smx
  sourcemod/configs/summon_owner_commands.cfg
  tests/entrypoint.sh
)

for file in "${required_files[@]}"; do
  test -f "${file}" || {
    echo "Missing required file: ${file}" >&2
    exit 1
  }
done

printf '%s  %s\n' \
  0e34864d17cdaa615b6cde3a45fec858aaa4d816c1072666045f7f5b774a83ed plugins/autoreload.smx \
  | sha256sum -c -

# Summon's plugins are compiled during the image build from a pinned summon commit.
test ! -e plugins/summon.smx
test ! -e plugins/mapdownloader.smx
grep -Eq '^  default = "https://github\.com/cometsmarsblackberry/summon\.git#[0-9a-f]{40}:tf2-reservation-plugin"$' docker-bake.hcl
test "$(grep -Fc 'summon-plugin                 = SUMMON_PLUGIN_SOURCE' docker-bake.hcl)" -eq 2
grep -Fq 'COPY --from=summon-plugin scripting/ scripting/' Dockerfile

grep -Fqx '    "changelevel"' sourcemod/configs/summon_owner_commands.cfg

grep -Fqx 'FROM tf2-summon-base' docker/sourcemod/Dockerfile
grep -Fqx 'FROM tf2-summon-sourcemod' docker/core-addons/Dockerfile
grep -Fqx 'FROM tf2-summon-core-addons' docker/competitive-assets/Dockerfile
grep -Fqx 'FROM tf2-summon-competitive-assets' Dockerfile
grep -Fqx 'FROM tf2-summon-image' docker/sigsegv/Dockerfile
grep -Fq 'tf2-summon-base = "target:base"' docker-bake.hcl
grep -Fq 'tf2-summon-sourcemod = "target:sourcemod"' docker-bake.hcl
grep -Fq 'tf2-summon-core-addons = "target:core-addons"' docker-bake.hcl
grep -Fq 'tf2-summon-competitive-assets = "target:competitive-assets"' docker-bake.hcl
grep -Fq 'tf2-summon-image = "target:image"' docker-bake.hcl
# The sigsegv variant stays out of the main image's cfg overlay.
test ! -e cfg/sigsegv_convars.cfg
grep -Fq 'target "image-amd64"' docker-bake.hcl
grep -Fq 'SRCDS_EXEC         = "srcds_run_64"' docker-bake.hcl
grep -Fq 'TF2_SERVER_ARCH    = "amd64"' docker-bake.hcl
grep -Fq 'TF2_SERVER_VERSION = TF2_SERVER_VERSION' docker-bake.hcl
grep -Fq 'steamcmd/linux64' docker/base/Dockerfile
grep -Fq 'ARG TF2_SERVER_VERSION=unknown' docker/base/Dockerfile
# The Docker build argument is intentionally literal.
# shellcheck disable=SC2016
grep -Fq 'tf2.server.version="${TF2_SERVER_VERSION}"' Dockerfile

if command -v rg >/dev/null 2>&1; then
  search_repository() {
    rg -a -n -i --hidden --glob '!.git/**' --fixed-strings "$1" .
  }
else
  search_repository() {
    grep -R -a -n -i -F --exclude-dir=.git -- "$1" .
  }
fi

for name in "tf2-"{"server","servers"} "source-""server-""plugins"; do
  if search_repository "${name}"; then
    echo "Forbidden repository reference found: ${name}" >&2
    exit 1
  fi
done

bash -n docker/base/entrypoint.sh docker/base/healthcheck.sh \
  docker/base/install_tf2.sh tests/validate.sh tests/contract.sh \
  tests/entrypoint.sh

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck docker/base/entrypoint.sh docker/base/healthcheck.sh \
    docker/base/install_tf2.sh tests/validate.sh tests/contract.sh \
    tests/entrypoint.sh
fi

tests/entrypoint.sh

docker buildx bake --print >/dev/null

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git diff --check
fi

echo "Repository validation passed"
