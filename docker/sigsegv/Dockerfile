# sigsegv-mvm's Optimize-Only package: server performance mods without gameplay
# features. Its convars come from sigsegv_convars.cfg in this directory. The
# release is global so the final stage can record it in a label.
ARG SIGSEGV_RELEASE=sv_parallel_sendsnapshot_fix

FROM ubuntu:22.04 AS sigsegv-download
RUN export DEBIAN_FRONTEND=noninteractive \
  && export TZ=Etc/UTC \
  && apt-get -y update \
  && apt-get install -y --no-install-recommends --no-install-suggests \
  unzip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /download
ARG PLUGIN_INSTALL_DIR=/server/tf
RUN mkdir -p "${PLUGIN_INSTALL_DIR}"

ARG SIGSEGV_RELEASE
ARG SIGSEGV_FILE_NAME=package-linux-optimize-only.zip
ARG SIGSEGV_URL=https://github.com/potato-tf/sigsegv-mvm/releases/download/${SIGSEGV_RELEASE}/${SIGSEGV_FILE_NAME}
ARG SIGSEGV_CHECKSUM=97c37e1a54252ecb6d4120645b87e1aa8327554ed8f7d8027a31d68ae3459a4b
ADD --checksum=sha256:${SIGSEGV_CHECKSUM} ${SIGSEGV_URL} .
# Keep only the TF2 builds of the extension (32-bit and x64), and replace the
# package's convars file with the Summon one.
RUN unzip -q "${SIGSEGV_FILE_NAME}" -d "${PLUGIN_INSTALL_DIR}/" \
  && cd "${PLUGIN_INSTALL_DIR}/addons/sourcemod/extensions" \
  && rm sigsegv-optimize-only.ext.so sigsegv-optimize-only.ext.2.css.so \
    x64/sigsegv-optimize-only.ext.so x64/sigsegv-optimize-only.ext.2.css.so \
  && rm "${PLUGIN_INSTALL_DIR}/cfg/sigsegv_convars.cfg"


FROM tf2-summon-image

ARG PLUGIN_INSTALL_DIR=/server/tf
COPY --from=sigsegv-download --chown=tf2 "${PLUGIN_INSTALL_DIR}/" "${SERVER_DIR}/tf/"
COPY --chown=tf2 sigsegv_convars.cfg ${SERVER_DIR}/tf/cfg/

ARG SIGSEGV_RELEASE
LABEL tf2.server.sigsegv="${SIGSEGV_RELEASE}"
