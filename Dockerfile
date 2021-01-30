ARG VERSION_CUDA=10.0-cudnn7
ARG VERSION_UBUNTU=18.04

FROM nvidia/cuda:${VERSION_CUDA}-devel-ubuntu${VERSION_UBUNTU} as build

ARG VERSION_FFMPEG=4.3.1
ARG VERSION_LIBTENSORFLOW=1.15.0

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    DEPENDENCIES="autoconf automake build-essential cmake curl git-core libass-dev libfdk-aac-dev libfreetype6-dev libgnutls28-dev libmp3lame-dev libnuma-dev libopus-dev libsdl2-dev libtool libunistring-dev libva-dev libvdpau-dev libvorbis-dev libvpx-dev libxcb-shm0-dev libxcb-xfixes0-dev libxcb1-dev libx264-dev libx265-dev nasm pkg-config texinfo yasm zlib1g-dev" \
    CLEANUP="/usr/local/lib/libcuda.so.1"

COPY script/ /usr/local/sbin/
 
RUN set -e && bootstrap.sh \
    ### create required symlinks &directories
        && ln -s /usr/local/cuda/lib64/stubs/libcuda.so /usr/local/lib/libcuda.so.1 \
        && mkdir -p /tmp/ffmpeg /deps /deps/usr/local/lib \
    ### prepare libtensorflow
        && curl -kLs https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-gpu-linux-x86_64-${VERSION_LIBTENSORFLOW}.tar.gz | tar -xzC /usr/local -f - \
    ### build ffmpeg
        && curl -kLs https://ffmpeg.org/releases/ffmpeg-${VERSION_FFMPEG}.tar.bz2 | tar --strip 1 -xjC /tmp/ffmpeg -f - \
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
    ### prepare sr models
        && apt-get install -y python3 python3-pip git \
        && python3 -m pip install --upgrade pip \
        && pip3 install setuptools wheel \
        && pip3 install tensorflow==${VERSION_LIBTENSORFLOW} numpy \
        && git clone https://github.com/HighVoltageRocknRoll/sr \
        && cd sr \
        && python3 generate_header_and_model.py --model=espcn  --ckpt_path=checkpoints/espcn \
        && python3 generate_header_and_model.py --model=srcnn  --ckpt_path=checkpoints/srcnn \
        && python3 generate_header_and_model.py --model=vespcn --ckpt_path=checkpoints/vespcn \
        && python3 generate_header_and_model.py --model=vsrnet --ckpt_path=checkpoints/vsrnet \
        && mkdir /usr/local/share/ffmpeg-tensorflow-models/ \
        && cp espcn.pb srcnn.pb vespcn.pb vsrnet.pb /usr/local/share/ffmpeg-tensorflow-models/ \
        && cd .. \
        && rm -rf sr/ \
    ### persist dependencies
        && ldd /usr/local/bin/ffmpeg | tr -s '[:blank:]' '\n' | grep '^/' | xargs -I % sh -c 'mkdir -p $(dirname /deps%); cp % /deps%;' \
        && mv /usr/local/lib/libtensorflow* /deps/usr/local/lib \
    ### finalize
        && finalize.sh

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
COPY --from=build /usr/local/share/ffmpeg-tensorflow-models/ /usr/local/share/ffmpeg-tensorflow-models/

RUN set -e && ln -s /usr/local/share/ffmpeg-tensorflow-models/ /models && bootstrap.sh && finalize.sh

ENTRYPOINT ["/usr/local/bin/ffmpeg"]
