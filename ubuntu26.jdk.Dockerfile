# No ARG defaults: a bare `docker build` must fail rather than silently build an
# unpinned base. docker-bake.hcl supplies every value.
ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS base

ARG SBT_VERSION
ARG SBT_SHA256
ARG SBT_BASE_URL

# libtool-bin as well as libtool: Debian's libtool ships libtoolize and the m4 macros
# but not /usr/bin/libtool, which every other family gets from its libtool package.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      autoconf \
      automake \
      binutils \
      bzip2 \
      ca-certificates \
      clang \
      clang-format \
      clang-tidy \
      clangd \
      cmake \
      coreutils \
      curl \
      ed \
      file \
      g++ \
      gcc \
      gdb \
      git \
      gnupg \
      graphviz \
      libgc-dev \
      libre2-dev \
      libssl-dev \
      libtool \
      libtool-bin \
      libunwind-dev \
      libuv1-dev \
      lld \
      llvm \
      make \
      openssh-client \
      pkg-config \
      rsync \
      sudo \
      tar \
      unzip \
      xz-utils \
      zip \
      zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

# Invoked via `sh`: the executable bit does not survive a Windows-authored checkout,
# and a non-executable script fails with the bare exit code 126.
COPY scripts/install-sbt.sh /tmp/install-sbt.sh
RUN sh /tmp/install-sbt.sh "${SBT_VERSION}" "${SBT_SHA256}" "${SBT_BASE_URL}" && rm -f /tmp/install-sbt.sh

FROM base AS final

ARG JDK_VERSION

# The JVM directory carries the dpkg architecture suffix, so it differs between the
# amd64 and arm64 builds of the same tag.
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      "openjdk-${JDK_VERSION}-jdk" \
 && ln -s "/usr/lib/jvm/java-${JDK_VERSION}-openjdk-$(dpkg --print-architecture)" /opt/jdk \
 && [ -x /opt/jdk/bin/javac ] \
 && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/opt/jdk
ENV PATH=${JAVA_HOME}/bin:/opt/sbt/bin:${PATH}

RUN { dpkg -l | sort; echo "sbt-$(cat /etc/sbt-version)"; "${JAVA_HOME}/bin/java" -version 2>&1; } > /etc/image-manifest \
 && sha256sum /etc/image-manifest | awk '{print $1}' > /etc/image-manifest.sha256

LABEL authors="Shuwari Africa Development Team"
LABEL org.opencontainers.image.description="Scala 3 / Scala Native (glibc) build environment based on Ubuntu 26.04 with the distribution's OpenJDK"
LABEL org.opencontainers.image.source="https://github.com/shuwariafrica/container-images"
