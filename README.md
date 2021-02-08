# FFMpeg with Libtensorflow

Since [Google Summer of Code 2018][summer-of-code], FFMpeg supports [the `sr`
filter][sr] for applying super-resolution methods based on convolutional neural
networks. However, compiling FFMpeg with proper libraries and preparing models
for super-resolution requires expert knowledge. This repository provides a
Dockerfile that makes super-resolution in FFMpeg a breeze!

## Requirements

- **[Docker][]**: For running containerized FFMpeg with super-resolution support.
- **[NVIDIA Container Toolkit][nvidia-docker]**: For GPU acceleration.

## Install FFMpeg with Libtensorflow (Optional)

Simply clone the repo and build the container with the following commands:

``` sh
git clone https://github.com/MIR-MU/ffmpeg-tensorflow.git
docker build --compress --no-cache --force-rm --squash -t miratmu/ffmpeg-tensorflow ffmpeg-tensorflow/
```

If you wish to use different versions of Libtensorflow, FFMpeg, CUDA, or Ubuntu
you can also build a customized container. Keep in mind that your version of
Libtensorflow (here `1.15.0`) should match your version of CUDA (here ≥ 10.0),
see [the compatibility table][tensorflow-compatibility]. Your version of CUDA
should match your NVIDIA driver, see [NVIDIA CUDA Toolkit Release Notes, Table
2][nvidia-driver]:

``` sh
docker build --compress --no-cache --force-rm --squash --build-arg VERSION_LIBTENSORFLOW=1.15.0 --build-arg VERSION_TENSORFLOW=1.15.0 --build-arg VERSION_CUDA=10.0-cudnn7 --build-arg VERSION_UBUNTU=18.04 --build-arg VERSION_FFMPEG=4.3.1 -t miratmu/ffmpeg-tensorflow ffmpeg-tensorflow/
```

You should now see `miratmu/ffmpeg-tensorflow` among your Docker images:

``` sh
docker images
```

You can now remove the downloaded during the installation:

``` sh
rm -rf ffmpeg-tensorflow/
```

If you skip this section, a pre-build Docker image will be downloaded from
[Docker Hub][docker-hub].

## Upscale a video using super-resolution

Download an [example video][flower] and run the `miratmu/ffmpeg-tensorflow`
docker image to upscale it using one of the super-resolution models (here
ESPCN):

``` sh
wget https://media.xiph.org/video/derf/y4m/flower_cif.y4m
alias ffmpeg-tensorflow='docker run --rm --gpus all -u $(id -u):$(id -g) -v "$PWD":/data -w /data -it miratmu/ffmpeg-tensorflow'
ffmpeg-tensorflow -i flower_cif.y4m -filter_complex '[0:v] format=pix_fmts=yuv420p, extractplanes=y+u+v [y][u][v]; [y] sr=dnn_backend=tensorflow:scale_factor=2:model=/models/espcn.pb [y_scaled]; [u] scale=iw*2:ih*2 [u_scaled]; [v] scale=iw*2:ih*2 [v_scaled]; [y_scaled][u_scaled][v_scaled] mergeplanes=0x001020:yuv420p [merged]' -map [merged] -sws_flags lanczos -c:v libx264 -crf 17 -c:a copy -y flower_cif_2x.mp4
```

The `flower_cif_2x.mp4` file with the upscaled example video should be produced.
Compare upscaling using Lanczos filtering (left) with upscaling using the ESPCN
super-resolution model (right):

 ![Comparison of Lanczos and ESPCN][comparison]

Besides ESPCN, the docker image includes pre-trained SRCNN, VESPCN, and VSRNET
models in the `/models` directory. The [architectures][model-architectures] and
[experimental results][model-results] for the super-resolution results are
described in the `HighVoltageRocknRoll/sr` GitHub repository.

 [comparison]: comparison.jpg
 [div2k]: https://data.vision.ee.ethz.ch/cvl/DIV2K/
 [docker]: https://docs.docker.com/engine/install/
 [docker-build-arg]: https://docs.docker.com/engine/reference/builder/#arg
 [docker-hub]: https://hub.docker.com/r/miratmu/ffmpeg-tensorflow
 [flower]: https://media.xiph.org/video/derf/y4m/flower_cif.y4m
 [ffmpeg-latest]: https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
 [HighVoltageRocknRoll/sr]: https://github.com/HighVoltageRocknRoll/sr
 [issues]: https://github.com/MIR-MU/ffmpeg-tensorflow/issues?q=is%3Aissue
 [miniconda]: https://docs.conda.io/en/latest/miniconda.html
 [model-architectures]: https://github.com/HighVoltageRocknRoll/sr#image-and-video-super-resolution
 [model-results]: https://github.com/HighVoltageRocknRoll/sr#benchmark-results
 [nvidia-cuda]: https://hub.docker.com/r/nvidia/cuda/
 [nvidia-docker]: https://github.com/NVIDIA/nvidia-docker
 [nvidia-driver]: https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html#cuda-major-component-versions
 [summer-of-code]: https://summerofcode.withgoogle.com/archive/2018/projects/5661133578960896/
 [sr]: https://ffmpeg.org/ffmpeg-filters.html#sr-1
 [tensorflow-compatibility]: https://www.tensorflow.org/install/source#gpu
