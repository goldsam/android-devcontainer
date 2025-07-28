# CMake stage
FROM base-image
ARG CMAKE_VERSION=3.31.8

# Use cache mount and check if cmake is already installed
RUN --mount=type=cache,target=/var/cache/cmake \
    if [ ! -f /var/cache/cmake/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz ]; then \
        curl -fsSL -o /var/cache/cmake/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz \
            https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz; \
    fi && \
    mkdir -p /opt/cmake && \
    tar --strip-components=1 -xzf /var/cache/cmake/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz -C /opt/cmake
