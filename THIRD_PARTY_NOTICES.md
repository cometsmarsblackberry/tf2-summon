# Third-party notices

The tf2-summon images bundle the third-party software listed below. Each entry
gives the installed version, its license, and where its source code is
published. The license texts are in the `licenses/` directory next to this
file. Images install both in `/usr/share/doc/tf2-summon/`; paths that begin
with `tf/` are relative to the server directory, `/home/tf2/server`.

The tf2-summon build files are available under the MIT License (`LICENSE`).
They download, compile, and install everything listed here. Published images
were built from the commit of https://github.com/cometsmarsblackberry/tf2-summon
recorded in their `org.opencontainers.image.revision` label.

## Source code

The source code for each component is published at its "Source" location, at
the version listed. For software under the GNU General Public License, that
location provides the corresponding source code for the binaries in the image.
The plugins that the tf2-summon build compiles itself are compiled from the
listed commit.

### Written offer for GPL-2.0 source

SrcTV+ is licensed under the GNU General Public License version 2. For at
least three years after the last distribution of an image that contains it,
the tf2-summon maintainers will give any third party a complete
machine-readable copy of the corresponding source code for SrcTV+, and for any
other code in the image licensed under GPL-2.0, for a charge no more than the
cost of physically performing the source distribution. Request it by opening an
issue at https://github.com/cometsmarsblackberry/tf2-summon/issues.

### Components without a published license

Some upstream projects publish no license. They are marked "none published"
and listed with their authors and source. SourceMod's license
(`tf/addons/sourcemod/LICENSE.txt`) describes SourceMod plugins as derivative
works of SourceMod.

## Base image

### Valve software

The Team Fortress 2 dedicated server (Steam app 232250) and SteamCMD are
proprietary software of Valve Corporation, installed from Valve's servers and
subject to Valve's terms. No license in this file applies to them.

### Ubuntu packages

The Ubuntu 22.04 packages in the image record their copyright and license
terms in `/usr/share/doc/<package>/copyright`.

### rcon

- Version: commit e7e2d9bb21930d7e2b00f9b35effe1eee1ec5585
- License: BSD-2-Clause (`licenses/rcon.txt`)
- Source: https://github.com/n0la/rcon/tree/e7e2d9bb21930d7e2b00f9b35effe1eee1ec5585
- Installed: `/home/tf2/server/rcon`

## Metamod:Source and SourceMod

### Metamod:Source

- Version: 1.12.0-git1228 (release 1.12.0.1228)
- License: zlib/libpng (`licenses/metamod-source.txt`)
- Source: https://github.com/alliedmodders/metamod-source; the `meta version`
  server command prints the commit the build was made from

### SourceMod

- Version: 1.12.0-git7255 (release 1.12.0.7255)
- License: GPL-3.0 with the exceptions in `tf/addons/sourcemod/LICENSE.txt`
  (`licenses/GPL-3.0.txt`)
- Source: https://github.com/alliedmodders/sourcemod; the `sm version` server
  command prints the commit the build was made from. The sources of SourceMod's
  own plugins are also installed in `tf/addons/sourcemod/scripting/`.

## Core add-ons

### TF2 Competitive Fixes

- Version: v1.18.1
- License: GPL-3.0 (`licenses/GPL-3.0.txt`)
- Source: https://github.com/ldesgoui/tf2-comp-fixes/tree/v1.18.1; also
  installed in `tf/addons/sourcemod/scripting/`

### SM-neocurl-ext

- Version: v2.0.1-beta1
- License: none published; the extension is built on the SourceMod SDK
  (GPL-3.0, `licenses/GPL-3.0.txt`)
- Source: https://github.com/sapphonie/SM-neocurl-ext/tree/v2.0.1-beta1
- Bundled in `curl.ext.so`:
  - curl 8.0.1: curl license (`licenses/curl-8.0.1.txt`)
  - OpenSSL 3.1.0: Apache-2.0 (`licenses/Apache-2.0.txt`)
  - nghttp2 1.51.0: MIT (`licenses/nghttp2.txt`)
  - libssh2: BSD-3-Clause (`licenses/libssh2.txt`)
  - Brotli: MIT (`licenses/brotli.txt`)
  - zlib 1.2.13: zlib license

### StAC

- Version: v6.3.13
- License: GPL-3.0 (`licenses/GPL-3.0.txt`)
- Source: https://github.com/sapphonie/StAC-tf2/tree/v6.3.13; also installed
  in `tf/addons/sourcemod/scripting/`

### REST in Pawn (sm-ripext)

