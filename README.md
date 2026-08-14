# tf2-summon

A self-contained Team Fortress 2 reservation server image for
[Summon](https://github.com/cometsmarsblackberry/summon). It includes the game
server, Metamod:Source, SourceMod, competitive configs, reservation plugins,
and the command-line RCON client expected by the Summon agent.

The public images are available through GitHub Container Registry:

```bash
docker pull ghcr.io/cometsmarsblackberry/tf2-summon/i386:nightly
docker pull ghcr.io/cometsmarsblackberry/tf2-summon/amd64:nightly
```

Both images use the `linux/amd64` container platform. The `/i386` image runs
32-bit SRCDS, while `/amd64` runs the native 64-bit TF2 server. The root image
name remains an alias for `/i386` for compatibility.

Some bundled third-party native SourceMod extensions only provide 32-bit Linux
binaries. Their dependent optional plugins are unavailable in the `/amd64`
variant until upstream Linux x86-64 ports exist; Summon, Map Downloader,
Metamod:Source, SourceMod, and RCON are covered by the 64-bit image contract.

## Run

Summon normally starts the image automatically. A minimal manual launch is:

```bash
docker run --rm \
  -p 27015:27015/tcp \
  -p 27015:27015/udp \
  -p 27020:27020/udp \
  -e RCON_PASSWORD=change-me \
  -e SERVER_PASSWORD=join-password \
  -e SERVER_HOSTNAME='Summon TF2 server' \
  ghcr.io/cometsmarsblackberry/tf2-summon/i386:nightly \
  +map cp_badlands
```

The container exposes game/RCON traffic on TCP and UDP port 27015 and
SourceTV on UDP port 27020. It intentionally declares no volumes: Summon uses
disposable containers and copies logs out before shutdown.

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `RCON_PASSWORD` | `123456` | RCON authentication |
| `SERVER_HOSTNAME` | `A Team Fortress 2 server` | Public server name |
| `SERVER_PASSWORD` | empty | Player password |
| `STV_NAME` | `Source TV` | SourceTV name |
| `STV_TITLE` | `A Team Fortress 2 server Source TV` | SourceTV title |
| `STV_PASSWORD` | empty | SourceTV password |
| `DOWNLOAD_URL` | empty | FastDL base URL |
| `SM_MAP_DOWNLOAD_BASE` | `https://fastdl.serveme.tf/maps` | Map download base URL |
| `SUMMON_START_MAP` | empty | Map to fetch and launch before SRCDS starts; unavailable maps fall back to `cp_badlands` |
| `DEMOS_TF_APIKEY` | empty | demos.tf API key |
| `LOGS_TF_APIKEY` | empty | logs.tf API key |
| `MOTD_URL` | empty | URL written to the generated MOTD file |
| `SM_ADMINS` | empty | Comma-separated Steam IDs granted SourceMod root access |
| `ENABLE_FAKE_IP` | `0` | Set to `1` to enable Steam Datagram Relay FakeIP |
| `SERVER_TOKEN` | empty | Game server login token |
| `IP` | `0.0.0.0` | Bind address |
| `PORT` | `27015` | Game and RCON port |
| `CLIENT_PORT` | `27016` | Client port |
| `STEAM_PORT` | `27018` | Steam master-server port |
| `STV_PORT` | `27020` | SourceTV port |

Additional SRCDS arguments are passed after the image name. The image defaults
to `+sv_pure 1 +map cp_badlands +maxplayers 24` when no arguments are supplied.

Summon sets `SUMMON_START_MAP` while retaining `+map cp_badlands` as a
command-line fallback. Before SRCDS starts, the entrypoint fetches a missing
uncompressed BSP from `SM_MAP_DOWNLOAD_BASE`. It installs the file atomically
only after validating its Source BSP header and lump bounds, applies a 512 MiB
download ceiling, then starts directly on the requested map. Invalid names and
missing, corrupt, oversized, or slow downloads leave the bundled `cp_badlands`
startup unchanged.

The runtime contract intentionally keeps the server at `/home/tf2/server`,
including the RCON client at `/home/tf2/server/rcon` and game files at
`/home/tf2/server/tf`.

## Build and test

Docker Buildx 0.17 or newer is required because the build uses local target
contexts to keep every layer in this repository:

`base` → `sourcemod` → `core-addons` → `competitive-assets` → final image

The core addons target contains general-purpose SourceMod extensions and
plugins. The competitive assets target adds league configs, game modes, and
match integrations. The root Dockerfile applies only the Summon-specific
plugins, configuration, metadata, and runtime policy.

```bash
docker buildx bake image image-amd64 --load
tests/validate.sh
tests/contract.sh tf2-summon:local i386
tests/contract.sh tf2-summon:amd64-local amd64
```

Set `SUMMON_EXACT=1` to exercise Summon's fixed host ports and FakeIP launch
path. Set `CONTAINER_RUNTIME=podman` to run the same contract with rootless
Podman after loading the image into Podman's image store.

The first build downloads the current TF2 dedicated server and can take a
while. GitHub Actions checks Valve's current TF2 server version hourly. When
either published architecture is stale, it rebuilds and contract-tests both
images before replacing the `nightly` tags. A daily unconditional rebuild also
captures Steam depot updates that do not change the server compatibility
version. Pushes, tags, pull requests, and manual runs still build
unconditionally. Published images record the installed version in the
`tf2.server.version` OCI label. Non-scheduled publishes retain the existing
commit-SHA and semantic-version tag rules.

The workflow publishes updated images but does not restart existing containers.
Consumers must pull `nightly` and recreate their disposable server containers
to use the new TF2 build.

## License

The repository build files are available under the MIT License. Bundled game,
plugin, extension, and configuration projects retain their respective
licenses.
