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

First, download the Libtensorflow library. Your version of Libtensorflow (here
`1.15.0`) should match your version of CUDA, see [the compatibility
table][tensorflow-compatibility]. Your version of CUDA should match your NVIDIA
driver, see [NVIDIA CUDA Toolkit Release Notes, Table 2][nvidia-driver].

``` sh
$ mkdir -p tensorflow/lib_package/
$ pushd tensorflow/lib_package/
$ wget https://storage.googleapis.com/tensorflow/libtensorflow/libtensorflow-gpu-linux-x86_64-1.15.0.tar.gz
$ popd
```

If your version of Libtensorflow is not pre-built, you will need to build it
yourself (takes about 2 hours on a quad-core laptop).

``` sh
$ git clone https://github.com/tensorflow/tensorflow.git
$ pushd tensorflow/tensorflow/tools/ci_build/linux/
$ git checkout v1.15.0
$ ./libtensorflow_gpu.sh
$ popd
```

Next, build our FFMpeg Docker image (takes about 5 minutes on a quad-core
laptop). [Your `nvidia/cuda` base image][nvidia-cuda] should match your version
of CUDA (here 10.0).

``` sh
$ git clone https://github.com/MIR-MU/ffmpeg-tensorflow.git
$ tar xzvf tensorflow/lib_package/libtensorflow-gpu*.tar.gz -C ffmpeg-tensorflow/
$ docker build -t ffmpeg --build-arg FROM_IMAGE=cuda:10.0-cudnn7-devel-ubuntu18.04 ffmpeg-tensorflow/
```

You should now see `ffmpeg` among your Docker images. Remove auxiliary
directories and intermediary Docker images downloaded during the installation:

``` sh
$ docker images
REPOSITORY          TAG                            IMAGE ID            CREATED             SIZE
ffmpeg              latest                         5d66a25f140b        About an hour ago   5.34GB
tf-tensorflow-gpu   latest                         7f8c5a76892c        4 hours ago         6.15GB
$ rm -rf ffmpeg-tensorflow/ tensorflow/
$ docker rmi 7f8c5a76892c
```

## Prepare super-resolution models

Create and activate a Miniconda environment named `ffmpeg-tensorflow`.
Your version of the `tensorflow` package (here 1.15.0) should match the
version of Libtensorflow that you used during installation:

``` sh
$ conda create --name ffmpeg-tensorflow tensorflow=1.15.0 numpy python=3
$ conda activate ffmpeg-tensorflow
```

Next, download [the `HighVoltageRocknRoll/sr` GitHub
repository][HighVoltageRocknRoll/sr] that contains tensorflow checkpoints for
models trained on [the DIV2K dataset][div2k], and convert the tensorflow
checkpoints into super-resolution models:

``` sh
$ git clone https://github.com/HighVoltageRocknRoll/sr
$ pushd sr
$ python generate_header_and_model.py --model=espcn  --ckpt_path=checkpoints/espcn
$ python generate_header_and_model.py --model=srcnn  --ckpt_path=checkpoints/srcnn
$ python generate_header_and_model.py --model=vespcn --ckpt_path=checkpoints/vespcn
$ python generate_header_and_model.py --model=vsrnet --ckpt_path=checkpoints/vsrnet
$ cp espcn.pb srcnn.pb vespcn.pb vsrnet.pb ..
$ popd
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

Download an [example video][flower] and use the `ffmpeg-tensorflow` docker
image to upscale it using one of the super-resolution models (here ESPCN):

``` sh
$ wget https://media.xiph.org/video/derf/y4m/flower_cif.y4m
$ docker run --rm --gpus all -u $(id -u):$(id -g) -v "$PWD":/data -w /data -it ffmpeg \
> -i flower_cif.y4m \
> -filter_complex '
>   [0:v] format=pix_fmts=yuv420p, extractplanes=y+u+v [y][u][v];
>   [y] sr=dnn_backend=tensorflow:scale_factor=2:model=espcn.pb [y_scaled];
>   [u] scale=iw*2:ih*2 [u_scaled];
>   [v] scale=iw*2:ih*2 [v_scaled];
>   [y_scaled][u_scaled][v_scaled] mergeplanes=0x001020:yuv420p [merged]
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
 [ffmpeg-latest]: https://ffmpeg.org/releases/ffmpeg-snapshot.tar.bz2
 [HighVoltageRocknRoll/sr]: https://github.com/HighVoltageRocknRoll/sr
 [libtensorflow-1.12.3]: https://github.com/MIR-MU/ffmpeg-tensorflow/issues/1
 [miniconda]: https://docs.conda.io/en/latest/miniconda.html
 [model-architectures]: https://github.com/HighVoltageRocknRoll/sr#image-and-video-super-resolution
 [model-results]: https://github.com/HighVoltageRocknRoll/sr#benchmark-results
 [nvidia-cuda]: https://hub.docker.com/r/nvidia/cuda/
 [nvidia-docker]: https://github.com/NVIDIA/nvidia-docker
 [nvidia-driver]: https://docs.nvidia.com/cuda/cuda-toolkit-release-notes/index.html#cuda-major-component-versions
 [summer-of-code]: https://summerofcode.withgoogle.com/archive/2018/projects/5661133578960896/
 [sr]: https://ffmpeg.org/ffmpeg-filters.html#sr-1
 [tensorflow-compatibility]: https://www.tensorflow.org/install/source#gpu
