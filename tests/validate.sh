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
  docker/plugins/Dockerfile
  cfg/server.cfg.template
  cfg/summon_reset.cfg
  plugins/autoreload.smx
  plugins/mapdownloader.smx
  plugins/summon.smx
)

for file in "${required_files[@]}"; do
  test -f "${file}" || {
    echo "Missing required file: ${file}" >&2
    exit 1
  }
done

printf '%s  %s\n' \
  0e34864d17cdaa615b6cde3a45fec858aaa4d816c1072666045f7f5b774a83ed plugins/autoreload.smx \
  bc56591d3abc55c7b9f164f8e9ca4d49c7cdd9f363049a65d19eee0ee0d9d380 plugins/mapdownloader.smx \
  afb269af47a8dde925b85ac039159ab8540237dfec44cba6a851f7c944ba1877 plugins/summon.smx \
  | sha256sum -c -

grep -Fqx 'FROM tf2-summon-base' docker/sourcemod/Dockerfile
grep -Fqx 'FROM tf2-summon-sourcemod' docker/plugins/Dockerfile
grep -Fqx 'FROM tf2-summon-plugins' Dockerfile
grep -Fq 'tf2-summon-base = "target:base"' docker-bake.hcl
grep -Fq 'tf2-summon-sourcemod = "target:sourcemod"' docker-bake.hcl
grep -Fq 'tf2-summon-plugins = "target:plugins"' docker-bake.hcl
grep -Fq 'target "image-amd64"' docker-bake.hcl
grep -Fq 'SRCDS_EXEC      = "srcds_run_64"' docker-bake.hcl
grep -Fq 'TF2_SERVER_ARCH = "amd64"' docker-bake.hcl
grep -Fq 'steamcmd/linux64' docker/base/Dockerfile

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
  docker/base/install_tf2.sh tests/validate.sh tests/contract.sh

if command -v shellcheck >/dev/null 2>&1; then
  shellcheck docker/base/entrypoint.sh docker/base/healthcheck.sh \
    docker/base/install_tf2.sh tests/validate.sh tests/contract.sh
fi

docker buildx bake --print >/dev/null

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git diff --check
fi

echo "Repository validation passed"
