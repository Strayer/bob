FROM ubuntu:14.04

RUN apt-get update

RUN apt-get install -y \
  curl \
  wget \
  ca-certificates \
  gcc \
  g++ \
  make \
  automake \
  autoconf \
  libwxgtk2.8-dev \
  libgl1-mesa-dev \
  libglu1-mesa-dev \
  libpng3 \
  libreadline-dev \
  libncurses-dev \
  libssl-dev \
  libssh-dev \
  libxslt-dev \
  libffi-dev \
  libtool \
  unixodbc-dev \
  fop \
  xsltproc

RUN mkdir -p /build
WORKDIR /build

COPY build_otp_ubuntu.sh /build/build.sh
RUN chmod +x /build/build.sh
CMD ./build.sh
