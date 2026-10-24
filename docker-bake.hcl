group "default" {
  targets = ["image", "image-amd64", "image-sigsegv"]
}

variable "TF2_SERVER_VERSION" {
  default = "unknown"
}

# Summon's SourceMod plugin sources, pinned to a summon commit. Point this at a
# local checkout (for example ../summon/tf2-reservation-plugin) to build an image
# with unpublished plugin changes.
variable "SUMMON_PLUGIN_SOURCE" {
  default = "https://github.com/cometsmarsblackberry/summon.git#237985b5aa6660b82f8e771344bd3ac2ab9a1643:tf2-reservation-plugin"
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

# The 32-bit image with the sigsegv-mvm Optimize-Only extension added as a final
# layer, so it differs from the image target only by the extension.
target "image-sigsegv" {
  inherits   = ["docker-metadata-action"]
  context    = "./docker/sigsegv"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]
  tags       = ["tf2-summon:sigsegv-local"]

  contexts = {
    tf2-summon-image = "target:image"
  }
}
