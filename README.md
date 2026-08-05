# tf2-summon

A self-contained Team Fortress 2 reservation server image for
[Summon](https://github.com/cometsmarsblackberry/summon). It includes the game
server, Metamod:Source, SourceMod, competitive configs, reservation plugins,
and the command-line RCON client expected by the Summon agent.

The public image is available through GitHub Container Registry:

```bash
docker pull ghcr.io/cometsmarsblackberry/tf2-summon/i386:nightly
```

The image runs 32-bit SRCDS on `linux/amd64`. The root image name and the
`/i386` image name are aliases for the same build.

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

The runtime contract intentionally keeps the server at `/home/tf2/server`,
including the RCON client at `/home/tf2/server/rcon` and game files at
`/home/tf2/server/tf`.

## Build and test

Docker Buildx 0.17 or newer is required because the build uses local target
contexts to keep every layer in this repository:

```bash
docker buildx bake image --load
tests/validate.sh
tests/contract.sh tf2-summon:local
```

Set `SUMMON_EXACT=1` to exercise Summon's fixed host ports and FakeIP launch
path. Set `CONTAINER_RUNTIME=podman` to run the same contract with rootless
Podman after loading the image into Podman's image store.

The first build downloads the current TF2 dedicated server and can take a
while. GitHub Actions validates the project, performs the same image contract
test, and publishes `nightly`, commit SHA, and semantic-version tags.

## License

The repository build files are available under the MIT License. Bundled game,
plugin, extension, and configuration projects retain their respective
licenses.
