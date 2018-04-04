FROM alpine:3.7

RUN apk --no-cache upgrade

RUN apk add --no-cache \
    wget \
    bash \
    pcre \
    ca-certificates \
    openssl-dev \
    ncurses-dev \
    unixodbc-dev \
    zlib-dev \
    autoconf \
    build-base \
    perl-dev \
    dpkg-dev \
    dpkg

RUN mkdir -p /build/out
WORKDIR /build

COPY build_otp_alpine.sh /build/build.sh
COPY build-otp /build/build-otp
RUN chmod +x /build/build.sh
CMD ./build.sh