- Version: 1.3.2
- License: GPL-3.0 (`licenses/GPL-3.0.txt`)
- Source: https://github.com/ErikMinekus/sm-ripext/tree/1.3.2, which also
  contains the source of the bundled libraries
- Bundled in `rip.ext.so`:
  - curl 7.75.0: curl license (`licenses/curl-7.75.0.txt`)
  - jansson 2.13.1: MIT (`licenses/jansson.txt`)
  - libuv 1.41.0: MIT (`licenses/libuv.txt`)
  - Mbed TLS 2.25.0: Apache-2.0 (`licenses/Apache-2.0.txt`)
  - nghttp2 1.43.0: MIT (`licenses/nghttp2.txt`)
  - zlib 1.2.11: zlib license

### SteamWorks

- Version: 1.2.3c
- License: GPL-3.0 (`licenses/GPL-3.0.txt`)
- Source: https://github.com/KyleSanderson/SteamWorks/tree/1.2.3c

### Reloadmap

- Version: commit 5256b9ea833d5362afbd2effeb0e3ac370178412
- Author: WidovV
- License: none published
- Source: https://github.com/WidovV/Reloadmap/tree/5256b9ea833d5362afbd2effeb0e3ac370178412

### Chat Exec

- Version: commit 61e45b9d3b4207ab92b40c8b8266bb0404a3c196
- License: MIT (`licenses/chatexec.txt`). Upstream states the license in its
  README and publishes no license file.
- Source: https://github.com/SNWCreations/ChatExec/tree/61e45b9d3b4207ab92b40c8b8266bb0404a3c196

### Command Buffer

- Version: commit 390b8b12e55204d1201cd8d85d5dc9fadcbca9a9
- License: GPL-3.0 (`licenses/GPL-3.0.txt`)
- Source: https://github.com/SilvDev/Command_Buffer/tree/390b8b12e55204d1201cd8d85d5dc9fadcbca9a9

### linux_file_lowercaser

- Version: commit b3abce9547997eab0534f46a2c6f9654709cb041
- License: GPL-3.0-or-later (`licenses/GPL-3.0.txt`)
- Source: https://github.com/rtldg/linux_file_lowercaser/tree/b3abce9547997eab0534f46a2c6f9654709cb041

### Spray Exploit Fixer

- Version: commit ade947bc4976c42b8fba751396deca48881546e5
- License: GPL-3.0 (`licenses/GPL-3.0.txt`)
- Source: https://github.com/SilvDev/Spray_Exploit/tree/ade947bc4976c42b8fba751396deca48881546e5

### Spell Banlist

- Version: commit dbad665a7d437fd80547c4fd84481ca50d712d07 of serveme
- Author: Coco
- License: Apache-2.0, the license of the serveme repository
  (`licenses/Apache-2.0.txt`)
- Source: https://github.com/Arie/serveme/blob/dbad665a7d437fd80547c4fd84481ca50d712d07/docker/tf2-cloud-server/spells_blocker.sp

## Competitive assets

### SOAP TF2DM

- Version: v4.4.9
- Authors: Icewind, MikeJS, Lange, and Tondark; maintained by sappho.io
- License: none published
- Source: https://github.com/sapphonie/SOAP-TF2DM/tree/v4.4.9; also installed
  in `tf/addons/sourcemod/scripting/`

### MGEMod

- Version: v3.1.0-beta39
- License: GPL-3.0 (`licenses/GPL-3.0.txt`)
- Source: https://github.com/mgetf/MGEMod/tree/v3.1.0-beta39; also installed
  in `tf/addons/sourcemod/scripting/`

### MGE Config Downloader

- Version: v1.4
- Author: ampere
- License: none published
- Source: https://github.com/mgetf/mge-config-downloader/tree/v1.4; also
  installed in `tf/addons/sourcemod/scripting/`

### F2's SourceMod Plugins

- Version: 20260717-1784284363049
- Author: F2
- License: none published
- Source: https://github.com/F2/F2s-sourcemod-plugins/tree/20260717-1784284363049
- Installed plugins: afk, fixstvslot, logstf, medicstats, pause, recordstv,
  restorescore, supstats2, and waitforstv

### ETF2L configs

- Version: 1.0.29
- License: MIT (`licenses/etf2l-gameserver-configs.txt`)
- Source: https://github.com/ETF2L/gameserver-configs/tree/1.0.29

### FBTF configs

- Version: season 25
- License: none published
- Source: https://fbtf.tf/uploads/cfgs/fbtf_cfg_s25.zip

### RGL server resources

