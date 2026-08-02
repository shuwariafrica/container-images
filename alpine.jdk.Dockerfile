# No ARG defaults: a bare `docker build` must fail rather than silently build an
# unpinned base. docker-bake.hcl supplies every value.
# Builds both the alpine and alpine-edge families; only BASE_IMAGE differs.
ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS base

ARG SBT_VERSION
ARG SBT_SHA256
ARG SBT_BASE_URL

RUN apk upgrade --no-cache \
 && apk add --no-cache \
      autoconf \
      automake \
      bash \
      binutils \
      bzip2 \
      ca-certificates \
      clang \
      clang-extra-tools \
      cmake \
      coreutils \
      curl \
      ed \
      file \
      g++ \
      gc-dev \
      gcc \
      gcompat \
      gdb \
      git \
      gnupg \
      graphviz \
      libc-dev \
      libtool \
      libunwind-dev \
      libunwind-static \
      libuv-dev \
      libuv-static \
      linux-headers \
      lld \
      make \
      musl-dev \
      ncurses \
      openssh-client \
      openssl-dev \
      openssl-libs-static \
      pkgconfig \
      re2-dev \
      rsync \
      sudo \
      tar \
      unzip \
      xz \
      zip \
      zlib-dev \
      zlib-static

# Invoked via `sh`: the executable bit does not survive a Windows-authored checkout,
# and a non-executable script fails with the bare exit code 126.
COPY scripts/install-sbt.sh /tmp/install-sbt.sh
RUN sh /tmp/install-sbt.sh "${SBT_VERSION}" "${SBT_SHA256}" "${SBT_BASE_URL}" && rm -f /tmp/install-sbt.sh

FROM base AS final

ARG JDK_VERSION

# default-jvm resolves to the only JDK installed here; a second would silently
# repoint /opt/jdk.
RUN apk add --no-cache openjdk${JDK_VERSION}-jdk \
 && ln -s /usr/lib/jvm/default-jvm /opt/jdk

ENV JAVA_HOME=/opt/jdk
ENV PATH=$JAVA_HOME/bin:/opt/sbt/bin:$PATH

RUN { apk info -vv | sort; echo "sbt-$(cat /etc/sbt-version)"; } > /etc/image-manifest \
 && sha256sum /etc/image-manifest | awk '{print $1}' > /etc/image-manifest.sha256

LABEL authors="Shuwari Africa Development Team"
LABEL org.opencontainers.image.description="Scala 3 / Scala Native (musl) build environment based on Alpine Linux"
LABEL org.opencontainers.image.source="https://github.com/shuwariafrica/container-images"
