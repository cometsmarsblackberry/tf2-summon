FROM ubuntu:22.04 AS competitive-downloads
# Competitive game modes, league configs, and match integrations.
SHELL ["/bin/bash", "-c"]
RUN export DEBIAN_FRONTEND=noninteractive \
  && export TZ=Etc/UTC \
  && apt-get -y update \
  && apt-get install -y --no-install-recommends --no-install-suggests \
  unzip \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /download
ARG PLUGIN_INSTALL_DIR=/server/tf
RUN mkdir -p "${PLUGIN_INSTALL_DIR}"

# SOAP TF2DM
ARG SOAP_DM_FILE_NAME=soap.zip
ARG SOAP_DM_VERSION=4.4.9
ARG SOAP_DM_URL=https://github.com/sapphonie/SOAP-TF2DM/releases/download/v${SOAP_DM_VERSION}/${SOAP_DM_FILE_NAME}
ARG SOAP_DM_CHECKSUM=aee4474a3528087241bcd4d61b1a99feaf2fb0a942b41f7ca0c887eef61a624e
ADD --checksum=sha256:${SOAP_DM_CHECKSUM} ${SOAP_DM_URL} .
RUN unzip -q "${SOAP_DM_FILE_NAME}" -d "${PLUGIN_INSTALL_DIR}/"

# MGEMod
ARG MGEMOD_FILE_NAME=mge.zip
ARG MGEMOD_VERSION=v3.1.0-beta39
ARG MGEMOD_URL=https://github.com/mgetf/MGEMod/releases/download/${MGEMOD_VERSION}/${MGEMOD_FILE_NAME}
ARG MGEMOD_CHECKSUM=069f7ad28d797c892a96133bbe7304c81175fbb82c5bc2209d7836324096d78b
ADD --checksum=sha256:${MGEMOD_CHECKSUM} ${MGEMOD_URL} .
RUN unzip -q -n "${MGEMOD_FILE_NAME}" -d "${PLUGIN_INSTALL_DIR}/"

# F2's SourceMod Plugins
ARG F2_SOURCEMOD_PLUGINS_FILE_NAME=f2-sourcemod-plugins.zip
ARG F2_SOURCEMOD_PLUGINS_VERSION=20260717-1784284363049
ARG F2_SOURCEMOD_PLUGINS_URL=https://github.com/F2/F2s-sourcemod-plugins/releases/download/${F2_SOURCEMOD_PLUGINS_VERSION}/${F2_SOURCEMOD_PLUGINS_FILE_NAME}
ARG F2_SOURCEMOD_PLUGINS_CHECKSUM=246b2522ee5b7467e247a621ff1fa4c53f735657ddc2f9a67747959de1ae59bd
ADD --checksum=sha256:${F2_SOURCEMOD_PLUGINS_CHECKSUM} ${F2_SOURCEMOD_PLUGINS_URL} .
ARG F2_ENABLED_PLUGINS="afk.smx fixstvslot.smx logstf.smx medicstats.smx pause.smx recordstv.smx restorescore.smx supstats2.smx waitforstv.smx"
RUN unzip -q -j "${F2_SOURCEMOD_PLUGINS_FILE_NAME}" ${F2_ENABLED_PLUGINS} \
  -d "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/"

# ETF2L Configs
ARG ETF2L_CONFIGS_FILE_NAME=etf2l_configs.zip
ARG ETF2L_CONFIGS_VERSION=1.0.29
ARG ETF2L_CONFIGS_URL=https://github.com/ETF2L/gameserver-configs/releases/download/${ETF2L_CONFIGS_VERSION}/${ETF2L_CONFIGS_FILE_NAME}
ARG ETF2L_CONFIGS_CHECKSUM=f171e626bcd4cbdfafef764420f0d788ebf96d599bf676c869b948d81191743e
ADD --checksum=sha256:${ETF2L_CONFIGS_CHECKSUM} ${ETF2L_CONFIGS_URL} .
RUN unzip -q "${ETF2L_CONFIGS_FILE_NAME}" -d "${PLUGIN_INSTALL_DIR}/cfg/"

