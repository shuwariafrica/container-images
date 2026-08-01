ARG OPENSUSE_VERSION=latest

FROM opensuse/tumbleweed:${OPENSUSE_VERSION} AS base

ARG SBT_VERSION=2.0.4

# Adoptium publishes no Tumbleweed repository (its opensuse/ tree is Leap 15.1-15.5 only),
# so the JDK is distro-native.
#
# ZYPP_PCK_PRELOAD=0: libzypp's parallel commit download waits indefinitely when the origin
# cancels a stream, as transfer_timeout is not enforced on that path. Per-RUN, not ENV, to
# keep it out of the published image.
#
# The stock baseurls resolve through MirrorBrain, which assigns a mirror per file and
# stably, so a dead mirror fails the same file on every retry. downloadcontent serves every
# file itself. Verify any replacement by fetching a package, not repodata.
RUN set -eu \
 && export ZYPP_PCK_PRELOAD=0 \
 && zypper --non-interactive removerepo repo-openh264 \
 && sed -i 's|http://download\.opensuse\.org|https://downloadcontent.opensuse.org|g' \
        /etc/zypp/repos.d/*.repo \
 && grep -q 'downloadcontent\.opensuse\.org' /etc/zypp/repos.d/repo-oss.repo \
 && zypper --non-interactive refresh \
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
 && zypper clean --all \
 && rm -rf /var/cache/zypp/* /tmp/*

# Invoked via `sh`, not executed directly: the file mode does not survive every checkout
# (a Windows-authored commit lands as 100644) and a non-executable script fails with the
# bare exit code 126.
COPY scripts/install-sbt.sh /tmp/install-sbt.sh
RUN sh /tmp/install-sbt.sh "${SBT_VERSION}" && rm -f /tmp/install-sbt.sh

RUN git config --system --add safe.directory '*'

FROM base AS final

ARG JDK_VERSION=21

# openSUSE installs JVMs under /usr/lib64/jvm. A miss is fatal rather than leaving /opt/jdk
# dangling.
RUN export ZYPP_PCK_PRELOAD=0 \
 && zypper --non-interactive install --no-recommends "java-${JDK_VERSION}-openjdk-devel" \
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
