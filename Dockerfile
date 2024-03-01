FROM ubuntu:20.04

ARG OPENFHE="openfhe-development"
ARG branch=main
ARG tag=v0.9.1
ARG CC_param=/usr/bin/gcc-10
ARG CXX_param=/usr/bin/g++-10
ARG no_threads=1

ENV DEBIAN_FRONTEND=noninteractive
ENV CC $CC_param
ENV CXX $CXX_param
ENV INSTALL_DIR=$HOME/.local
ENV PATH="$HOME/.local/bin:$PATH"

#install pre-requisites for OpenFHE
RUN apt update && apt -y upgrade

RUN apt install -y git \
                   build-essential \
                   gcc-10 \
                   g++-10 \
                   cmake \
                   autoconf \
                   clang-10 \
                   libomp5 \
                   libomp-dev \
                   doxygen \
                   graphviz \
                   libboost-all-dev=1.71.0.0ubuntu2 \
                   libtool \
                   wget \
                   pkg-config

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p INSTALL_DIR

RUN cd $HOME && git clone --recurse-submodules -b v1.60.0 --depth 1 --shallow-submodules https://github.com/grpc/grpc && cd grpc && mkdir -p cmake/build && cd cmake/build && cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR ../.. && make -j $no_threads && make install

#git clone the openfhe-development repository and its submodules (this always clones the most latest commit)
RUN cd $HOME && git clone https://github.com/openfheorg/$OPENFHE.git && cd ~/$OPENFHE && git checkout $branch && git checkout $tag && git submodule sync --recursive && git submodule update --init  --recursive

#installing OpenFHE
RUN mkdir -p $HOME/$OPENFHE/build && cd $HOME/$OPENFHE/build && cmake .. && make -j $no_threads && make install