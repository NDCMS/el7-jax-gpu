FROM nvidia/cuda:10.2-cudnn7-devel-ubuntu16.04
MAINTAINER Kenyi Hurtado <khurtado@nd.edu> 

RUN apt-get update && apt-get upgrade -y --allow-unauthenticated
RUN add-apt-repository -y ppa:deadsnakes/ppa

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && apt-get upgrade -y --allow-unauthenticated && \
    apt-get install -y --allow-unauthenticated \
        build-essential \
        cmake \
        cuda-drivers \
        curl \
        davix-dev \
        dcap-dev \
        fonts-freefont-ttf \
        g++ \
        gcc \
        gfal2 \
        gfortran \
        git \
        libafterimage-dev \
        libavahi-compat-libdnssd-dev \
        libcfitsio-dev \
        libfftw3-dev \
        libfreetype6-dev \
        libftgl-dev \
        libgfal2-dev \
        libgif-dev \
        libgl2ps-dev \
        libglew-dev \
        libglu-dev \
        libgraphviz-dev \
        libgsl-dev \
        libjemalloc-dev \
        libjpeg-dev \
        libkrb5-dev \
        libldap2-dev \
        liblz4-dev \
        liblzma-dev \
        libmysqlclient-dev \
        libpcre++-dev \
        libpng12-dev \
        libpng-dev \
        libpq-dev \
        libpythia8-dev \
        libqt4-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        libtbb-dev \
        libtiff-dev \
        libx11-dev \
        libxext-dev \
        libxft-dev \
        libxml2-dev \
        libxpm-dev \
        libz-dev \
        libzmq3-dev \
        locales \
        lsb-release \
        make \
        module-init-tools \
        openjdk-8-jdk \
        openjdk-8-jre-headless \
        openssh-client \
        openssh-server \
        pkg-config \
        python \
        python3.6 \
        python3.6-dev \
        r-base \
        r-cran-rcpp \
        r-cran-rinside \
        rsync \
        software-properties-common \
        srm-ifce-dev \
        unixodbc-dev \
        unzip \
        vim \
        wget \
        zip \
        zlib1g-dev \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# bazel is required for some TensorFlow projects
RUN echo "deb [arch=amd64] http://storage.googleapis.com/bazel-apt stable jdk1.8" >/etc/apt/sources.list.d/bazel.list && \
    curl https://bazel.build/bazel-release.pub.gpg | apt-key add -

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --allow-unauthenticated \
        bazel

RUN echo "/usr/local/cuda/lib64/" >/etc/ld.so.conf.d/cuda.conf
# For CUDA profiling, TensorFlow requires CUPTI.
RUN echo "/usr/local/cuda/extras/CUPTI/lib64/" >>/etc/ld.so.conf.d/cuda.conf

# required directories
RUN for MNTPOINT in \
    /cvmfs \
    /hadoop \
    /hdfs \
    /lizard \
    /mnt/hadoop \
    /mnt/hdfs \
    /xenon \
    /spt \
    /stash2 \
    /srv \
    /scratch \
    /scratch365 \
    /data \
    /project \
  ; do \
    mkdir -p $MNTPOINT ; \
  done

# make sure we have a way to bind host provided libraries
# see https://github.com/singularityware/singularity/issues/611
RUN mkdir -p /host-libs /etc/OpenCL/vendors


### Python 3 support
# Note: The pip symlink will switch from pip2 to pip3 as the default
# But pip3 will be used here, just for clarity.

RUN curl -O https://bootstrap.pypa.io/get-pip.py
RUN python3 get-pip.py
RUN rm get-pip.py

RUN pip3 install cython

# Add jupyterhub
RUN pip3 install jupyterhub==1.0.0 notebook==6.0.3

# JAX
#RUN env PYTHON_VERSION=cp36 \
#    CUDA_VERSION=cuda102 \
#    PLATFORM=linux_x86_64 \
#    BASE_URL='https://storage.googleapis.com/jax-releases' \
#    pip3 install --upgrade $BASE_URL/$CUDA_VERSION/jaxlib-0.1.46-$PYTHON_VERSION-none-$PLATFORM.whl
RUN pip3 install --upgrade https://storage.googleapis.com/jax-releases/cuda102/jaxlib-0.1.46-cp36-none-linux_x86_64.whl
RUN pip3 install --upgrade jax

#################################
# Manually add Singularity files

RUN git clone https://github.com/jthiltges/singularity-environment.git /usr/singularity-environment/
RUN cp -r /usr/singularity-environment/{environment,.exec,.run,.shell,singularity,.singularity.d,.test} /
RUN mkdir /.singularity.d/libs

#################################
# According to: https://docs-dev.nersc.gov/cgpu/software/#shifter-with-cuda
RUN echo "export PATH and LD_LIBRARY_PATH"
ENTRYPOINT export PATH=/opt/shifter/bin:${PATH} && export LD_LIBRARY_PATH=/opt/shifter/lib:${LD_LIBRARY_PATH}

############
# Finish up

# build info
RUN echo "Timestamp:" `date --utc` | tee /image-build-info.txt

