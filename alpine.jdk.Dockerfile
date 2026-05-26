ARG ALPINE_VERSION=3.23

FROM alpine:${ALPINE_VERSION} AS base

ARG SBT_VERSION=1.12.11

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
      g++ \
      gc-dev \
      gcc \
      gcompat \
      gdb \
      git \
      gnupg \
      graphviz \
      libc-dev \
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

RUN curl -fL --retry 5 "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" \
      | tar xzf - -C /opt \
 && ln -s /opt/sbt/bin/sbt  /usr/local/bin/sbt \
 && ln -s /opt/sbt/bin/sbtn /usr/local/bin/sbtn \
 && echo "${SBT_VERSION}" > /etc/sbt-version

RUN git config --system --add safe.directory '*'

FROM base AS final

ARG JDK_VERSION=21

RUN apk add --no-cache openjdk${JDK_VERSION}-jdk

ENV JAVA_HOME=/usr/lib/jvm/default-jvm
ENV PATH=$JAVA_HOME/bin:/opt/sbt/bin:$PATH

RUN { apk info -vv | sort; echo "sbt-$(cat /etc/sbt-version)"; } > /etc/image-manifest \
 && sha256sum /etc/image-manifest | awk '{print $1}' > /etc/image-manifest.sha256

LABEL authors="Shuwari Africa Development Team"
LABEL org.opencontainers.image.description="Scala 3 / Scala Native (musl) build environment based on Alpine Linux"
LABEL org.opencontainers.image.source="https://github.com/shuwariafrica/container-images"
