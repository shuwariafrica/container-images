FROM fedora:rawhide AS base

ARG SBT_VERSION=1.12.11

RUN cat > /etc/yum.repos.d/adoptium.repo <<'EOF'
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/fedora/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF

RUN dnf -y upgrade \
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
      gc-devel \
      gcc \
      gcc-c++ \
      gdb \
      git \
      graphviz \
      libstdc++-devel \
      libunwind-devel \
      libuv-devel \
      lld \
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
 && dnf clean all \
 && rm -rf /var/cache/dnf/* /tmp/*

RUN curl -fL --retry 5 "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" \
      | tar xzf - -C /opt \
 && ln -s /opt/sbt/bin/sbt  /usr/local/bin/sbt \
 && ln -s /opt/sbt/bin/sbtn /usr/local/bin/sbtn \
 && echo "${SBT_VERSION}" > /etc/sbt-version

RUN git config --system --add safe.directory '*'

FROM base AS final

ARG JDK_VERSION=21

RUN dnf -y install "temurin-${JDK_VERSION}-jdk" \
 && ln -s "/usr/lib/jvm/java-${JDK_VERSION}-temurin-jdk" /opt/jdk \
 && dnf clean all \
 && rm -rf /var/cache/dnf/* /tmp/*

ENV JAVA_HOME=/opt/jdk
ENV PATH=${JAVA_HOME}/bin:/opt/sbt/bin:${PATH}

RUN { rpm -qa | sort; echo "sbt-$(cat /etc/sbt-version)"; "${JAVA_HOME}/bin/java" -version 2>&1; } > /etc/image-manifest \
 && sha256sum /etc/image-manifest | awk '{print $1}' > /etc/image-manifest.sha256

LABEL authors="Shuwari Africa Development Team"
LABEL org.opencontainers.image.description="Scala 3 / Scala Native (glibc) build environment based on Fedora Linux (Rawhide) with Eclipse Temurin JDK"
LABEL org.opencontainers.image.source="https://github.com/shuwariafrica/container-images"