- Version: v390
- License: GPL-3.0 (`licenses/GPL-3.0.txt`)
- Source: https://github.com/RGLgg/server-resources-updater/releases/tag/v390;
  the release archive contains the source of the installed config_checker,
  demo_check_no_discord, rglqol, rglupdater, roundtimer_override, and updater
  plugins
- Bundled: p4sstime v3.1.2, GPL-3.0 (`licenses/GPL-3.0.txt`), source
  https://github.com/p4sstime/p4sstime-server-resources/tree/v3.1.2

### ozfortress configs

- Version: commit e4baf2ee575a9f387eb13f5c096549458ff65752
- License: none published
- Source: https://github.com/ozfortress/server-configs/tree/e4baf2ee575a9f387eb13f5c096549458ff65752

### Ultitrio configs

- Version: commit 8d9381b94ea9c3865426268467a188a240270ed4
- License: none published
- Source: https://github.com/CoolstuffTF2/Ultitrio/tree/8d9381b94ea9c3865426268467a188a240270ed4

### AsiaFortress, CLTF2, TFArena, and UFL configs (serveme)

- Version: commit 3c5f2bd9dce37d8f416881f93a87fbb7037c3efd of serveme
- License: Apache-2.0, the license of the serveme repository
  (`licenses/Apache-2.0.txt`)
- Source: https://github.com/Arie/serveme/tree/3c5f2bd9dce37d8f416881f93a87fbb7037c3efd/docker/tf2-cloud-server/base-configs/cfg
- Modifications: the build replaces the `servercfg` command with
  `servercfgfile` in the CLTF2 and TFArena configs and marks each changed file
  with a comment on its first line.

### Improved Match Timer

- Version: commit 28f1f9a03c07a072684fa3d4977a0898a85b0588
- License: GPL-3.0 (`licenses/GPL-3.0.txt`)
- Source: https://github.com/dewbsku/Improved-Match-Timer/tree/28f1f9a03c07a072684fa3d4977a0898a85b0588;
  also installed in `tf/addons/sourcemod/scripting/`

### SrcTV+

- Version: v3.0
- License: GPL-2.0 (`licenses/GPL-2.0.txt`); see the written offer above
- Source: https://github.com/dalegaard/srctvplus/tree/v3.0

### demos.tf plugin

- Version: commit 467a8858e642729c2bdbc769a28c7d450a2c1123
- Authors: Icewind and sappho.io
- License: none published
- Source: https://codeberg.org/demostf/plugin/src/commit/467a8858e642729c2bdbc769a28c7d450a2c1123

### Whitelist Downloader

- Version: commit 6a1837dbd4f6432bb561a8278ede384471e22ab8
- License: MIT (`licenses/robin-appelman.txt`)
- Source: https://codeberg.org/spire/sm_whitelist/src/commit/6a1837dbd4f6432bb561a8278ede384471e22ab8

### SdrConnect

- Version: commit 134aeab59bb09c93bfeadea492098ebb671ada9b
- License: MIT (`licenses/robin-appelman.txt`)
- Source: https://codeberg.org/spire/sdrconnect/src/commit/134aeab59bb09c93bfeadea492098ebb671ada9b

## Summon plugins and tf2-summon overlay

### Summon and Map Downloader

- Version: the Summon commit pinned by `SUMMON_PLUGIN_SOURCE` in
  `docker-bake.hcl`
- License: Summon is licensed under AGPL-3.0
  (https://github.com/cometsmarsblackberry/summon/blob/main/LICENSE). Map
  Downloader is based on mapdownloader by Robin Appelman
  (https://codeberg.org/spire/mapdownloader), MIT (`licenses/robin-appelman.txt`).
- Source: https://github.com/cometsmarsblackberry/summon/tree/main/tf2-reservation-plugin

### Autoreload plugins

- Version: 1.16
- Author: Dragokas, based on the original plugin by Timiditas
- License: none published
- Source: https://forums.alliedmods.net/showthread.php?t=322045

## sigsegv variant

The `i386-sigsegv` image adds this extension to the `i386` image. Other images
do not contain it.

### sigsegv-mvm (Optimize-Only package)

- Version: release sv_parallel_sendsnapshot_fix, built from commit
  a2553414c8839bee0864b53524fcadec6d4a89c7
- License: BSD-2-Clause (`licenses/sigsegv-mvm.txt`)
- Source: https://github.com/potato-tf/sigsegv-mvm/tree/a2553414c8839bee0864b53524fcadec6d4a89c7
- Bundled: udis86, BSD-2-Clause (`licenses/udis86.txt`), source
  https://github.com/canihavesomecoffee/udis86/tree/5336633af70f3917760a6d441ff02d93477b0c86
