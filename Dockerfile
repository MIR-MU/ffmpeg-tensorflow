ARG FROM_IMAGE=nvidia/cuda:10.0-cudnn7-devel-ubuntu18.04

FROM $FROM_IMAGE

ARG DEBIAN_FRONTEND=noninteractive

ARG FFMPEG
ENV FFMPEG=${FFMPEG:-ffmpeg-snapshot}

ADD include/ /usr/local/include/
ADD lib/ /usr/local/lib/

RUN set -e; \
    apt-get update -qq; \
    apt-get -y --no-install-recommends install \
      autoconf \
      automake \
      build-essential \
      cmake \
      git-core \
      libass-dev \
      libfdk-aac-dev \
      libfreetype6-dev \
      libgnutls28-dev \
      libmp3lame-dev \
      libnuma-dev \
      libopus-dev \
      libsdl2-dev \
      libtool \
      libunistring-dev \
      libva-dev \
      libvdpau-dev \
      libvorbis-dev \
      libvpx-dev \
      libxcb-shm0-dev \
      libxcb-xfixes0-dev \
      libxcb1-dev \
      libx264-dev \
      libx265-dev \
      nasm \
      pkg-config \
      texinfo \
      wget \
      yasm \
      zlib1g-dev; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir ~/ffmpeg-sources; \
    wget --no-check-certificate -O - https://ffmpeg.org/releases/$FFMPEG.tar.bz2 | \
      tar xjC ~/ffmpeg-sources; \
    ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/lib/libcuda.so.1; \
    cd ~/ffmpeg-sources/ffmpeg; \
      ./configure \
        --pkg-config-flags='--static' \
        --extra-libs='-lpthread -lm' \
        --enable-gpl \
        --enable-gnutls \
        --enable-libass \
        --enable-libfdk-aac \
        --enable-libfreetype \
        --enable-libmp3lame \
        --enable-libopus \
        --enable-libvorbis \
        --enable-libvpx \
        --enable-libx264 \
        --enable-libx265 \
        --enable-libtensorflow \
        --enable-nonfree; \
      make -j $(nproc); \
      make install; \
    cd -; \
    rm -rf ~/ffmpeg_sources; \
    rm /usr/local/lib/libcuda.so.1; \
    . ~/.profile

ENTRYPOINT ["/usr/local/bin/ffmpeg"]
