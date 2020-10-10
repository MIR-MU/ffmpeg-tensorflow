# FFMpeg with Libtensorflow

Since [Google Summer of Code 2018][summer-of-code], FFMpeg supports [the `sr`
filter][sr] for applying super-resolution methods based on convolutional neural
networks. However, compiling FFMpeg with proper libraries and preparing models
for super-resolution requires expert knowledge. This repository provides a
Dockerfile that makes super-resolution in FFMpeg a breeze!

## Requirements

- **[Miniconda][]**: For producing pre-trained super-resolution models.
- **[Docker][]**: For running containerized FFMpeg with super-resolution support.
- **[NVIDIA Container Toolkit][nvidia-docker]**: For GPU acceleration.

## Install FFMpeg with Libtensorflow

Install the `ffmpeg-tensorflow` Docker image:

``` sh
$ docker build https://github.com/MIR-MU/ffmpeg-tensorflow.git -t ffmpeg-tensorflow
```

Using [the `--build-arg` parameter of `docker build`][docker-build-arg], you can
also specify several additional installation options:

- **`FROM_IMAGE` (default: [`nvidia/cuda:10.0-base-ubuntu18.04`][nvidia-cuda])**:
  The base image on top of which FFMpeg is built.
  The version of CUDA (default: 10.0) should match your NVIDIA driver, see
  [NVIDIA CUDA Toolkit Release Notes, Table 2][nvidia-drivers].

- **`LIBTENSORFLOW` (default: `libtensorflow-gpu-linux-x86_64-1.15.0`)**:
  The version of the Libtensorflow library that will be downloaded from
  <https://storage.googleapis.com/tensorflow/> and used to compile FFmpeg.
  The version of Libtensorflow (default: 1.15.0) should match your version of
  CUDA, see [the compatibility table][tensorflow-compatibility].

- **`FFMPEG` (default: `ffmpeg-snapshot`)**:
  The version of FFMpeg (default: latest) that will be downloaded from
  <https://ffmpeg.org/releases/> and compiled. A version newer than 4.1 is
  required for Libtensorflow and super-resolution support.

After installation, you should see `ffmpeg-tensorflow` among your Docker images:

``` sh
$ docker images
REPOSITORY          TAG                     IMAGE ID            CREATED             SIZE
ffmpeg-tensorflow   latest                  60d2d17efba9        11 seconds ago      2.63GB
```

## Prepare super-resolution models

Create and activate a Miniconda environment named `ffmpeg-tensorflow`.
The version of the `tensorflow-gpu` should match the version of the
Libtensorflow library that you used during installation:

``` sh
$ conda create --name ffmpeg-tensorflow tensorflow-gpu=1.15.0 numpy python=3
$ conda activate ffmpeg-tensorflow
```

Next, download [the `HighVoltageRocknRoll/sr` GitHub
repository][HighVoltageRocknRoll/sr] that contains tensorflow checkpoints for
models trained on [the DIV2K dataset][div2k], and convert the tensorflow
checkpoints into super-resolution models:

``` sh
$ git clone https://github.com/HighVoltageRocknRoll/sr
$ cd sr/
$ python generate_header_and_model.py --model=espcn  --ckpt_path=checkpoints/espcn
$ python generate_header_and_model.py --model=srcnn  --ckpt_path=checkpoints/srcnn
$ python generate_header_and_model.py --model=vespcn --ckpt_path=checkpoints/vespcn
$ python generate_header_and_model.py --model=vsrnet --ckpt_path=checkpoints/vsrnet
$ cp espcn.pb srcnn.pb vespcn.pb vsrnet.pb ..
$ cd -
```

Finally, deactivate and remove the `ffmpeg-tensorflow` Miniconda environment,
and remove the `HighVoltageRocknRoll/sr` GitHub repository:

``` sh
$ conda deactivate
$ conda env remove --name ffmpeg-tensorflow
$ rm -rf sr/
```

You should be left with a number of super-resolution models:

``` sh
$ ls
espcn.pb srcnn.pb vespcn.pb vsrnet.pb
```

The [architectures][model-architectures] and [experimental
results][model-results] for the super-resolution results are described in the
`HighVoltageRocknRoll/sr` GitHub repository.

## Upscale a video using super-resolution

Download an [example video][flower]. You should now have both super-resolution
models and the example video in your current directory:

``` sh
$ wget https://media.xiph.org/video/derf/y4m/flower_cif.y4m
$ ls
espcn.pb flower_cif.y4m srcnn.pb vespcn.pb vsrnet.pb
```

Use the `ffmpeg-tensorflow` docker image to upscale the example video using one
of the super-resolution models (here ESPCN):

``` sh
$ docker run --rm --gpus all -u $(id -u) -v "$PWD":/data -w /data -i ffmpeg-tensorflow \
> -i flower_cif.y4m \
> -filter_complex '
>   [0:v] format=pix_fmts=yuv420p, extractplanes=y+u+v [y][u][v];
>   [y] sr=dnn_backend=tensorflow:scale_factor=2:model=espcn.pb [y_scale];
>   [u] scale=iw*2:ih*2 [u_scale];
>   [v] scale=iw*2:ih*2 [v_scale];
>   [y_scale][u_scale][v_scale] mergeplanes=0x001020:yuv420p [merged]
> ' -map [merged] -sws_flags lanczos \
> -c:v libx264 -crf 17 -preset ultrafast -tune film \
> -c:a copy \
> -y flower_cif_2x.mp4
```

The `flower_cif_2x.mp4` file with the upscaled example video should be produced.
Compare upscaling using Lanczos filtering (left) with upscaling using the ESPCN
super-resolution model (right):

 ![Comparison of Lanczos and ESPCN][comparison]

 [comparison]: comparison.jpg
 [div2k]: https://data.vision.ee.ethz.ch/cvl/DIV2K/
 [docker]: https://docs.docker.com/engine/install/
 [docker-build-arg]: https://docs.docker.com/engine/reference/builder/#arg
 [flower]: https://media.xiph.org/video/derf/y4m/flower_cif.y4m
 [HighVoltageRocknRoll/sr]: https://github.com/HighVoltageRocknRoll/sr
 [miniconda]: https://docs.conda.io/en/latest/miniconda.html
 [model-architectures]: https://github.com/HighVoltageRocknRoll/sr#image-and-video-super-resolution
 [model-results]: https://github.com/HighVoltageRocknRoll/sr#benchmark-results
 [nvidia-cuda]: https://hub.docker.com/r/nvidia/cuda/
 [nvidia-docker]: https://github.com/NVIDIA/nvidia-docker
 [nvidia-drivers]: https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html#cuda-major-component-versions
 [summer-of-code]: https://summerofcode.withgoogle.com/archive/2018/projects/5661133578960896/
 [sr]: https://ffmpeg.org/ffmpeg-filters.html#sr-1
 [tensorflow-compatibility]: https://www.tensorflow.org/install/source#gpu
