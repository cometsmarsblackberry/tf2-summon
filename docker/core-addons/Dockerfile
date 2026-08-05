FROM ubuntu:22.04 AS downloaded-addons
# General-purpose SourceMod plugins and native extensions shared by all images.
SHELL ["/bin/bash", "-c"]
RUN export DEBIAN_FRONTEND=noninteractive \
    && export TZ=Etc/UTC \
    && apt-get -y update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
    unzip \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /download
ARG PLUGIN_INSTALL_DIR=/server/tf
RUN mkdir -p "${PLUGIN_INSTALL_DIR}"

# tf2-comp-fixes
ARG COMP_FIXES_FILE_NAME=tf2-comp-fixes.zip
ARG COMP_FIXES_VERSION=1.16.19
ARG COMP_FIXES_URL=https://github.com/ldesgoui/tf2-comp-fixes/releases/download/v${COMP_FIXES_VERSION}/${COMP_FIXES_FILE_NAME}
ARG COMP_FIXES_CHECKSUM=4a54bdafda9d8f462ac5bfcc9d402840f1954dbfacdb5d17a06e20b796e760e1
ADD --checksum=sha256:${COMP_FIXES_CHECKSUM} ${COMP_FIXES_URL} .
RUN unzip -q -o "${COMP_FIXES_FILE_NAME}" -d "${PLUGIN_INSTALL_DIR}/"

# SM_Neocurl
ARG NEOCURL_FILE_NAME=sm-neocurl-repack.zip
ARG NEOCURL_VERSION=v2.0.1-beta1
ARG NEOCURL_URL=https://github.com/sapphonie/SM-neocurl-ext/releases/download/${NEOCURL_VERSION}/${NEOCURL_FILE_NAME}
ARG NEOCURL_CHECKSUM=cddbef00ca5b4b2a14c35fd062fe18586fb42f68c6d6366bf74f5b72a5734e44
ADD --checksum=sha256:${NEOCURL_CHECKSUM} ${NEOCURL_URL} .
RUN unzip -q -o "${NEOCURL_FILE_NAME}" -d "${PLUGIN_INSTALL_DIR}/addons/sourcemod/"

# STAC Anti-Cheat
ARG STAC_FILE_NAME=stac.zip
ARG STAC_VERSION=v6.3.8
ARG STAC_URL=https://github.com/sapphonie/StAC-tf2/releases/download/${STAC_VERSION}/${STAC_FILE_NAME}
ARG STAC_CHECKSUM=ec64fc4f697754038526591cc8ef6a99d331b5e962eac36d968dfb25c0c69957
ADD --checksum=sha256:${STAC_CHECKSUM} ${STAC_URL} .
RUN unzip -q -o "${STAC_FILE_NAME}" -d "${PLUGIN_INSTALL_DIR}/addons/sourcemod/"

# sm-ripext (REST in Pawn Extension)
ARG RIPEXT_FILE_NAME=sm-ripext-1.3.2-linux.zip
ARG RIPEXT_VERSION=1.3.2
ARG RIPEXT_URL=https://github.com/ErikMinekus/sm-ripext/releases/download/${RIPEXT_VERSION}/${RIPEXT_FILE_NAME}
ARG RIPEXT_CHECKSUM=c3afa6173b2d5210110e139b00cfb03f04c5615f44840d83be46aa60fc497624
ADD --checksum=sha256:${RIPEXT_CHECKSUM} ${RIPEXT_URL} .
RUN unzip -q -o "${RIPEXT_FILE_NAME}" -d "${PLUGIN_INSTALL_DIR}/"

# SteamWorks extension
ARG STEAMWORKS_VERSION=1.2.3c
ARG STEAMWORKS_FILE_NAME=package-lin.tgz
ARG STEAMWORKS_URL=https://github.com/KyleSanderson/SteamWorks/releases/download/${STEAMWORKS_VERSION}/${STEAMWORKS_FILE_NAME}
ARG STEAMWORKS_CHECKSUM=6679e6dfd19d4c78a71d224ff3f7d72d9becbc256082ed4bce85cbaa1e012713
ADD --checksum=sha256:${STEAMWORKS_CHECKSUM} ${STEAMWORKS_URL} .
RUN tar xzf "${STEAMWORKS_FILE_NAME}" -C "${PLUGIN_INSTALL_DIR}/"

