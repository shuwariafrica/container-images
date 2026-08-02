# No ARG defaults: a bare `docker build` must fail rather than silently build an
# unpinned base. docker-bake.hcl supplies every value.
ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS base

ARG SBT_VERSION
ARG SBT_SHA256
ARG SBT_BASE_URL

# ZYPP_PCK_PRELOAD=0: libzypp's parallel commit download waits indefinitely when the origin
# cancels a stream, as transfer_timeout is not enforced on that path. Per-RUN, not ENV, to
# keep it out of the published image.
#
# The stock baseurls resolve through MirrorBrain, which assigns a mirror per file and
# stably, so a dead mirror fails the same file on every retry. downloadcontent serves every
# file itself. Verify any replacement by fetching a package, not repodata.
#
# The retry is not optional: one HTTP/2 stream reset (curl 92) mid-package aborts the
# entire transaction, and --non-interactive answers that prompt with "abort". Observed
# on a 32MB libLLVM download.
RUN set -eu \
 && export ZYPP_PCK_PRELOAD=0 \
 && zypper --non-interactive removerepo repo-openh264 \
 && sed -i 's|http://download\.opensuse\.org|https://downloadcontent.opensuse.org|g' \
        /etc/zypp/repos.d/*.repo \
 && grep -q 'downloadcontent\.opensuse\.org' /etc/zypp/repos.d/repo-oss.repo \
 && for attempt in 1 2 3 4 5; do \
      zypper --non-interactive refresh \
        && zypper --non-interactive dup \
        && zypper --non-interactive install --no-recommends \
      autoconf \
      automake \
      binutils \
      bzip2 \
      ca-certificates \
      clang \
      clang-tools \
      cmake \
      curl \
      ed \
      file \
      gawk \
      gc-devel \
      gcc \
      gcc-c++ \
      gdb \
      git \
      gpg2 \
      graphviz \
      libopenssl-devel \
      libstdc++-devel \
      libtool \
      libunwind-devel \
      libuv-devel \
      lld \
      llvm \
      make \
      openssh-clients \
      pkgconf-pkg-config \
      re2-devel \
      rsync \
      sudo \
      tar \
      unzip \
      which \
      xz \
      zip \
      zlib-devel \
        && break; \
      [ "${attempt}" = 5 ] && { echo "zypper aborted on 5 attempts" >&2; exit 1; }; \
      zypper --non-interactive clean --all || true; \
    done \
 && zypper clean --all \
 && rm -rf /var/cache/zypp/* /tmp/*

# Invoked via `sh`: the executable bit does not survive a Windows-authored checkout,
# and a non-executable script fails with the bare exit code 126.
COPY scripts/install-sbt.sh /tmp/install-sbt.sh
RUN sh /tmp/install-sbt.sh "${SBT_VERSION}" "${SBT_SHA256}" "${SBT_BASE_URL}" && rm -f /tmp/install-sbt.sh

FROM base AS final

ARG JDK_VERSION

# Retried for the same reason as the toolchain transaction above.
# Fail on a miss rather than leave /opt/jdk dangling.
RUN set -eu \
 && export ZYPP_PCK_PRELOAD=0 \
 && for attempt in 1 2 3 4 5; do \
      zypper --non-interactive install --no-recommends "java-${JDK_VERSION}-openjdk-devel" \
        && break; \
      [ "${attempt}" = 5 ] && { echo "zypper aborted on 5 attempts" >&2; exit 1; }; \
      zypper --non-interactive clean --all || true; \
    done \
 && jdk_dir="$(ls -d "/usr/lib64/jvm/java-${JDK_VERSION}-openjdk" \
                     "/usr/lib/jvm/java-${JDK_VERSION}-openjdk" 2>/dev/null | head -1)" \
 && [ -n "${jdk_dir}" ] || { echo "no JVM directory for major ${JDK_VERSION}" >&2; exit 1; } \
 && ln -s "${jdk_dir}" /opt/jdk \
 && zypper clean --all \
 && rm -rf /var/cache/zypp/* /tmp/*

ENV JAVA_HOME=/opt/jdk
ENV PATH=${JAVA_HOME}/bin:/opt/sbt/bin:${PATH}

RUN { rpm -qa | sort; echo "sbt-$(cat /etc/sbt-version)"; "${JAVA_HOME}/bin/java" -version 2>&1; } > /etc/image-manifest \
 && sha256sum /etc/image-manifest | awk '{print $1}' > /etc/image-manifest.sha256

LABEL authors="Shuwari Africa Development Team"
LABEL org.opencontainers.image.description="Scala 3 / Scala Native (glibc) build environment based on openSUSE Tumbleweed with the distribution's OpenJDK"
LABEL org.opencontainers.image.source="https://github.com/shuwariafrica/container-images"
