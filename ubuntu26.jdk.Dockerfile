FROM ubuntu:26.04 AS base


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

# sbt's Debian repository is a single arch-independent package (suite `all`), and it
# resolves each project's own version, so it tracks the repository rather than a pin.
#
# The key is fetched from repo.scala-sbt.org rather than keyserver.ubuntu.com, which sbt's
# instructions use: both serve identical material, but the keyserver is an extra host that
# can fail, and it has. The fingerprint is verified before use, which is what makes the
# source irrelevant to trust.
ARG SBT_KEY_FPR=2EE0EA64E40A89B84B2DF73499E82A75642AC823
RUN curl -fsSL --retry 5 \
      https://repo.scala-sbt.org/scalasbt/rpm/repodata/repomd.xml.key -o /tmp/sbt.key \
 && got="$(gpg --show-keys --with-colons /tmp/sbt.key | awk -F: '/^fpr:/ {print $10; exit}')" \
 && { [ "${got}" = "${SBT_KEY_FPR}" ] \
      || { echo "sbt repo key fingerprint mismatch: got ${got:-<none>}" >&2; exit 1; }; } \
 && gpg --dearmor -o /etc/apt/keyrings/scalasbt.gpg /tmp/sbt.key \
 && rm -f /tmp/sbt.key \
 && echo "deb [signed-by=/etc/apt/keyrings/scalasbt.gpg] https://repo.scala-sbt.org/scalasbt/debian all main" \
      > /etc/apt/sources.list.d/sbt.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends sbt \
 && rm -rf /var/lib/apt/lists/*

RUN git config --system --add safe.directory '*'

FROM base AS final

ARG JDK_VERSION=21

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      "temurin-${JDK_VERSION}-jdk" \
 && ln -s "/usr/lib/jvm/temurin-${JDK_VERSION}-jdk-$(dpkg --print-architecture)" /opt/jdk \
 && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/opt/jdk
ENV PATH=${JAVA_HOME}/bin:${PATH}

RUN { dpkg -l | sort; "${JAVA_HOME}/bin/java" -version 2>&1; } > /etc/image-manifest \
 && sha256sum /etc/image-manifest | awk '{print $1}' > /etc/image-manifest.sha256

LABEL authors="Shuwari Africa Development Team"
LABEL org.opencontainers.image.description="Scala 3 / Scala Native (glibc) build environment based on Ubuntu 26.04 with Eclipse Temurin JDK"
LABEL org.opencontainers.image.source="https://github.com/shuwariafrica/container-images"
