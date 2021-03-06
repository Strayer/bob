FROM ubuntu:14.04

ARG otp_version

RUN apt-get update
RUN apt-get install -y git make wget zip

RUN wget -nv -O otp.tar.gz https://repo.hex.pm/builds/otp/ubuntu-14.04/OTP-${otp_version}.tar.gz
RUN mkdir -p /otp
RUN tar zxf otp.tar.gz -C /otp --strip-components=1
RUN /otp/Install -minimal /otp

ENV PATH=/otp/bin:$PATH

RUN mkdir -p /home/build/out
WORKDIR /home/build

COPY build_elixir.sh /home/build/build.sh
COPY utils.sh /home/build/utils.sh
COPY latest_version.exs /home/build/latest_version.exs
COPY elixir_to_ex_doc.exs /home/build/elixir_to_ex_doc.exs
COPY logo.png /home/build/logo.png
RUN chmod +x /home/build/build.sh
CMD ./build.sh
