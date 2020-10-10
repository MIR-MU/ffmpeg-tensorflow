FROM nvidia/cuda:10.0-base-ubuntu18.04

ARG DEBIAN_FRONTEND=noninteractive

RUN set -e; apt-get update -qq; apt-get -y install \
  autoconf \
  automake \
  build-essential \
  cmake \
  git-core \
  libass-dev \
  libfreetype6-dev \
  libgnutls28-dev \
  libsdl2-dev \
  libtool \
  libva-dev \
  libvdpau-dev \
  libvorbis-dev \
  libxcb1-dev \
  libxcb-shm0-dev \
  libxcb-xfixes0-dev \
  pkg-config \
  texinfo \
  wget \
  yasm \
  zlib1g-dev; \
  wget https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-gpu-linux-x86_64-1.15.0.tar.gz; \
  tar -C /usr/local -xzf libtensorflow-gpu-linux-x86_64-1.15.0.tar.gz; \
  rm libtensorflow-gpu-linux-x86_64-1.15.0.tar.gz; \ 
  mkdir -p ~/ffmpeg_sources ~/bin; \
  apt-get update -qq && apt-get install \ 
  nasm \
  libx264-dev \
  libx265-dev \
  libnuma-dev \
  libvpx-dev \
  libfdk-aac-dev \
  libmp3lame-dev \
  libopus-dev \
  libunistring-dev -y; \
  rm -rf /var/lib/apt/lists/*

RUN set -e; cd ~/ffmpeg_sources; \
  wget -O ffmpeg-snapshot.tar.bz2 https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2; \
  tar xjvf ffmpeg-snapshot.tar.bz2; \
  cd ffmpeg; \
  ./configure \
  --pkg-config-flags="--static" \
  --extra-libs="-lpthread -lm" \
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
  cd; \
  rm -rf ~/ffmpeg_sources

RUN . ~/.profile
ENTRYPOINT ["/bin/bash", "-c"]
