# Single authority for the matrix, version pins and base digests.
# Dockerfiles must not carry literal versions.

variable "REGISTRY" {
  default = "docker.io/shuwariafrica"
}

variable "SBT_VERSION" {
  default = "2.0.12"
}

# Must change with SBT_VERSION; the ci pins job fails a PR where the two disagree.
variable "SBT_SHA256" {
  default = "a797e1d940260c9d6e8a0a434ff8fc3247c1b711d2cf302bae62ae243293fe55"
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
  default = "oraclelinux:10@sha256:c45341d07ee8d2397656d34e3e17306bc60c92ac4243da2ecfe8cdee8f25c01e"
}
variable "BASE_ALPINE" {
  default = "alpine:3.24@sha256:f59abe656b692d901e184be3445e084786602108599d2a51d229c0f5a48c71bf"
}
variable "BASE_ALPINE_EDGE" {
  default = "alpine:edge@sha256:020dfcbaaf4cc1078bf2d9c7ba31a8466e334061dcd2f248001d68f79e52c000"
}
variable "BASE_UBUNTU26" {
  default = "ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c"
}
variable "BASE_FEDORA" {
  default = "fedora:latest@sha256:a7d72ba2745b100a3351087472e5ee7b2450af7cf331e7673007e3817612839c"
}
variable "BASE_RAWHIDE" {
  default = "fedora:rawhide@sha256:78bb31de333664aa76c4bf54306791cd294c0bd4fbcfc4346e2286261de544c4"
}
variable "BASE_OPENSUSE" {
  default = "opensuse/tumbleweed:latest@sha256:3dbec1a6a4248919c18707d1c1d58cb0e982581c2243e11c5a08f14d0977f430"
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
