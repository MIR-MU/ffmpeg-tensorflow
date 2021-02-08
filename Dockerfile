ARG VERSION_CUDA=10.0-cudnn7
ARG VERSION_UBUNTU=18.04

FROM nvidia/cuda:${VERSION_CUDA}-devel-ubuntu${VERSION_UBUNTU} as build

ARG VERSION_FFMPEG=4.3.1
ARG VERSION_LIBTENSORFLOW=1.15.0
ARG VERSION_TENSORFLOW=1.15.0

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm

COPY script/ /usr/local/sbin/
COPY patch/ /tmp/patch/
 
RUN set -e \
        && bootstrap \
        && build-libtensorflow ${VERSION_LIBTENSORFLOW} \
        && build-ffmpeg ${VERSION_FFMPEG} \
        && build-sr-models ${VERSION_TENSORFLOW} \
        && finalize

ENTRYPOINT ["/usr/local/bin/ffmpeg"]


FROM nvidia/cuda:${VERSION_CUDA}-runtime-ubuntu${VERSION_UBUNTU}

LABEL authors="Vít Novotný <witiko@mail.muni.cz>,Mikuláš Bankovič <456421@mail.muni.cz>,Dirk Lüth <dirk.lueth@gmail.com>" \
      org.label-schema.docker.dockerfile="/Dockerfile" \
      org.label-schema.name="jetson.ffmpeg"

ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm

COPY --from=build /deps /
COPY --from=build /usr/local/bin/ffmpeg /usr/local/bin/ffmpeg
COPY --from=build /usr/local/bin/ffprobe /usr/local/bin/ffprobe
COPY --from=build /usr/local/share/ffmpeg-tensorflow-models/ /usr/local/share/ffmpeg-tensorflow-models/

RUN set -e && ln -s /usr/local/share/ffmpeg-tensorflow-models/ /models

ENTRYPOINT ["/usr/local/bin/ffmpeg"]
