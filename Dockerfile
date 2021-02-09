ARG VERSION_CUDA=10.0-cudnn7
ARG VERSION_UBUNTU=18.04

FROM nvidia/cuda:${VERSION_CUDA}-devel-ubuntu${VERSION_UBUNTU} as build

ARG VERSION_FFMPEG=4.3.1
ARG VERSION_LIBTENSORFLOW=1.15.0
ARG DEPENDENCIES="autoconf automake build-essential cmake curl git-core libass-dev libfdk-aac-dev libfreetype6-dev libgnutls28-dev libmp3lame-dev libnuma-dev libopus-dev libsdl2-dev libtool libunistring-dev libva-dev libvdpau-dev libvorbis-dev libvpx-dev libxcb-shm0-dev libxcb-xfixes0-dev libxcb1-dev libx264-dev libx265-dev nasm pkg-config texinfo yasm zlib1g-dev python3.6 python3 python3-pip git"

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm

COPY script/ /usr/local/sbin/
COPY patch/ /tmp/patch/
 
RUN set -o errexit \
 && set -o xtrace \
 && bootstrap ${DEPENDENCIES} \
 && build-libtensorflow ${VERSION_LIBTENSORFLOW} \
 && build-ffmpeg ${VERSION_FFMPEG} \
 && build-sr-models ${VERSION_LIBTENSORFLOW} \
 && finalize ${DEPENDENCIES}

ENTRYPOINT ["/usr/local/bin/ffmpeg"]


FROM nvidia/cuda:${VERSION_CUDA}-runtime-ubuntu${VERSION_UBUNTU}

LABEL authors="Vít Novotný <witiko@mail.muni.cz>,Mikuláš Bankovič <456421@mail.muni.cz>,Dirk Lüth <dirk.lueth@gmail.com>" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.name="jetson.ffmpeg"

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm

COPY script/ /usr/local/sbin/

COPY --from=build /deps /
COPY --from=build /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg
COPY --from=build /usr/local/bin/ffprobe /usr/local/bin/ffprobe
COPY --from=build /usr/local/share/ffmpeg-tensorflow-models/ /usr/local/share/ffmpeg-tensorflow-models/

RUN set -o errexit \
 && set -o xtrace \
 && ln -s /usr/local/share/ffmpeg-tensorflow-models/ /models \
 && bootstrap ${DEPENDENCIES} \
 && finalize ${DEPENDENCIES}

ENTRYPOINT ["/usr/local/bin/ffmpeg"]
