FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    make \
    binutils \
    bison \
    flex \
    libncurses-dev \
    libssl-dev \
    libelf-dev \
    bc \
    kmod \
    cpio \
    gawk \
    wget \
    rsync \
    tar \
    xz-utils \
    git \
    python3 \
    python3-dev \
    isolinux \
    syslinux-utils \
    genisoimage \
    sudo \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

VOLUME ["/build/src", "/build/output"]

CMD ["/bin/bash"]