# System2 extension (DISABLED - upstream legacy.inc has syntax incompatibility with SM 1.12)
# ARG SYSTEM2_VERSION=v3.3.2
# ARG SYSTEM2_FILE_NAME=system2.zip
# ARG SYSTEM2_URL=https://github.com/dordnung/System2/releases/download/${SYSTEM2_VERSION}/${SYSTEM2_FILE_NAME}
# ADD ${SYSTEM2_URL} .
# RUN unzip -q -o "${SYSTEM2_FILE_NAME}" -d "${PLUGIN_INSTALL_DIR}/addons/sourcemod/"

# SM-TickrateChanger (release zip)
# ARG TICKRATE_CHANGER_VERSION=1.1.1
# ARG TICKRATE_CHANGER_FILE_NAME=SM-TickrateChanger.zip
# ARG TICKRATE_CHANGER_URL=https://github.com/Mikusch/SM-TickrateChanger/releases/download/${TICKRATE_CHANGER_VERSION}/${TICKRATE_CHANGER_FILE_NAME}
# ARG TICKRATE_CHANGER_CHECKSUM=8430b45fd961f18c53131c44f879f8effb691a8213775f5b3ae1a85b2e0dfe34
# ADD --checksum=sha256:${TICKRATE_CHANGER_CHECKSUM} ${TICKRATE_CHANGER_URL} .
# RUN unzip -q -o "${TICKRATE_CHANGER_FILE_NAME}" -d "${PLUGIN_INSTALL_DIR}/addons/sourcemod/"

# TF2-Imageboard-GreenText (release smx)
# ARG GREENTEXT_VERSION=1.0.0
# ARG GREENTEXT_FILE_NAME=tf2_4chan_quoter.smx
# ARG GREENTEXT_URL=https://github.com/KohtepSP/TF2-Imageboard-GreenText/releases/download/${GREENTEXT_VERSION}/${GREENTEXT_FILE_NAME}
# ARG GREENTEXT_CHECKSUM=e24d4a5db1034e18c16aeefe4ca49810c4831ab74c754cdce3b3ace0f7804e13
# ADD --checksum=sha256:${GREENTEXT_CHECKSUM} ${GREENTEXT_URL} "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/${GREENTEXT_FILE_NAME}"

# funcommandsX (precompiled with translations and config)
# ARG FUNCOMMANDSX_COMMIT=5467d433cbcfb666581ea08edc2a267d3578d5b7
# ARG FUNCOMMANDSX_BASE_URL=https://raw.githubusercontent.com/Dosergen/Stuff/${FUNCOMMANDSX_COMMIT}/funcommandsX
# ARG FUNCOMMANDSX_PLUGIN_CHECKSUM=fa788add4542a29ff7ba1f3c48a76eab793812775c50b8f8f2e2bbf7bb37ad8d
# ARG FUNCOMMANDSX_TRANSLATIONS_CHECKSUM=2f33a8b89cfcaae84ed87e7441de57654be645d4981e25f5f3624006117c140d
# ARG FUNCOMMANDSX_CONFIG_CHECKSUM=39e2dfc31c3b124cc3d534157c723d84c950ab4d02b31eaa2303ddeec2f39aa7
# ADD --checksum=sha256:${FUNCOMMANDSX_PLUGIN_CHECKSUM} ${FUNCOMMANDSX_BASE_URL}/plugins/funcommandsX.smx "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/funcommandsX.smx"
# ADD --checksum=sha256:${FUNCOMMANDSX_TRANSLATIONS_CHECKSUM} ${FUNCOMMANDSX_BASE_URL}/translations/funcommandsX.phrases.txt "${PLUGIN_INSTALL_DIR}/addons/sourcemod/translations/funcommandsX.phrases.txt"
# ADD --checksum=sha256:${FUNCOMMANDSX_CONFIG_CHECKSUM} ${FUNCOMMANDSX_BASE_URL}/configs/happy_phrases.ini "${PLUGIN_INSTALL_DIR}/addons/sourcemod/configs/happy_phrases.ini"

