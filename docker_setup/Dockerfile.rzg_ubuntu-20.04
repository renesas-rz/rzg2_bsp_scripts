# Download base image ubuntu 20.04
FROM ubuntu:20.04

# Default values if not passed on the build command line
ARG host_uid=1000
ARG host_gid=1000
ARG USERNAME=user
ARG TZ_VALUE="Etc/UTC"

# use bash instead of dash as default /bin/sh
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install tzdata and set up time zone
ENV TZ=$TZ_VALUE
RUN apt-get update && apt-get install -y apt-utils sudo

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ_VALUE > /etc/timezone \
    && dpkg-reconfigure -f noninteractive tzdata

# Install packages necessary for building Yocto/OpenEmbedded based images
RUN \
	apt-get install -y \
		gawk \
		wget \
		git-core \
		diffstat \
		unzip \
		texinfo \
		gcc-multilib \
		build-essential \
		chrpath \
		socat \
		cpio \
		python \
		python3 \
		python3-pip \
		python3-pexpect \
		xz-utils \
		debianutils \
		iputils-ping \
		python3-git \
		python3-jinja2 \
		libegl1-mesa \
		libsdl1.2-dev \
		pylint3 \
		xterm

# Install packages necessary for building U-boot
RUN \
	apt-get install -y \
		lzop \
		srecord

# Install packages necessary for building TFA
RUN \
	apt-get install -y \
		plantuml

# Install additional useful packages
RUN \
	apt-get install -y \
		curl \
		nano \
		pv \
		tmux \
		tree \
		vim \
		zip \
		p7zip-full \
		whiptail

# Setup locales
RUN \
	apt-get install -y locales && \
	rm -rf /var/lib/apt/lists/*
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8

# Add user account that matches the host
RUN groupadd -g $host_gid $USERNAME
RUN adduser --disabled-password --shell /bin/bash \
    --uid $host_uid --gid $host_gid \
    --gecos '' $USERNAME
RUN adduser $USERNAME sudo

# Add to the sudoers list (allow for sudo to run without password)
RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# To have a more colorful world
ENV TERM xterm-256color

# Start the container with user $USERNAME
USER $USERNAME

# Change the prompt
RUN echo PS1=\"\\[\\e[33m\\]dir\:\ \\w\\n\\[\\e[1\;31m\\]\\u\@\(docker\)\$\\[\\e[00m\\]\ \" >> ~/.bashrc
RUN echo printf=\"\\e]2\;docker\\a\" >> ~/.bashrc
