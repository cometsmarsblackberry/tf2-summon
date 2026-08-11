FROM tf2-summon-competitive-assets

LABEL org.opencontainers.image.title="tf2-summon" \
      org.opencontainers.image.description="Team Fortress 2 reservation server image for Summon" \
      org.opencontainers.image.source="https://github.com/cometsmarsblackberry/tf2-summon" \
      org.opencontainers.image.url="https://github.com/cometsmarsblackberry/tf2-summon" \
      org.opencontainers.image.licenses="MIT"

# Disable SourceMod's map rotation; Summon controls the server lifecycle.
RUN mv "${SERVER_DIR}/tf/addons/sourcemod/plugins/nextmap.smx" "${SERVER_DIR}/tf/addons/sourcemod/plugins/disabled/"

ENV DEMOS_TF_APIKEY=
ENV LOGS_TF_APIKEY=

# These checked-in plugins and configs are the Summon-specific final overlay.
COPY --chown=tf2 plugins/ ${SERVER_DIR}/tf/addons/sourcemod/plugins/
COPY --chown=tf2 sourcemod/configs/ ${SERVER_DIR}/tf/addons/sourcemod/configs/
COPY cfg/ ${SERVER_DIR}/tf/cfg/

ARG SRCDS_EXEC=srcds_run
ARG TF2_SERVER_ARCH=i386
ARG TF2_SERVER_VERSION=unknown

ENV SRCDS_EXEC=${SRCDS_EXEC}

LABEL tf2.server.architecture="${TF2_SERVER_ARCH}" \
      tf2.server.version="${TF2_SERVER_VERSION}"
