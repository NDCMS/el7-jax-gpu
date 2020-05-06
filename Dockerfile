FROM nvidia/cuda:10.2-cudnn7-devel-centos7
MAINTAINER Kenyi Hurtado <khurtado@nd.edu> 

RUN yum -y upgrade
RUN yum -y install epel-release yum-plugin-priorities

# osg repo
RUN yum -y install http://repo.opensciencegrid.org/osg/3.4/osg-3.4-el7-release-latest.rpm

# pegasus repo
RUN echo -e "# Pegasus\n[Pegasus]\nname=Pegasus\nbaseurl=http://download.pegasus.isi.edu/wms/download/rhel/7/\$basearch/\ngpgcheck=0\nenabled=1\npriority=50" >/etc/yum.repos.d/pegasus.repo

# well rounded basic system to support a wide range of user jobs
RUN yum -y groups mark convert
RUN yum -y grouplist
RUN yum -y groupinstall "Compatibility Libraries" \
                    "Development Tools" \
                    "Scientific Support"


RUN yum -y install \
	redhat-lsb \
	bc \
	binutils \
	binutils-devel \
	coreutils \
	curl \
	fontconfig \
	gcc \
	gcc-c++ \
	gcc-gfortran \
	git \
	glew-devel \
	glib2-devel \
	glib-devel \
	graphviz \
	gsl-devel \
        gtk3 \
	java-1.8.0-openjdk \
	java-1.8.0-openjdk-devel \
        libcurl \
	libgfortran \
	libGLU \
	libgomp \
	libicu \
	libquadmath \
	libtool \
	libtool-ltdl \
	libtool-ltdl-devel \
	libX11-devel \
	libXaw-devel \
	libXext-devel \
	libXft-devel \
	libxml2 \
	libxml2-devel \
	libXmu-devel \
	libXpm \
	libXpm-devel \
	libXt \
	mesa-libGL-devel \
	openssh \
	openssh-server \
	openssl \
        openssl-devel \
	osg-wn-client \
	p7zip \
	p7zip-plugins \
	redhat-lsb-core \
	rsync \
        stashcache-client \
	subversion \
	tcl-devel \
	tcsh \
	time \
	tk-devel \
	wget \
	which

# Add python3 support
RUN yum -y install \
        python3 \
        python3-dev \
        python3-tk

# osg
RUN yum -y install osg-ca-certs osg-wn-client
RUN rm -f /etc/grid-security/certificates/*.r0

# htcondor - include so we can chirp
RUN yum -y install condor

# Cleaning caches to reduce size of image
RUN yum clean all

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


# Create an empty location for nvidia executables
RUN for NVBIN in \
    nvidia-smi \
    nvidia-debugdump \
    nvidia-persistenced \
    nvidia-cuda-mps-control \
    nvidia-cuda-mps-server \
  ; do \
    touch /usr/bin/$NVBIN ; \
  done


RUN echo "/usr/local/cuda/lib64/" >/etc/ld.so.conf.d/cuda.conf
RUN echo "/usr/local/cuda/extras/CUPTI/lib64/" >>/etc/ld.so.conf.d/cuda.conf

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