# Reloadmap (precompiled)
ARG RELOADMAP_COMMIT=5256b9ea833d5362afbd2effeb0e3ac370178412
ARG RELOADMAP_URL=https://raw.githubusercontent.com/WidovV/Reloadmap/${RELOADMAP_COMMIT}/plugins/reloadmap.smx
ARG RELOADMAP_CHECKSUM=43a2abe919bed8b13c0668d2d209035a47ffc99b10dc4264caf0669c5fac5a14
ADD --checksum=sha256:${RELOADMAP_CHECKSUM} ${RELOADMAP_URL} "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/reloadmap.smx"

# TF2-Simple-FOV (precompiled)
# ARG SIMPLE_FOV_COMMIT=main
# ARG SIMPLE_FOV_URL=https://raw.githubusercontent.com/CallMeBlad3z/TF2-Simple-FOV/${SIMPLE_FOV_COMMIT}/plugins/simple-fov.smx
# ADD ${SIMPLE_FOV_URL} "${PLUGIN_INSTALL_DIR}/addons/sourcemod/plugins/simple-fov.smx"

# ============================================================================
# Stage 2: Compile source-only plugins
# ============================================================================
FROM ubuntu:22.04 AS compiler
SHELL ["/bin/bash", "-c"]
RUN export DEBIAN_FRONTEND=noninteractive \
    && export TZ=Etc/UTC \
    && apt-get -y update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
    wget \
    ca-certificates \
    lib32stdc++6 \
    lib32z1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /compile

# Download SourceMod for the compiler (use latest stable)
ARG SOURCEMOD_URL=https://sm.alliedmods.net/smdrop/1.12/sourcemod-1.12.0-git7221-linux.tar.gz
ARG SOURCEMOD_CHECKSUM=8924d7cd664a52ff0dd84a493949040865d0984b01f3c4b569db7357c592b56f
RUN wget -q "${SOURCEMOD_URL}" -O sourcemod.tar.gz \
    && echo "${SOURCEMOD_CHECKSUM}  sourcemod.tar.gz" | sha256sum -c - \
    && mkdir -p /sourcemod \
    && tar xzf sourcemod.tar.gz -C /sourcemod \
    && chmod +x /sourcemod/addons/sourcemod/scripting/spcomp

# Set up scripting directory
RUN mkdir -p /compile/scripting/include /compile/plugins /compile/gamedata

