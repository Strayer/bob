FROM ubuntu:14.04

RUN apt-get update

RUN apt-get install -y \
  git \
  wget \
  curl \
  unzip \
  zip \
  build-essential \
  locales

RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN mkdir -p /build
WORKDIR /build

RUN git clone https://github.com/asdf-vm/asdf.git /asdf --branch v0.4.3
ENV PATH="$PATH:/asdf/shims:/asdf/bin"
RUN asdf plugin-add erlang
RUN asdf plugin-add elixir

RUN asdf install elixir 1.6.4

COPY asdf_install_otp.sh asdf_install_otp.sh
RUN ./asdf_install_otp.sh 17.3 ubuntu-14.04
RUN ./asdf_install_otp.sh 17.5 ubuntu-14.04
RUN ./asdf_install_otp.sh 18.3 ubuntu-14.04
RUN ./asdf_install_otp.sh 19.3 ubuntu-14.04
RUN ./asdf_install_otp.sh 20.2 ubuntu-14.04
RUN ./asdf_install_otp.sh 20.3 ubuntu-14.04

RUN mkdir /app
WORKDIR /app

RUN asdf local erlang 20.3
RUN asdf local elixir 1.6.4

RUN mix local.hex --force
RUN mix local.rebar --force

COPY priv priv
COPY build_elixir*.sh ./
COPY *.exs ./

ENTRYPOINT ["/bin/bash", "-c"]
