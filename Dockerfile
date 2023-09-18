FROM nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

# Tell the CUDA environment what GPU features to expose in the container.
ENV NVIDIA_DRIVER_CAPABILITIES $NVIDIA_DRIVER_CAPABILITIES,video,graphics

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies (topaz deb depends on these)
RUN apt-get update && apt-get install -y \
    gstreamer1.0-alsa \
    gstreamer1.0-gl \
    gstreamer1.0-gtk3 \
    gstreamer1.0-libav \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-base \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-pulseaudio \
    gstreamer1.0-qt5 \
    gstreamer1.0-tools \
    gstreamer1.0-x \
    libgstreamer-plugins-bad1.0-dev \
    libgstreamer-plugins-base1.0-dev \
    libgstreamer1.0-dev \
    libgtk2.0-0 \
    libunwind-dev \
    libvulkan1 \
    libxcb-xkb1 \
    libxcb1 \
    curl \
    net-tools \
 && rm -rf /var/lib/apt/lists/*

# Version of VAI to build
ENV VAI_VERSION=3.4.4.0.b
ARG VAI_SHA2=607e1b9ad497a353f5efe901a1640a7fe1f9dc7445bbad16f86bf0969f5b9083
ARG VAI_DIR=/opt/TopazVideoAIBETA

# Install the VAI deb package
RUN curl -Lo vai.deb "https://downloads.topazlabs.com/deploy/TopazVideoAIBeta/${VAI_VERSION}/TopazVideoAIBeta_${VAI_VERSION}_amd64.deb" \
 && echo "${VAI_SHA2}  vai.deb" | sha256sum -c \
 && dpkg -i vai.deb \
 && rm vai.deb

# Add conventience container initialization helper
COPY ./docker-init.sh /

# Use non-root to run VAI
RUN useradd -m -s /bin/bash user
USER user

# Setup required VAI env variables.
# Make ffmpeg resolve to VAI's variant by default.
# Use /models as the directory to store the large network tz files
#   (avoid re-downloading by volume mounting that directory)
ENV TVAI_MODEL_DATA_DIR=/models \
    TVAI_MODEL_DIR=${VAI_DIR}/models \
    LD_LIBRARY_PATH=${VAI_DIR}/lib \
    PATH=${VAI_DIR}/bin:${PATH}

# Tip: volume mount this from the host to process files from outside the container.
WORKDIR /workspace

ENTRYPOINT ["/docker-init.sh"]
CMD ["/bin/bash"]
