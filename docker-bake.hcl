# Single authority for the matrix, version pins and base digests.
# Dockerfiles must not carry literal versions.

variable "REGISTRY" {
  default = "docker.io/shuwariafrica"
}

variable "SBT_VERSION" {
  default = "2.0.4"
}

# Must change with SBT_VERSION; the ci pins job fails a PR where the two disagree.
variable "SBT_SHA256" {
  default = "13253ee7a8b19f60f8c6dc100249619df19ed8869f8be783ab8d206aedfdc366"
}

# Mirror override; SBT_SHA256 is verified whatever the origin.
variable "SBT_BASE_URL" {
  default = "https://github.com/sbt/sbt/releases/download"
}

# The docker exporter cannot carry attestations, so the pull-request path sets
# ATTEST=false. `--set '*.attest='` does NOT clear the list — it survives the override.
variable "ATTEST" {
  default = "true"
}

# The digest builds; the tag is informational. Tracked by .github/renovate.json.
variable "BASE_EL10" {
  default = "oraclelinux:10@sha256:07875b8c89e5afe1d15ea77553eb5910234b4afca44d31eb9391e5e1d93d38cc"
}
variable "BASE_ALPINE" {
  default = "alpine:3.23@sha256:fd791d74b68913cbb027c6546007b3f0d3bc45125f797758156952bc2d6daf40"
}
variable "BASE_ALPINE_EDGE" {
  default = "alpine:edge@sha256:9a341ff2287c54b86425cbee0141114d811ae69d88a36019087be6d896cef241"
}
variable "BASE_UBUNTU26" {
  default = "ubuntu:26.04@sha256:3131b4cc82a783df6c9df078f86e01819a13594b865c2cad47bd1bca2b7063bb"
}
variable "BASE_FEDORA" {
  default = "fedora:latest@sha256:6c75d5bf57cb0fa5aa4b92c6a83c86c791644496d9ac230de7711f5b8ec3b898"
}
variable "BASE_RAWHIDE" {
  default = "fedora:rawhide@sha256:0c1f63ed8fb818fad16cf6ae091598c410a21d2e1a9adf183beb93189299bfba"
}
variable "BASE_OPENSUSE" {
  default = "opensuse/tumbleweed:latest@sha256:35057fc7ef857a1411c44e6e7ecefd7e60cbec689ab9ca3a4ef4f3257ab4b8e5"
}

# The support matrix. CI derives its build matrix from `bake --print`, so a cell absent
# here is never built and never published.
#
# 21 and 25 only, matching the Scala CI's JDK_RELEASE and JDK_CURRENT. A distribution
# shipping 17 does not earn it a cell.
#
# Establish a cell by installing the distribution's JDK package in that base, not by
# listing it: a listing reflects what the repositories advertise, not what resolves.
jdks_el10        = ["21", "25"]
jdks_alpine      = ["21", "25"]
jdks_alpine_edge = ["21", "25"]
jdks_ubuntu26    = ["21", "25"]
jdks_fedora      = ["25"]
jdks_rawhide     = ["25"]
jdks_opensuse    = ["21", "25"]

target "_common" {
  platforms = ["linux/amd64", "linux/arm64"]
  attest = ATTEST == "true" ? [
    "type=provenance,mode=max",
    "type=sbom",
  ] : []
  args = {
    SBT_VERSION  = SBT_VERSION
    SBT_SHA256   = SBT_SHA256
    SBT_BASE_URL = SBT_BASE_URL
  }
}

target "el10" {
  matrix     = { jdk = jdks_el10 }
  name       = "el10-jdk${jdk}"
  inherits   = ["_common"]
  dockerfile = "el10.jdk.Dockerfile"
  args       = { BASE_IMAGE = BASE_EL10, JDK_VERSION = jdk }
  tags       = ["${REGISTRY}/el10-jdk:${jdk}"]
}

target "alpine" {
  matrix     = { jdk = jdks_alpine }
  name       = "alpine-jdk${jdk}"
  inherits   = ["_common"]
  dockerfile = "alpine.jdk.Dockerfile"
  args       = { BASE_IMAGE = BASE_ALPINE, JDK_VERSION = jdk }
  tags       = ["${REGISTRY}/alpine-jdk:${jdk}"]
}

target "alpine-edge" {
  matrix     = { jdk = jdks_alpine_edge }
  name       = "alpine-edge-jdk${jdk}"
  inherits   = ["_common"]
  dockerfile = "alpine.jdk.Dockerfile"
  args       = { BASE_IMAGE = BASE_ALPINE_EDGE, JDK_VERSION = jdk }
  tags       = ["${REGISTRY}/alpine-edge-jdk:${jdk}"]
}

target "ubuntu26" {
  matrix     = { jdk = jdks_ubuntu26 }
  name       = "ubuntu26-jdk${jdk}"
  inherits   = ["_common"]
  dockerfile = "ubuntu26.jdk.Dockerfile"
  args       = { BASE_IMAGE = BASE_UBUNTU26, JDK_VERSION = jdk }
  tags       = ["${REGISTRY}/ubuntu26-jdk:${jdk}"]
}

target "fedora" {
  matrix     = { jdk = jdks_fedora }
  name       = "fedora-jdk${jdk}"
  inherits   = ["_common"]
  dockerfile = "fedora.jdk.Dockerfile"
  args       = { BASE_IMAGE = BASE_FEDORA, JDK_VERSION = jdk }
  tags       = ["${REGISTRY}/fedora-jdk:${jdk}"]
}

target "rawhide" {
  matrix     = { jdk = jdks_rawhide }
  name       = "rawhide-jdk${jdk}"
  inherits   = ["_common"]
  dockerfile = "fedora.jdk.Dockerfile"
  args       = { BASE_IMAGE = BASE_RAWHIDE, JDK_VERSION = jdk }
  tags       = ["${REGISTRY}/rawhide-jdk:${jdk}"]
}

target "opensuse" {
  matrix     = { jdk = jdks_opensuse }
  name       = "opensuse-jdk${jdk}"
  inherits   = ["_common"]
  dockerfile = "opensuse.jdk.Dockerfile"
  args       = { BASE_IMAGE = BASE_OPENSUSE, JDK_VERSION = jdk }
  tags       = ["${REGISTRY}/opensuse-jdk:${jdk}"]
}

group "default" {
  targets = ["el10", "alpine", "alpine-edge", "ubuntu26", "fedora", "rawhide", "opensuse"]
}
