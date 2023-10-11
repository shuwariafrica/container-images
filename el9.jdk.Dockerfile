FROM oraclelinux:9

ARG JDK_VERSION=21.0.0
ARG M2_VERSION=3.9.5
ARG NODE_VERSION=18
ARG DOTNET_VERSION=7.0

# Enable "CodeReady" Repository
RUN dnf config-manager --set-enabled ol9_codeready_builder ol9_addons

# Enable sbt Repository
RUN dnf config-manager --add-repo https://www.scala-sbt.org/sbt-rpm.repo

# Enable docker repository
RUN dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Enable the Microsoft repository
RUN rpm --import https://packages.microsoft.com/keys/microsoft.asc
RUN dnf install -y https://packages.microsoft.com/config/rhel/9.0/packages-microsoft-prod.rpm

# Update image, sbt, node and development tools
RUN dnf -y module enable nodejs:${NODE_VERSION} \
  && dnf -y upgrade \
  && dnf -y module install nodejs/development \
  && dnf -y install \
    autoconf \
    automake \
    azure-cli \
    binutils \
    bzip2 \
    clang \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin \
    dotnet-sdk-${DOTNET_VERSION} \
    ed \
    gdb \
    git \
    glibc-static \
    graphviz \
    libstdc++-static \
    libxcrypt-compat \
    llvm \
    make \
    rsync \
    sbt \
    sudo \
    unzip \
    xz \
    zip \
    zlib-static \
  && dnf clean all

# Install Graal VM / JDK
ENV JAVA_HOME=/opt/graalvm-community-openjdk-${JDK_VERSION}
RUN curl -L --retry 5 https://github.com/graalvm/graalvm-ce-builds/releases/download/jdk-${JDK_VERSION}/graalvm-community-jdk-${JDK_VERSION}_linux-x64_bin.tar.gz | tar xzf - -C /opt
RUN mv /opt/graalvm-* ${JAVA_HOME}
RUN ${JAVA_HOME}/bin/gu install native-image
# Add Graal Binaries as alternatives
RUN for ex in "${JAVA_HOME}/bin/"*; do f="$(basename "${ex}")"; [ ! -e "/usr/bin/${f}" ]; alternatives --install "/usr/bin/${f}" "${f}" "${ex}" 30000; done

# Install Maven
RUN curl -L --retry 5 https://archive.apache.org/dist/maven/maven-3/${M2_VERSION}/binaries/apache-maven-${M2_VERSION}-bin.tar.gz | tar xzf - -C /opt
RUN alternatives --install /usr/bin/mvn mvn /opt/apache-maven-${M2_VERSION}/bin/mvn 30000

LABEL "com.azure.dev.pipelines.agent.handler.node.path"="/bin/node"
LABEL authors="Shuwari Africa Development Team"