# Copy default includes
RUN cp -r /sourcemod/addons/sourcemod/scripting/include/* /compile/scripting/include/

# Download additional include files for extensions
# SteamWorks include
ARG STEAMWORKS_INC_COMMIT=f0c1b62dff615511b27824aaa2815c7dc58d2716
ARG STEAMWORKS_INC_CHECKSUM=e636b7da86d2a95c7cd4a89275eff7ea9e7f5cadaa7287937943591865d2b341
ADD --checksum=sha256:${STEAMWORKS_INC_CHECKSUM} https://raw.githubusercontent.com/KyleSanderson/SteamWorks/${STEAMWORKS_INC_COMMIT}/Pawn/includes/SteamWorks.inc /compile/scripting/include/SteamWorks.inc

# System2 include (DISABLED - upstream legacy.inc has syntax incompatibility with SM 1.12)
# ARG SYSTEM2_INC_COMMIT=master
# RUN mkdir -p /compile/scripting/include/system2
# ADD https://raw.githubusercontent.com/dordnung/System2/${SYSTEM2_INC_COMMIT}/sourcemod/scripting/include/system2.inc /compile/scripting/include/system2.inc
# ADD https://raw.githubusercontent.com/dordnung/System2/${SYSTEM2_INC_COMMIT}/sourcemod/scripting/include/system2/legacy.inc /compile/scripting/include/system2/legacy.inc
# ADD https://raw.githubusercontent.com/dordnung/System2/${SYSTEM2_INC_COMMIT}/sourcemod/scripting/include/system2/request.inc /compile/scripting/include/system2/request.inc


# Download source files for plugins that need compilation
# ChatExec
ARG CHATEXEC_COMMIT=61e45b9d3b4207ab92b40c8b8266bb0404a3c196
ARG CHATEXEC_CHECKSUM=dbcb3da2d0ae482de9671f5ca374486ee0e18ea75a97a584111abff209655459
ADD --checksum=sha256:${CHATEXEC_CHECKSUM} https://raw.githubusercontent.com/SNWCreations/ChatExec/${CHATEXEC_COMMIT}/scripting/chat_exec.sp /compile/scripting/chat_exec.sp

# Command_Buffer (source + gamedata)
ARG COMMAND_BUFFER_COMMIT=390b8b12e55204d1201cd8d85d5dc9fadcbca9a9
ARG COMMAND_BUFFER_PLUGIN_CHECKSUM=5d5ab9088e53e1ba2390a8d386621ffb4c9cda662c148c489cc90495b0c56d20
ARG COMMAND_BUFFER_GAMEDATA_CHECKSUM=adeb663f7e7700a34a9137973b1c062958c0c4bffdb53ca43bf9b6218593efb8
ADD --checksum=sha256:${COMMAND_BUFFER_PLUGIN_CHECKSUM} https://raw.githubusercontent.com/SilvDev/Command_Buffer/${COMMAND_BUFFER_COMMIT}/scripting/command_buffer.sp /compile/scripting/command_buffer.sp
ADD --checksum=sha256:${COMMAND_BUFFER_GAMEDATA_CHECKSUM} https://raw.githubusercontent.com/SilvDev/Command_Buffer/${COMMAND_BUFFER_COMMIT}/gamedata/command_buffer.games.txt /compile/gamedata/command_buffer.games.txt

# HideViewmodel (regular version with clientprefs)
# ARG HIDEVIEWMODEL_COMMIT=87cd1eb4dd6b6654db46c532bfd0dd33b3a7062e
# ARG HIDEVIEWMODEL_CHECKSUM=2ecd287823fd0c3108e4ed8233ab9770d57a7ab1d0896682402e207ca29b83c0
# ADD --checksum=sha256:${HIDEVIEWMODEL_CHECKSUM} https://raw.githubusercontent.com/notkoen/HideViewmodel/${HIDEVIEWMODEL_COMMIT}/HideViewmodel.sp /compile/scripting/HideViewmodel.sp

# linux_file_lowercaser (source + gamedata)
ARG LINUX_LOWERCASER_COMMIT=b3abce9547997eab0534f46a2c6f9654709cb041
ARG LINUX_LOWERCASER_PLUGIN_CHECKSUM=f770fd8315378927c82000496520a4d30abf2d80fc5d25db62eb6c1b2b4307c8
ARG LINUX_LOWERCASER_GAMEDATA_CHECKSUM=8d9111f9b1dbe71272bfa8f70dfcd22d70815236b1a80327584cce084a2b4b66
ADD --checksum=sha256:${LINUX_LOWERCASER_PLUGIN_CHECKSUM} https://raw.githubusercontent.com/rtldg/linux_file_lowercaser/${LINUX_LOWERCASER_COMMIT}/addons/sourcemod/scripting/linux_file_lowercaser.sp /compile/scripting/linux_file_lowercaser.sp
ADD --checksum=sha256:${LINUX_LOWERCASER_GAMEDATA_CHECKSUM} https://raw.githubusercontent.com/rtldg/linux_file_lowercaser/${LINUX_LOWERCASER_COMMIT}/addons/sourcemod/gamedata/linux_file_lowercaser.txt /compile/gamedata/linux_file_lowercaser.txt

# noautokick and nospecmsg (from sapphonie/gameservers)
# ARG SAPPHONIE_COMMIT=3407bb856fc3a34e7e28e7afebb82c7683378e7c
# ARG NOAUTOKICK_CHECKSUM=59d0affdc1c745153159dc7862ab0256f0bb625098d10b04ee06cc6ac48c84f1
# ARG NOSPECMSG_CHECKSUM=a98dae556372692fb03c544ed996fb99be0c44a206af90ad72ac43d46d87c3b9
# ADD --checksum=sha256:${NOAUTOKICK_CHECKSUM} https://raw.githubusercontent.com/sapphonie/gameservers/${SAPPHONIE_COMMIT}/tf/addons/sourcemod/scripting/noautokick.sp /compile/scripting/noautokick.sp
# ADD --checksum=sha256:${NOSPECMSG_CHECKSUM} https://raw.githubusercontent.com/sapphonie/gameservers/${SAPPHONIE_COMMIT}/tf/addons/sourcemod/scripting/nospecmsg.sp /compile/scripting/nospecmsg.sp

# PlayerAnalytics (source + gamedata)
# ARG PLAYERANALYTICS_COMMIT=master
# ADD https://raw.githubusercontent.com/sneak-it/PlayerAnalytics/${PLAYERANALYTICS_COMMIT}/scripting/player_analytics.sp /compile/scripting/player_analytics.sp
# ADD https://raw.githubusercontent.com/sneak-it/PlayerAnalytics/${PLAYERANALYTICS_COMMIT}/gamedata/detect_os.games.txt /compile/gamedata/detect_os.games.txt

# restartsoon (from sapphonie/gameservers)
# syskill DISABLED - requires System2 which has upstream syntax incompatibility
# ARG RESTARTSOON_CHECKSUM=e3c35c9003f1f134a1c3e05673662eca7d8f65deffe6829f2eae34043c3da4b5
# ADD --checksum=sha256:${RESTARTSOON_CHECKSUM} https://raw.githubusercontent.com/sapphonie/gameservers/${SAPPHONIE_COMMIT}/tf/addons/sourcemod/scripting/restartsoon.sp /compile/scripting/restartsoon.sp
# ADD https://raw.githubusercontent.com/sapphonie/gameservers/${SAPPHONIE_COMMIT}/tf/addons/sourcemod/scripting/syskill.sp /compile/scripting/syskill.sp

# Spray_Exploit
ARG SPRAY_EXPLOIT_COMMIT=ade947bc4976c42b8fba751396deca48881546e5
ARG SPRAY_EXPLOIT_CHECKSUM=887ba0e80320176ade169778daa63a7711f9899714b863084f7460074609106c
ADD --checksum=sha256:${SPRAY_EXPLOIT_CHECKSUM} https://raw.githubusercontent.com/SilvDev/Spray_Exploit/${SPRAY_EXPLOIT_COMMIT}/scripting/spray_exploit_fixer.sp /compile/scripting/spray_exploit_fixer.sp

# webshortcuts (from castaway-plugins)
# ARG CASTAWAY_COMMIT=master
# ADD https://raw.githubusercontent.com/rsedxcftvgyhbujnkiqwe/castaway-plugins/${CASTAWAY_COMMIT}/scripting/webshortcuts.sp /compile/scripting/webshortcuts.sp

# arena-autoscramble (from castaway-plugins)
# ADD https://raw.githubusercontent.com/rsedxcftvgyhbujnkiqwe/castaway-plugins/${CASTAWAY_COMMIT}/scripting/arena-autoscramble.sp /compile/scripting/arena-autoscramble.sp
# ADD https://raw.githubusercontent.com/rsedxcftvgyhbujnkiqwe/castaway-plugins/${CASTAWAY_COMMIT}/scripting/include/scramble.inc /compile/scripting/include/scramble.inc

# Compile all source plugins
RUN set -Eeuo pipefail; \
    cd /compile/scripting; \
    for sp_file in *.sp; do \
      echo "Compiling ${sp_file}..."; \
      /sourcemod/addons/sourcemod/scripting/spcomp \
        -i/compile/scripting/include \
        -i/sourcemod/addons/sourcemod/scripting/include \
        -o/compile/plugins/${sp_file%.sp}.smx \
        "${sp_file}"; \
    done

# ============================================================================
# Final stage: Combine everything
# ============================================================================
FROM tf2-summon-sourcemod

ARG PLUGIN_INSTALL_DIR=/server/tf
COPY --from=downloaded-addons --chown=tf2 "${PLUGIN_INSTALL_DIR}/" "${SERVER_DIR}/tf/"

# Copy compiled plugins
COPY --from=compiler --chown=tf2 /compile/plugins/*.smx "${SERVER_DIR}/tf/addons/sourcemod/plugins/"

# Copy gamedata files
COPY --from=compiler --chown=tf2 /compile/gamedata/*.txt "${SERVER_DIR}/tf/addons/sourcemod/gamedata/"

# Disable useless plugins
RUN mkdir -p "${SERVER_DIR}/tf/addons/sourcemod/plugins/disabled" \
    && mv \
      "${SERVER_DIR}/tf/addons/sourcemod/plugins/funcommands.smx" \
      "${SERVER_DIR}/tf/addons/sourcemod/plugins/funvotes.smx" \
      "${SERVER_DIR}/tf/addons/sourcemod/plugins/disabled/"

ENV DOWNLOAD_URL=
ENV SM_MAP_DOWNLOAD_BASE=https://fastdl.serveme.tf/maps