# FBTF Configs
ARG FBTF_CONFIGS_VERSION=25
ARG FBTF_CONFIGS_FILE_NAME=fbtf_cfg_s${FBTF_CONFIGS_VERSION}.zip
ARG FBTF_CONFIGS_URL=https://fbtf.tf/uploads/cfgs/${FBTF_CONFIGS_FILE_NAME}
ARG FBTF_CONFIGS_CHECKSUM=a0e637085defbd186800f069a65cc70a147eebd7672cdec493ffc94804dd5d28
ADD --checksum=sha256:${FBTF_CONFIGS_CHECKSUM} ${FBTF_CONFIGS_URL} .
RUN unzip -q "${FBTF_CONFIGS_FILE_NAME}" \
  && cp fbtf_cfg/* "${PLUGIN_INSTALL_DIR}/cfg/"

# RGL Configs + Plugins (all plugins disabled)
ARG RGL_CONFIGS_FILE_NAME=server-resources-updater.zip
ARG RGL_CONFIGS_VERSION=v365
ARG RGL_CONFIGS_URL=https://github.com/RGLgg/server-resources-updater/releases/download/${RGL_CONFIGS_VERSION}/${RGL_CONFIGS_FILE_NAME}
ARG RGL_CONFIGS_CHECKSUM=671e5a2c2b7432212f1ab9c73253de6383d1483cb12b30a45f1c08a3a418df8f
ADD --checksum=sha256:${RGL_CONFIGS_CHECKSUM} ${RGL_CONFIGS_URL} .
RUN unzip -q "${RGL_CONFIGS_FILE_NAME}" \
  && cp "cfg/"* "${PLUGIN_INSTALL_DIR}/cfg/" \
  && mkdir -p "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/disabled" \
  && cp "addons/sourcemod/plugins/"{config_checker,rglqol,updater,demo_check_no_discord,rglupdater}.smx "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/disabled/" \
  && cp "addons/sourcemod/plugins/disabled/"{p4sstime,roundtimer_override}.smx "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/disabled/"

# ozfortress Configs (pinned to commit)
# The Summer Cup (ozfortress_sc*) configs target Team Comtress 2, not stock TF2.
ARG OZF_CONFIGS_COMMIT=e4baf2ee575a9f387eb13f5c096549458ff65752
ARG OZF_CONFIGS_FILE_NAME=ozfortress-configs.zip
ARG OZF_CONFIGS_URL=https://github.com/ozfortress/server-configs/archive/${OZF_CONFIGS_COMMIT}.zip
ARG OZF_CONFIGS_CHECKSUM=0834c5d2683a8c726d15c3310ff5e7cd5740343a96da435cfe00343ec47196e4
ADD --checksum=sha256:${OZF_CONFIGS_CHECKSUM} ${OZF_CONFIGS_URL} ./${OZF_CONFIGS_FILE_NAME}
RUN unzip -q "${OZF_CONFIGS_FILE_NAME}" \
  && cp "server-configs-${OZF_CONFIGS_COMMIT}/cfg/"* "${PLUGIN_INSTALL_DIR}/cfg/" \
  && rm "${PLUGIN_INSTALL_DIR}/cfg/ozfortress_sc.cfg" "${PLUGIN_INSTALL_DIR}/cfg/ozfortress_sc_"*.cfg


# Ultitrio Configs (pinned to the v3.2.2 commit, which upstream tagged MainRelease)
ARG ULTITRIO_CONFIGS_COMMIT=8d9381b94ea9c3865426268467a188a240270ed4
ARG ULTITRIO_CONFIGS_FILE_NAME=Ultitrio-${ULTITRIO_CONFIGS_COMMIT}.zip
ARG ULTITRIO_CONFIGS_URL=https://github.com/CoolstuffTF2/Ultitrio/archive/${ULTITRIO_CONFIGS_COMMIT}.zip
ARG ULTITRIO_CONFIGS_CHECKSUM=d65d1412bf3589ed02d2cfb44563fec0fab9cf61ec4bdf6c07c5f1be23ed49bb
ADD --checksum=sha256:${ULTITRIO_CONFIGS_CHECKSUM} ${ULTITRIO_CONFIGS_URL} ./${ULTITRIO_CONFIGS_FILE_NAME}
RUN unzip -q "${ULTITRIO_CONFIGS_FILE_NAME}" \
  && cp "Ultitrio-${ULTITRIO_CONFIGS_COMMIT}/ultitrio_"*.{cfg,txt} "${PLUGIN_INSTALL_DIR}/cfg/"

# AsiaFortress, CLTF2, TFArena, and UFL Configs (from serveme.tf, pinned to commit)
# These leagues do not publish their configs publicly, so they come from serveme.tf's mirror.
# The AsiaFortress 6s 5CP config layers over rgl_6s_base and uses the Improved Match Timer.
# The legacy AFC 10 configs (afcad, afckoth, afcpush) are intentionally omitted.
# The CLTF2 and TFArena configs call the nonexistent "servercfg" command, which would leave
# servercfgfile unset and skip re-executing the config after a map change.
ARG SERVEME_CONFIGS_COMMIT=3c5f2bd9dce37d8f416881f93a87fbb7037c3efd
ARG SERVEME_CONFIGS_FILE_NAME=serveme-${SERVEME_CONFIGS_COMMIT}.zip
ARG SERVEME_CONFIGS_URL=https://github.com/Arie/serveme/archive/${SERVEME_CONFIGS_COMMIT}.zip
ARG SERVEME_CONFIGS_CHECKSUM=50f19dde09fa8b60a60283a9d58789c776ddea24dcef1979cb516734f606d27a
ADD --checksum=sha256:${SERVEME_CONFIGS_CHECKSUM} ${SERVEME_CONFIGS_URL} ./${SERVEME_CONFIGS_FILE_NAME}
RUN unzip -q "${SERVEME_CONFIGS_FILE_NAME}" "serveme-${SERVEME_CONFIGS_COMMIT}/docker/tf2-cloud-server/base-configs/cfg/*" \
  && cd "serveme-${SERVEME_CONFIGS_COMMIT}/docker/tf2-cloud-server/base-configs/cfg" \
  && cp afc_6s_5cp_match_pro.cfg af_HL_{base,koth,koth_bo5,stopwatch}.cfg af_whitelist_HL.txt \
    cltf2_*.cfg tfarena_*.cfg ufl_base.cfg "${PLUGIN_INSTALL_DIR}/cfg/" \
  && sed -i 's/^servercfg /servercfgfile /' "${PLUGIN_INSTALL_DIR}/cfg/"{cltf2,tfarena}_*.cfg

# Improved Match Timer
ARG IMPROVED_MATCH_TIMER_COMMIT=28f1f9a03c07a072684fa3d4977a0898a85b0588
ARG IMPROVED_MATCH_TIMER_FILE_NAME=Improved-Match-Timer-${IMPROVED_MATCH_TIMER_COMMIT}.zip
ARG IMPROVED_MATCH_TIMER_URL=https://github.com/dewbsku/Improved-Match-Timer/archive/${IMPROVED_MATCH_TIMER_COMMIT}.zip
ARG IMPROVED_MATCH_TIMER_CHECKSUM=683dc1c58d397d2d3bfd468985ee22fa830d4fd570f187754ab7ef686c3c6d77
ADD --checksum=sha256:${IMPROVED_MATCH_TIMER_CHECKSUM} ${IMPROVED_MATCH_TIMER_URL} ${IMPROVED_MATCH_TIMER_FILE_NAME}
RUN unzip -q "${IMPROVED_MATCH_TIMER_FILE_NAME}" \
  && cp "Improved-Match-Timer-${IMPROVED_MATCH_TIMER_COMMIT}/addons/sourcemod/plugins/"*.smx "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/" \
  && cp "Improved-Match-Timer-${IMPROVED_MATCH_TIMER_COMMIT}/addons/sourcemod/scripting/"*.sp "${PLUGIN_INSTALL_DIR}/addons/sourcemod/scripting/"


# SrcTV+
ARG SRCTV_PLUS_VERSION=v3.0
ARG SRCTV_PLUS_SO_FILE_NAME=srctvplus.so
ARG SRCTV_PLUS_SO_URL=https://github.com/dalegaard/srctvplus/releases/download/${SRCTV_PLUS_VERSION}/${SRCTV_PLUS_SO_FILE_NAME}
ARG SRCTV_PLUS_SO_CHECKSUM=5063cf4a29bc9b9ddb8d4703ac0128e62ea6a4c976439e0e77d4085646704fe2
ADD --checksum=sha256:${SRCTV_PLUS_SO_CHECKSUM} ${SRCTV_PLUS_SO_URL} .
RUN cp "${SRCTV_PLUS_SO_FILE_NAME}" "${PLUGIN_INSTALL_DIR}/addons/${SRCTV_PLUS_SO_FILE_NAME}"

ARG SRCTV_PLUS_VDF_FILE_NAME=srctvplus.vdf
ARG SRCTV_PLUS_VDF_URL=https://github.com/dalegaard/srctvplus/releases/download/${SRCTV_PLUS_VERSION}/${SRCTV_PLUS_VDF_FILE_NAME}
ARG SRCTV_PLUS_VDF_CHECKSUM=886287c911200c1f2f0effc232fd01740cc0913cd92723fdf27cf3c52854beba
ADD --checksum=sha256:${SRCTV_PLUS_VDF_CHECKSUM} ${SRCTV_PLUS_VDF_URL} .
RUN cp "${SRCTV_PLUS_VDF_FILE_NAME}" "${PLUGIN_INSTALL_DIR}/addons/${SRCTV_PLUS_VDF_FILE_NAME}"

# Demos.tf (pinned to commit)
ARG DEMOSTF_COMMIT=467a8858e642729c2bdbc769a28c7d450a2c1123
ARG DEMOSTF_PLUGIN_FILE_NAME=demostf.smx
ARG DEMOSTF_PLUGIN_URL=https://codeberg.org/demostf/plugin/raw/commit/${DEMOSTF_COMMIT}/${DEMOSTF_PLUGIN_FILE_NAME}
ARG DEMOSTF_PLUGIN_CHECKSUM=e2fad4e7970ed0eb609d29ce17336408963debba9a3392768404cdff47fd90d0
ADD --checksum=sha256:${DEMOSTF_PLUGIN_CHECKSUM} ${DEMOSTF_PLUGIN_URL} .
RUN cp "${DEMOSTF_PLUGIN_FILE_NAME}" "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/${DEMOSTF_PLUGIN_FILE_NAME}"

# AutoExec (disabled)
# ARG AUTOEXEC_COMMIT=6188e75ee72b3f5e828ff06d783e5cd5c00a8975
# ARG AUTOEXEC_PLUGIN_FILE_NAME=autoexec.smx
# ARG AUTOEXEC_PLUGIN_URL=https://codeberg.org/spire/autoexec/raw/commit/${AUTOEXEC_COMMIT}/plugin/${AUTOEXEC_PLUGIN_FILE_NAME}
# ARG AUTOEXEC_PLUGIN_CHECKSUM=a32a6ec738bf258d782fa44a1cef4c1cf6cb3ce230bf35fe78f60b3b02df6cd9
# ADD --checksum=sha256:${AUTOEXEC_PLUGIN_CHECKSUM} ${AUTOEXEC_PLUGIN_URL} .
# RUN cp "${AUTOEXEC_PLUGIN_FILE_NAME}" "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/${AUTOEXEC_PLUGIN_FILE_NAME}"

# Whitelist Downloader (pinned to commit)
ARG WHITELISTTF_COMMIT=333c5065514a6c5b2f11e57f8ef0bbe80ac28a74
ARG WHITELISTTF_PLUGIN_FILE_NAME=whitelisttf.smx
ARG WHITELISTTF_PLUGIN_URL=https://codeberg.org/spire/sm_whitelist/raw/commit/${WHITELISTTF_COMMIT}/plugin/${WHITELISTTF_PLUGIN_FILE_NAME}
ARG WHITELISTTF_PLUGIN_CHECKSUM=75a09e7e65fda6e03acb8acb7adff0695fc7dfb827f44a9e548a3b3640e8c0b5
ADD --checksum=sha256:${WHITELISTTF_PLUGIN_CHECKSUM} ${WHITELISTTF_PLUGIN_URL} .
RUN cp "${WHITELISTTF_PLUGIN_FILE_NAME}" "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/${WHITELISTTF_PLUGIN_FILE_NAME}"

# WebRcon (disabled)
# ARG WEBRCON_COMMIT=d407f5b2e85432b9cbd8e8e5ff2a8a2a08a816e9
# ARG WEBRCON_PLUGIN_FILE_NAME=webrcon.smx
# ARG WEBRCON_PLUGIN_URL=https://codeberg.org/spire/webrcon/raw/commit/${WEBRCON_COMMIT}/plugin/${WEBRCON_PLUGIN_FILE_NAME}
# ARG WEBRCON_PLUGIN_CHECKSUM=74d2ee3f628260e77b495b6cb6c975d7e2bf8462cb7d967f14ad9e5b0cfe01a8
# ADD --checksum=sha256:${WEBRCON_PLUGIN_CHECKSUM} ${WEBRCON_PLUGIN_URL} .
# RUN cp "${WEBRCON_PLUGIN_FILE_NAME}" "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/${WEBRCON_PLUGIN_FILE_NAME}"

# SdrConnect (pinned to commit)
ARG SDRCONNECT_COMMIT=134aeab59bb09c93bfeadea492098ebb671ada9b
ARG SDRCONNECT_PLUGIN_FILE_NAME=sdrconnect.smx
ARG SDRCONNECT_PLUGIN_URL=https://codeberg.org/spire/sdrconnect/raw/commit/${SDRCONNECT_COMMIT}/plugin/${SDRCONNECT_PLUGIN_FILE_NAME}
ARG SDRCONNECT_PLUGIN_CHECKSUM=4c7c268b3b77c815fbcd56077534b9d9eafc23b3feacc4d6545474663916c712
ADD --checksum=sha256:${SDRCONNECT_PLUGIN_CHECKSUM} ${SDRCONNECT_PLUGIN_URL} .
RUN cp "${SDRCONNECT_PLUGIN_FILE_NAME}" "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/${SDRCONNECT_PLUGIN_FILE_NAME}"


FROM tf2-summon-core-addons

ARG PLUGIN_INSTALL_DIR=/server/tf
COPY --from=competitive-downloads --chown=tf2 "${PLUGIN_INSTALL_DIR}/" "${SERVER_DIR}/tf/"
