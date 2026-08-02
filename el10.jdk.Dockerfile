# No ARG defaults: a bare `docker build` must fail rather than silently build an
# unpinned base. docker-bake.hcl supplies every value.
ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS base

ARG SBT_VERSION
ARG SBT_SHA256
ARG SBT_BASE_URL

RUN dnf -y install dnf-plugins-core oracle-epel-release-el10 \
 && dnf config-manager --set-enabled ol10_codeready_builder \
 && dnf -y upgrade \
 && dnf -y install \
      autoconf \
      automake \
      binutils \
      bzip2 \
      ca-certificates \
      clang \
      clang-tools-extra \
      cmake \
      curl \
      ed \
      file \
      gc-devel \
      gcc \
      gcc-c++ \
      gdb \
      gnupg2 \
      git \
      graphviz \
      libstdc++-devel \
      libtool \
      libunwind-devel \
      libuv-devel \
      lld \
      llvm-toolset \
      make \
      openssl-devel \
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
 && dnf clean all \
 && rm -rf /var/cache/dnf/* /tmp/*

# Invoked via `sh`: the executable bit does not survive a Windows-authored checkout,
# and a non-executable script fails with the bare exit code 126.
COPY scripts/install-sbt.sh /tmp/install-sbt.sh
RUN sh /tmp/install-sbt.sh "${SBT_VERSION}" "${SBT_SHA256}" "${SBT_BASE_URL}" && rm -f /tmp/install-sbt.sh

FROM base AS final

ARG JDK_VERSION

# Link the unversioned symlink, not the java-<major>-openjdk-<full-version> directory
# it points at: only the former survives a patch release.
RUN dnf -y install "java-${JDK_VERSION}-openjdk-devel" \
 && ln -s "/usr/lib/jvm/java-${JDK_VERSION}-openjdk" /opt/jdk \
 && [ -x /opt/jdk/bin/javac ] \
 && dnf clean all \
 && rm -rf /var/cache/dnf/* /tmp/*

ENV JAVA_HOME=/opt/jdk
ENV PATH=${JAVA_HOME}/bin:/opt/sbt/bin:${PATH}

RUN { rpm -qa | sort; echo "sbt-$(cat /etc/sbt-version)"; "${JAVA_HOME}/bin/java" -version 2>&1; } > /etc/image-manifest \
 && sha256sum /etc/image-manifest | awk '{print $1}' > /etc/image-manifest.sha256

LABEL authors="Shuwari Africa Development Team"
LABEL org.opencontainers.image.description="Scala 3 / Scala Native (glibc) build environment based on Oracle Linux 10 with the distribution's OpenJDK"
LABEL org.opencontainers.image.source="https://github.com/shuwariafrica/container-images"
