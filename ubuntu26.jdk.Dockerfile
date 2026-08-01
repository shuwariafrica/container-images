FROM ubuntu:26.04 AS base

ARG SBT_VERSION=2.0.4

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      gnupg \
 && mkdir -p /etc/apt/keyrings \
 && curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public \
      | gpg --dearmor -o /etc/apt/keyrings/adoptium.gpg \
 && printf "deb [arch=%s signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb %s main\n" \
      "$(dpkg --print-architecture)" "$(. /etc/os-release && echo "${VERSION_CODENAME}")" \
      > /etc/apt/sources.list.d/adoptium.list \
 && apt-get update \
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
      ed \
      file \
      g++ \
      gcc \
      gdb \
      git \
      graphviz \
      libgc-dev \
      libssl-dev \
      libunwind-dev \
      libuv1-dev \
      lld \
      llvm \
      make \
      openssh-client \
      pkg-config \
      libre2-dev \
      rsync \
      sudo \
      tar \
      unzip \
      xz-utils \
      zip \
      zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

# Invoked via `sh`, not executed directly: the file mode does not survive every checkout
# (a Windows-authored commit lands as 100644) and a non-executable script fails with the
# bare exit code 126.
COPY scripts/install-sbt.sh /tmp/install-sbt.sh
RUN sh /tmp/install-sbt.sh "${SBT_VERSION}" && rm -f /tmp/install-sbt.sh

RUN git config --system --add safe.directory '*'

FROM base AS final

ARG JDK_VERSION=21

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      "temurin-${JDK_VERSION}-jdk" \
 && ln -s "/usr/lib/jvm/temurin-${JDK_VERSION}-jdk-$(dpkg --print-architecture)" /opt/jdk \
 && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/opt/jdk
ENV PATH=${JAVA_HOME}/bin:/opt/sbt/bin:${PATH}

RUN { dpkg -l | sort; echo "sbt-$(cat /etc/sbt-version)"; "${JAVA_HOME}/bin/java" -version 2>&1; } > /etc/image-manifest \
 && sha256sum /etc/image-manifest | awk '{print $1}' > /etc/image-manifest.sha256

LABEL authors="Shuwari Africa Development Team"
LABEL org.opencontainers.image.description="Scala 3 / Scala Native (glibc) build environment based on Ubuntu 26.04 with Eclipse Temurin JDK"
LABEL org.opencontainers.image.source="https://github.com/shuwariafrica/container-images"
