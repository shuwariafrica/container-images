#!/bin/sh
set -eu

VERSION="${1:?usage: install-sbt.sh <version> <sha256> [base-url]}"
SHA256="${2:?usage: install-sbt.sh <version> <sha256> [base-url] - refusing to install unverified}"
# Mirror override. The checksum below is unconditional, so a substituted origin cannot
# weaken verification.
BASE_URL="${3:-}"
: "${BASE_URL:=https://github.com/sbt/sbt/releases/download}"

TARBALL="/tmp/sbt-${VERSION}.tgz"
# --retry-all-errors: GitHub release CDN intermittently resets HTTP/2 streams
# (curl exit 92), which plain --retry does not treat as retryable.
curl -fL --retry 5 --retry-all-errors -o "${TARBALL}" \
    "${BASE_URL}/v${VERSION}/sbt-${VERSION}.tgz"
echo "${SHA256}  ${TARBALL}" | sha256sum -c - >/dev/null
tar xzf "${TARBALL}" -C /opt
rm -f "${TARBALL}"

ln -sf /opt/sbt/bin/sbt  /usr/local/bin/sbt
ln -sf /opt/sbt/bin/sbtn /usr/local/bin/sbtn
echo "${VERSION}" > /etc/sbt-version

# Not `sbt --script-version`: this stage has no JDK yet.
[ -x /opt/sbt/bin/sbt ] || { echo "sbt missing after extraction" >&2; exit 1; }
