ARG FROM_IMAGE=nvidia/cuda:10.0-base-ubuntu18.04

FROM $FROM_IMAGE

ARG DEBIAN_FRONTEND=noninteractive

ARG LIBTENSORFLOW
ENV LIBTENSORFLOW=${LIBTENSORFLOW:-libtensorflow-gpu-linux-x86_64-1.15.0}

ARG FFMPEG
ENV FFMPEG=${FFMPEG:-ffmpeg-snapshot}

COPY install-libtensorflow.sh /
RUN /install-libtensorflow.sh $LIBTENSORFLOW

COPY install-ffmpeg.sh /
RUN /install-ffmpeg.sh $FFMPEG

RUN . ~/.profile
ENTRYPOINT ["/usr/local/bin/ffmpeg"]
