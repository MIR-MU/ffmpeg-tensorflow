ARG VERSION_CUDA=10.2-cudnn8
ARG VERSION_UBUNTU=18.04

FROM nvidia/cuda:${VERSION_CUDA}-devel-ubuntu${VERSION_UBUNTU} as build

ARG VERSION_FFMPEG=release/4.3

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    DEPENDENCIES="autoconf automake build-essential cmake git-core libass-dev libfdk-aac-dev libfreetype6-dev libgnutls28-dev libmp3lame-dev libnuma-dev libopus-dev libsdl2-dev libtool libunistring-dev libva-dev libvdpau-dev libvorbis-dev libvpx-dev libxcb-shm0-dev libxcb-xfixes0-dev libxcb1-dev libx264-dev libx265-dev nasm pkg-config texinfo yasm zlib1g-dev"  \
    CLEANUP="/tmp/* /var/tmp/* /var/log/* /var/lib/apt/lists/* /var/lib/{apt,dpkg,cache,log}/ /var/cache/apt/archives /usr/share/doc/ /usr/share/man/ /usr/share/locale/ /usr/local/lib/libcuda.so.1"

ADD tensorflow/include/ /usr/local/include/
ADD tensorflow/lib/ /usr/local/lib/

RUN set -e \
    && apt-get -qy update \
    ### tweak some apt & dpkg settings
        && echo "APT::Install-Recommends "0";" >> /etc/apt/apt.conf.d/docker-noinstall-recommends \
        && echo "APT::Install-Suggests "0";" >> /etc/apt/apt.conf.d/docker-noinstall-suggests \
        && echo "Dir::Cache "";" >> /etc/apt/apt.conf.d/docker-nocache \
        && echo "Dir::Cache::archives "";" >> /etc/apt/apt.conf.d/docker-nocache \
        && echo "path-exclude=/usr/share/locale/*" >> /etc/dpkg/dpkg.cfg.d/docker-nolocales \
        && echo "path-exclude=/usr/share/man/*" >> /etc/dpkg/dpkg.cfg.d/docker-noman \
        && echo "path-exclude=/usr/share/doc/*" >> /etc/dpkg/dpkg.cfg.d/docker-nodoc \
    ### run dist-upgrade
        && apt-get dist-upgrade -qy \
    ### install required packages
        && apt-get install -qy ${DEPENDENCIES} \
    ### build ffmpeg
        && ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/lib/libcuda.so.1 \
        && git clone git://source.ffmpeg.org/ffmpeg.git -b ${VERSION_FFMPEG} --depth=1 /tmp/ffmpeg \
        && cd /tmp/ffmpeg \
        && ./configure \
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
            --enable-nonfree \
        && make -j $(nproc) \
        && make install \
        && cd ~ \
    ### persist ffmpeg dependencies
        && mkdir /deps \
        && ldd /usr/local/bin/ffmpeg | tr -s '[:blank:]' '\n' | grep '^/' | xargs -I % sh -c 'mkdir -p $(dirname /deps%); cp % /deps%;' \
    ### cleanup
        && apt-get remove --purge -qy ${DEPENDENCIES} \
        && apt-get -qy autoclean \
        && apt-get -qy clean \
        && apt-get -qy autoremove --purge \
        && rm -rf ${CLEANUP} \
    ### finalize
        && . ~/.profile

ENTRYPOINT ["/usr/local/bin/ffmpeg"]


FROM nvidia/cuda:${VERSION_CUDA}-runtime-ubuntu${VERSION_UBUNTU}

LABEL authors="Vít Novotný <witiko@mail.muni.cz>,Mikuláš Miki Bankovič" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.name="jetson.ffmpeg"

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    CLEANUP="/tmp/* /var/tmp/* /var/log/* /var/lib/apt/lists/* /var/lib/{apt,dpkg,cache,log}/ /var/cache/apt/archives /usr/share/doc/ /usr/share/man/ /usr/share/locale/"

ADD tensorflow/lib/ /usr/local/lib/

RUN set -e \
    && apt-get -qy update \
    ### tweak some apt & dpkg settings
        && echo "APT::Install-Recommends "0";" >> /etc/apt/apt.conf.d/docker-noinstall-recommends \
        && echo "APT::Install-Suggests "0";" >> /etc/apt/apt.conf.d/docker-noinstall-suggests \
        && echo "Dir::Cache "";" >> /etc/apt/apt.conf.d/docker-nocache \
        && echo "Dir::Cache::archives "";" >> /etc/apt/apt.conf.d/docker-nocache \
        && echo "path-exclude=/usr/share/locale/*" >> /etc/dpkg/dpkg.cfg.d/docker-nolocales \
        && echo "path-exclude=/usr/share/man/*" >> /etc/dpkg/dpkg.cfg.d/docker-noman \
        && echo "path-exclude=/usr/share/doc/*" >> /etc/dpkg/dpkg.cfg.d/docker-nodoc \
    ### run dist-upgrade
        && apt-get dist-upgrade -qy \
    ### cleanup
        && apt-get -qy autoclean \
        && apt-get -qy clean \
        && apt-get -qy autoremove --purge \
        && rm -rf ${CLEANUP} \
    ### finalize
        && . ~/.profile

COPY --from=build /deps /
COPY --from=build /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg

ENTRYPOINT ["/usr/local/bin/ffmpeg"]