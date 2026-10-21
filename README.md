# tf2-summon

The Team Fortress 2 server image used by
[Summon](https://github.com/cometsmarsblackberry/summon). It bundles the TF2
dedicated server, Metamod:Source, SourceMod, the Summon and Map Downloader
plugins, league configs and plugins (RGL, ETF2L, ozfortress, and others), and
the RCON client the Summon agent uses.

## Images

| Image | Description |
| --- | --- |
| `ghcr.io/cometsmarsblackberry/tf2-summon/i386:nightly` | 32-bit SRCDS. Summon's default. |
| `ghcr.io/cometsmarsblackberry/tf2-summon/amd64:nightly` | Native 64-bit SRCDS. Plugins that need 32-bit-only extensions are unavailable. |
| `ghcr.io/cometsmarsblackberry/tf2-summon/i386-sigsegv:nightly` | Experimental. `/i386` plus the Optimize-Only package of [sigsegv-mvm](https://github.com/potato-tf/sigsegv-mvm), which reduces server CPU usage. It can break after a TF2 update until upstream releases a fix. |

All images are `linux/amd64`. The image name without a suffix is an alias for
`/i386`.

CI checks hourly for a new TF2 server version and also rebuilds once a day. It
publishes a new `nightly` only after the contract tests pass. Running
containers are not updated: pull the image and recreate them.

## Run

Summon starts the image automatically. To launch it by hand:

```bash
docker run --rm \
  -p 27015:27015/tcp \
  -p 27015:27015/udp \
  -p 27020:27020/udp \
  -e RCON_PASSWORD=change-me \
  -e SERVER_PASSWORD=join-password \
  ghcr.io/cometsmarsblackberry/tf2-summon/i386:nightly \
  +map cp_badlands
```

Port 27015 carries game and RCON traffic, and 27020/udp carries SourceTV. The
container is meant to be disposable and declares no volumes.

Arguments after the image name are passed to SRCDS and replace the default
`+sv_pure 1 +map cp_badlands +maxplayers 24`. If you pass arguments, include
`+sv_pure` yourself, or the server runs at `sv_pure 0`.

## Configuration

| Variable | Default | Purpose |
| --- | --- | --- |
| `RCON_PASSWORD` | none (required) | RCON authentication. The container refuses to start without it. |
| `SERVER_HOSTNAME` | `A Team Fortress 2 server` | Public server name |
| `SERVER_PASSWORD` | empty | Player password |
| `STV_NAME` | `Source TV` | SourceTV name |
| `STV_TITLE` | `A Team Fortress 2 server Source TV` | SourceTV title |
| `STV_PASSWORD` | empty | SourceTV password |
| `DOWNLOAD_URL` | empty | FastDL base URL |
| `SM_MAP_DOWNLOAD_BASE` | `https://fastdl.serveme.tf/maps` | Map download base URL |
| `SUMMON_START_MAP` | empty | Map to download and start on. Unavailable maps fall back to `cp_badlands` |
| `DEMOS_TF_APIKEY` | empty | demos.tf API key |
| `LOGS_TF_APIKEY` | empty | logs.tf API key |
| `MOTD_URL` | empty | URL for the MOTD. Also enables a text MOTD naming the URL's host |
| `SM_ADMINS` | empty | Comma-separated Steam IDs granted SourceMod root access |
| `ENABLE_FAKE_IP` | `0` | Set to `1` to enable Steam Datagram Relay FakeIP |
| `SERVER_TOKEN` | empty | Game server login token |
| `IP` | `0.0.0.0` | Bind address |
| `PORT` | `27015` | Game and RCON port |
| `CLIENT_PORT` | `27016` | Client port |
| `STEAM_PORT` | `27018` | Steam master-server port |
| `STV_PORT` | `27020` | SourceTV port |

The Summon agent expects the server at `/home/tf2/server`, with the RCON
client at `/home/tf2/server/rcon`. In-game commands, pausing, and how configs
enable SOAP DM are described in the
[plugin README](https://github.com/cometsmarsblackberry/summon/blob/main/tf2-reservation-plugin/README.md).

## Build and test

Requires Docker Buildx 0.17 or newer. The first build downloads the TF2 server
and takes a while.

```bash
docker buildx bake image image-amd64 image-sigsegv --load
tests/validate.sh
tests/contract.sh tf2-summon:local i386
tests/contract.sh tf2-summon:amd64-local amd64
EXPECT_SIGSEGV=1 tests/contract.sh tf2-summon:sigsegv-local i386
```

`validate.sh` checks the repository without building anything.
`contract.sh` starts an image and checks the behavior Summon relies on. Set
`SUMMON_EXACT=1` to also test Summon's fixed host ports and FakeIP launch, or
`CONTAINER_RUNTIME=podman` to run the test with rootless Podman.

Each stage of the image has its own Dockerfile:

`docker/base` (TF2 server) → `docker/sourcemod` → `docker/core-addons` →
`docker/competitive-assets` → root `Dockerfile` (Summon plugins, configs, and
runtime policy) → `docker/sigsegv`

The Summon plugins are compiled during the build from Summon's
`tf2-reservation-plugin` directory, at the commit pinned by
`SUMMON_PLUGIN_SOURCE` in `docker-bake.hcl`. To ship plugin changes, push them
to Summon and update that commit. To build with a local checkout:

```bash
SUMMON_PLUGIN_SOURCE=../summon/tf2-reservation-plugin docker buildx bake image --load
```

## License

The build files in this repository are MIT-licensed. Bundled projects keep
their own licenses. [`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md) lists
each one with its version and source, and [`licenses/`](licenses/) holds the
license texts. Both are installed in the image under
`/usr/share/doc/tf2-summon/`. When you update a pinned download, update its
notice entry as well, or `tests/validate.sh` fails.
