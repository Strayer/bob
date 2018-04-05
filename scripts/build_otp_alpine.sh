#!/bin/bash

set -e -u

echo "Building ${OTP_REF}"
otp_url=https://github.com/erlang/otp/archive/${OTP_REF}.tar.gz

wget -nv ${otp_url}
tar -zxf ${OTP_REF}.tar.gz
chmod -R 777 otp-${OTP_REF}

cd otp-${OTP_REF}

case ${OTP_REF} in
	OTP-17* | maint-17)
    patch -p1 -i ../build-otp/remove-private-unit32.patch
    patch -p1 -i ../build-otp/hipe_x86_signal-fix.patch
    patch -p1 -i ../build-otp/replace_glibc_check.patch
    patch -p1 -i ../build-otp/remove_rpath.patch
    ;;
esac

export ERL_TOP=$PWD
export PATH=$ERL_TOP/bin:$PATH
export CPPFLAGS="-D_BSD_SOURCE"

./otp_build autoconf
./configure \
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
mv otp-${OTP_REF}/release/x86_64-unknown-linux-gnu/ ${OTP_REF}
rm ${OTP_REF}.tar.gz
tar -zcf out/${OTP_REF}.tar.gz ${OTP_REF}
