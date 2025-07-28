# Build arguments (global)
ARG CMAKE_VERSION=3.31.8
ARG ANDROID_CMDLINE_TOOLS_VERSION=13114758
ARG ANDROID_NDK_VERSION=27.2.12479018
ARG ANDROID_API_LEVEL=34
ARG ANDROID_BUILD_TOOLS_VERSION=34.0.0
ARG KOTLIN_LSP_VERSION=0.252.17811
ARG GRADLE_VERSION=8.10.2

# ----------------------------------------------------------------------------
# Stage 1: Minimal base OS
# ----------------------------------------------------------------------------
FROM ubuntu:22.04 AS base-os
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    ca-certificates curl unzip tar gnupg && \
    rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Stage 2: CMake (cached independently)
# ----------------------------------------------------------------------------
FROM base-os AS cmake
ARG CMAKE_VERSION
RUN mkdir -p /opt/cmake && \
    curl -fsSL -o /tmp/cmake.tar.gz \
      https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz && \
    tar --strip-components=1 -xzf /tmp/cmake.tar.gz -C /opt/cmake && \
    rm /tmp/cmake.tar.gz

# ----------------------------------------------------------------------------
# Stage 3: Gradle (cached independently)
# ----------------------------------------------------------------------------
FROM base-os AS gradle
ARG GRADLE_VERSION
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/* && \
    curl -fsSL -o /tmp/gradle.zip \
      https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    unzip /tmp/gradle.zip -d /opt && \
    mv /opt/gradle-${GRADLE_VERSION} /opt/gradle && \
    ln -s /opt/gradle/bin/gradle /usr/local/bin/gradle && \
    rm /tmp/gradle.zip

# ----------------------------------------------------------------------------
# Stage 4: Java runtime (cached independently)
# ----------------------------------------------------------------------------
FROM base-os AS java-base
RUN apt-get update && apt-get install -y openjdk-17-jdk-headless && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------------------------------
# Stage 5: Toolchain (git, ninja, ccache, Kotlin LSP)
# ----------------------------------------------------------------------------
FROM java-base AS tools
ARG KOTLIN_LSP_VERSION
ENV CODE_EXTENSIONS_DIR=/usr/local/share/vscode-extensions \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    PATH=$PATH:$JAVA_HOME/bin
RUN apt-get update && apt-get install -y \
    git git-lfs ninja-build ccache build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*
# RUN mkdir -p ${CODE_EXTENSIONS_DIR} && \
#     curl -fsSL -o ${CODE_EXTENSIONS_DIR}/kotlin.vsix \
#       https://download-cdn.jetbrains.com/kotlin-lsp/${KOTLIN_LSP_VERSION}/kotlin-${KOTLIN_LSP_VERSION}.vsix

# ----------------------------------------------------------------------------
# Stage 6: Android SDK & NDK (cached independently)
# ----------------------------------------------------------------------------
FROM java-base AS android-sdk
ARG ANDROID_CMDLINE_TOOLS_VERSION
ARG ANDROID_NDK_VERSION
ARG ANDROID_API_LEVEL
ARG ANDROID_BUILD_TOOLS_VERSION
ENV PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:/opt/android-sdk/build-tools/${ANDROID_BUILD_TOOLS_VERSION}:$PATH
RUN apt-get update && apt-get install -y unzip && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /opt/android-sdk/cmdline-tools && \
    curl -fsSL -o /tmp/cmdline-tools.zip \
      https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_CMDLINE_TOOLS_VERSION}_latest.zip && \
    unzip /tmp/cmdline-tools.zip -d /opt/android-sdk/cmdline-tools && \
    mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip && \
    yes | sdkmanager --sdk_root=/opt/android-sdk --licenses && \
    sdkmanager --sdk_root=/opt/android-sdk \
      "platform-tools" \
      "platforms;android-${ANDROID_API_LEVEL}" \
      "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
      "ndk;${ANDROID_NDK_VERSION}" \
      "cmake;3.22.1" \
      "emulator" \
      "system-images;android-${ANDROID_API_LEVEL};google_apis;x86_64" && \
    avdmanager create avd --name default --device "Galaxy Nexus" \
      --package "system-images;android-${ANDROID_API_LEVEL};google_apis;x86_64" --force

# ----------------------------------------------------------------------------
# Stage 7: Final development image
# ----------------------------------------------------------------------------
FROM tools AS final
# Copy only isolated tool directories
COPY --from=cmake /opt/cmake /opt/cmake
COPY --from=gradle /opt/gradle /opt/gradle
COPY --from=gradle /usr/local/bin/gradle /usr/local/bin/gradle
COPY --from=android-sdk /opt/android-sdk /opt/android-sdk


# Declare ARGs for final interpolation
ARG ANDROID_NDK_VERSION
ARG ANDROID_BUILD_TOOLS_VERSION

# Set environment variables
ENV CMAKE_HOME=/opt/cmake
ENV GRADLE_HOME=/opt/gradle
ENV ANDROID_HOME=/opt/android-sdk
ENV ANDROID_NDK_HOME=${ANDROID_HOME}/ndk/${ANDROID_NDK_VERSION}
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
# Define PATH with previously declared envs
ENV PATH=$PATH:$CMAKE_HOME/bin:$GRADLE_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/${ANDROID_BUILD_TOOLS_VERSION}:$ANDROID_NDK_HOME:$JAVA_HOME/bin

# Copy entrypoint and healthcheck scripts
COPY resources/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY resources/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/healthcheck.sh

# Healthcheck using dedicated script
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s CMD ["/usr/local/bin/healthcheck.sh"]

# Create non-root user
USER root
RUN useradd -m -s /bin/bash vscode && \
    usermod -aG sudo vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

    --chown=vscode:vscode

USER vscode
WORKDIR /home/vscode
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
