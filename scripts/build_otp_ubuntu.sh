#!/bin/bash

set -e -u

echo "Building ${OTP_REF}"
otp_url=https://github.com/erlang/otp/archive/${OTP_REF}.tar.gz

wget -nv ${otp_url}
tar -zxf ${OTP_REF}.tar.gz
chmod -R 777 otp-${OTP_REF}

cd otp-${OTP_REF}

./otp_build autoconf
./configure --with-ssl --enable-dirty-schedulers
make -j4
make release

cd ../
mv otp-${OTP_REF}/release/x86_64-unknown-linux-gnu/ ${OTP_REF}
rm ${OTP_REF}.tar.gz
tar -zcf out/${OTP_REF}.tar.gz ${OTP_REF}
