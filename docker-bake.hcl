group "default" {
  targets = ["image", "image-amd64"]
}

target "docker-metadata-action" {}

target "base" {
  context    = "./docker/base"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]
}

target "sourcemod" {
  context    = "./docker/sourcemod"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]

  contexts = {
    tf2-summon-base = "target:base"
  }
}

target "plugins" {
  context    = "./docker/plugins"
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]

  contexts = {
    tf2-summon-sourcemod = "target:sourcemod"
  }
}

target "image" {
  inherits   = ["docker-metadata-action"]
  context    = "."
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]
  tags       = ["tf2-summon:local"]

  contexts = {
    tf2-summon-plugins = "target:plugins"
  }
}

target "image-amd64" {
  inherits   = ["docker-metadata-action"]
  context    = "."
  dockerfile = "Dockerfile"
  platforms  = ["linux/amd64"]
  tags       = ["tf2-summon:amd64-local"]

  args = {
    SRCDS_EXEC      = "srcds_run_64"
    TF2_SERVER_ARCH = "amd64"
  }

  contexts = {
    tf2-summon-plugins = "target:plugins"
  }
}
