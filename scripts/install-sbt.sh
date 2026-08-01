#!/bin/sh
# Install the sbt launcher from the official release tarball.
#
# Tarball rather than sbt's rpm/deb repositories: those need per-distribution key handling
# and do not behave alike. `rpm --import` of the sbt key fails outright on EL10, whose
# Sequoia backend rejects the key's binding signature, and the published sbt-rpm.repo sets
# gpgcheck and repo_gpgcheck to 0 so it cannot simply be imported either. One tarball works
# on every base.
#
# sbt is a launcher: it reads project/build.properties and fetches the version each project
# declares, so SBT_VERSION only sets what runs with no project context.
#
# POSIX sh, no bashisms: this also runs under busybox on Alpine.
set -eu

VERSION="${1:?usage: install-sbt.sh <version>}"

curl -fL --retry 5 \
    "https://github.com/sbt/sbt/releases/download/v${VERSION}/sbt-${VERSION}.tgz" \
  | tar xzf - -C /opt

ln -sf /opt/sbt/bin/sbt  /usr/local/bin/sbt
ln -sf /opt/sbt/bin/sbtn /usr/local/bin/sbtn
echo "${VERSION}" > /etc/sbt-version

# Fail here rather than ship an image with a silently mislaid launcher. Not `sbt
# --script-version`: this runs in the base stage, which has no JDK yet.
[ -x /opt/sbt/bin/sbt ] || { echo "sbt missing after extraction" >&2; exit 1; }
