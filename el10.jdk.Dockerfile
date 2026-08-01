FROM oraclelinux:10 AS base

ARG SBT_VERSION=2.0.4

RUN cat > /etc/yum.repos.d/adoptium.repo <<'EOF'
[Adoptium]
name=Adoptium
baseurl=https://packages.adoptium.net/artifactory/rpm/rhel/$releasever/$basearch
enabled=1
gpgcheck=1
gpgkey=https://packages.adoptium.net/artifactory/api/gpg/key/public
EOF

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

COPY scripts/install-sbt.sh /tmp/install-sbt.sh
RUN /tmp/install-sbt.sh "${SBT_VERSION}" && rm -f /tmp/install-sbt.sh

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
LABEL org.opencontainers.image.description="Scala 3 / Scala Native (glibc) build environment based on Oracle Linux 10 with Eclipse Temurin JDK"
LABEL org.opencontainers.image.source="https://github.com/shuwariafrica/container-images"
