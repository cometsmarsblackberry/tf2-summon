# Compile the Summon and Map Downloader plugins from the summon repository's
# plugin sources (the summon-plugin build context, pinned in docker-bake.hcl)
# with the SourceMod compiler and includes installed in the image.
FROM tf2-summon-competitive-assets AS summon-plugins

USER root
WORKDIR /summon-plugins

# Includes for Summon's optional logs.tf and demos.tf upload forwards, matching
# the F2 plugin release and demos.tf commit installed in competitive-assets.
ARG LOGSTF_INC_VERSION=20260717-1784284363049
ARG LOGSTF_INC_CHECKSUM=b6db02a3cda283215db7059cf3a58e05c928520e29e4507ace2f9307ccb5d95a
ADD --checksum=sha256:${LOGSTF_INC_CHECKSUM} https://raw.githubusercontent.com/F2/F2s-sourcemod-plugins/${LOGSTF_INC_VERSION}/logstf/logstf.inc include/logstf.inc
ARG DEMOSTF_INC_COMMIT=467a8858e642729c2bdbc769a28c7d450a2c1123
ARG DEMOSTF_INC_CHECKSUM=b5a2b2957b3ce5db3c3b67d64326ea7df005e1e8b58ccc086c694f2faed2b52c
ADD --checksum=sha256:${DEMOSTF_INC_CHECKSUM} https://codeberg.org/demostf/plugin/raw/commit/${DEMOSTF_INC_COMMIT}/include/demostf.inc include/demostf.inc

COPY --from=summon-plugin scripting/ scripting/

# Without summon.inc, mapdownloader.sp silently compiles in standalone mode and
# ignores the reservation owner's map change requests.
RUN set -Eeuo pipefail; \
    test -f scripting/include/summon.inc; \
    mkdir -p plugins; \
    for plugin in summon mapdownloader; do \
      "${SERVER_DIR}/tf/addons/sourcemod/scripting/spcomp" \
        -i"${SERVER_DIR}/tf/addons/sourcemod/scripting/include" \
        -iinclude \
        -iscripting/include \
        -o"plugins/${plugin}.smx" \
        "scripting/${plugin}.sp"; \
    done


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

# The compiled Summon plugins and these checked-in plugins and configs are the
# Summon-specific final overlay.
COPY --from=summon-plugins --chown=tf2 /summon-plugins/plugins/ ${SERVER_DIR}/tf/addons/sourcemod/plugins/
COPY --chown=tf2 plugins/ ${SERVER_DIR}/tf/addons/sourcemod/plugins/
COPY --chown=tf2 sourcemod/configs/ ${SERVER_DIR}/tf/addons/sourcemod/configs/
COPY cfg/ ${SERVER_DIR}/tf/cfg/

ARG SRCDS_EXEC=srcds_run
ARG TF2_SERVER_ARCH=i386
ARG TF2_SERVER_VERSION=unknown

ENV SRCDS_EXEC=${SRCDS_EXEC}

LABEL tf2.server.architecture="${TF2_SERVER_ARCH}" \
      tf2.server.version="${TF2_SERVER_VERSION}"
