FROM oraclelinux:10 AS base

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

# sbt is noarch and requires only /bin/sh, /usr/bin/env and coreutils, so it pulls no JVM
# into this stage. It resolves each project's own version, so it tracks the repository
# rather than a pin.
#
# Packages are unsigned upstream, so gpgcheck cannot be enabled; repomd.xml.asc is signed
# and the metadata carries package checksums, so repo_gpgcheck can. The published
# sbt-rpm.repo sets both to 0, hence writing it out rather than `config-manager
# --add-repo`. gpgkey= is required as well, because dnf does not consult the rpm keyring
# for repo_gpgcheck.
ARG SBT_RPM_KEY_FPR=2EE0EA64E40A89B84B2DF73499E82A75642AC823
RUN curl -fsSL https://repo.scala-sbt.org/scalasbt/rpm/repodata/repomd.xml.key -o /tmp/sbt.key \
 && got="$(gpg --show-keys --with-colons /tmp/sbt.key | awk -F: '/^fpr:/ {print $10; exit}')" \
 && { [ "${got}" = "${SBT_RPM_KEY_FPR}" ] \
      || { echo "sbt repo key fingerprint mismatch: got ${got:-<none>}" >&2; exit 1; }; } \
 && install -D -m 0644 /tmp/sbt.key /etc/pki/rpm-gpg/RPM-GPG-KEY-sbt \
 && rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-sbt \
 && rm -f /tmp/sbt.key \
 && printf '%s\n' \
      '[sbt-rpm]' \
      'name=sbt-rpm' \
      'baseurl=https://repo.scala-sbt.org/scalasbt/rpm' \
      'enabled=1' \
      'gpgcheck=0' \
      'repo_gpgcheck=1' \
      'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-sbt' > /etc/yum.repos.d/sbt-rpm.repo \
 && dnf -y install sbt \
 && dnf clean all \
 && rm -rf /var/cache/dnf/*

RUN git config --system --add safe.directory '*'

FROM base AS final

ARG JDK_VERSION=21

RUN dnf -y install "temurin-${JDK_VERSION}-jdk" \
 && ln -s "/usr/lib/jvm/java-${JDK_VERSION}-temurin-jdk" /opt/jdk \
 && dnf clean all \
 && rm -rf /var/cache/dnf/* /tmp/*

ENV JAVA_HOME=/opt/jdk
ENV PATH=${JAVA_HOME}/bin:${PATH}

RUN { rpm -qa | sort; "${JAVA_HOME}/bin/java" -version 2>&1; } > /etc/image-manifest \
 && sha256sum /etc/image-manifest | awk '{print $1}' > /etc/image-manifest.sha256

LABEL authors="Shuwari Africa Development Team"
LABEL org.opencontainers.image.description="Scala 3 / Scala Native (glibc) build environment based on Oracle Linux 10 with Eclipse Temurin JDK"
LABEL org.opencontainers.image.source="https://github.com/shuwariafrica/container-images"
