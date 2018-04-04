#!/bin/bash

set -e -u

echo "Building ${OTP_REF}"
otp_url=http://www.erlang.org/download/otp_src_17.5.tar.gz
otp_untar_dir="otp-${OTP_REF}"

wget -nv ${otp_url}
tar -zxf otp_src_17.5.tar.gz
chmod -R 777 otp_src_17.5

cd otp_src_17.5

case ${OTP_REF} in
	OTP-17* | maint-17)
    patch -p1 -i ../build-otp/remove-private-unit32.patch
    patch -p1 -i ../build-otp/hipe_x86_signal-fix.patch
    patch -p1 -i ../build-otp/replace_glibc_check.patch
    ;;
esac

export ERL_TOP=$PWD
export PATH=$ERL_TOP/bin:$PATH
export CPPFLAGS="-D_BSD_SOURCE"

# ./otp_build autoconf
./configure \
  --build="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
  --host="$(dpkg-architecture --query DEB_HOST_GNU_TYPE)" \
  --without-javac \
  --without-wx \
  --without-debugger \
  --without-observer \
  --without-jinterface \
  --without-cosEvent\
  --without-cosEventDomain \
  --without-cosFileTransfer \
  --without-cosNotification \
  --without-cosProperty \
  --without-cosTime \
  --without-cosTransactions \
  --without-et \
  --without-gs \
  --without-ic \
  --without-megaco \
  --without-orber \
  --without-percept \
  --without-typer \
  --enable-threads \
  --enable-dirty-schedulers \
	--enable-shared-zlib \
	--enable-ssl=dynamic-ssl-lib \
  --disable-hipe

make -j4
make release

cd ../
mv otp_src_17.5/release/x86_64-unknown-linux-gnu/ ${OTP_REF}
rm otp_src_17.5.tar.gz
tar -zcf out/${OTP_REF}.tar.gz ${OTP_REF}
