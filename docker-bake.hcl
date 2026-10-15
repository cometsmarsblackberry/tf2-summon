group "default" {
  targets = ["image", "image-amd64"]
}

variable "TF2_SERVER_VERSION" {
  default = "unknown"
}

# Summon's SourceMod plugin sources, pinned to a summon commit. Point this at a
# local checkout (for example ../summon/tf2-reservation-plugin) to build an image
# with unpublished plugin changes.
variable "SUMMON_PLUGIN_SOURCE" {
  default = "https://github.com/cometsmarsblackberry/summon.git#7b9345af9c78411201d5ca1bf034a26fc67d9e93:tf2-reservation-plugin"
}

target "docker-metadata-action" {}

target "base" {
  context    = "./docker/base"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]

  args = {
    TF2_SERVER_VERSION = TF2_SERVER_VERSION
  }
}

target "sourcemod" {
  context    = "./docker/sourcemod"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]

  contexts = {
    tf2-summon-base = "target:base"
  }
}

target "core-addons" {
  context    = "./docker/core-addons"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]

  contexts = {
    tf2-summon-sourcemod = "target:sourcemod"
  }
}

target "competitive-assets" {
  context    = "./docker/competitive-assets"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]

  contexts = {
    tf2-summon-core-addons = "target:core-addons"
  }
}

target "image" {
  inherits   = ["docker-metadata-action"]
  context    = "."
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]
  tags       = ["tf2-summon:local"]

  args = {
    TF2_SERVER_VERSION = TF2_SERVER_VERSION
  }

  contexts = {
    tf2-summon-competitive-assets = "target:competitive-assets"
    summon-plugin                 = SUMMON_PLUGIN_SOURCE
  }
}

target "image-amd64" {
  inherits   = ["docker-metadata-action"]
  context    = "."
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]
  tags       = ["tf2-summon:amd64-local"]

  args = {
    SRCDS_EXEC         = "srcds_run_64"
    TF2_SERVER_ARCH    = "amd64"
    TF2_SERVER_VERSION = TF2_SERVER_VERSION
  }

  contexts = {
    tf2-summon-competitive-assets = "target:competitive-assets"
    summon-plugin                 = SUMMON_PLUGIN_SOURCE
  }
}
