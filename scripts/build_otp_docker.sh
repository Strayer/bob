#!/bin/bash

set -e -u

ref_name=$1
ref=$2
linux=$3
cwd=$(pwd)
scripts="${cwd}/../../scripts"
image=otp-build-${linux}
container=otp-build-${linux}-${ref_name}

function fastly_purge {
  curl -X PURGE https://repo.hex.pm/${ref_name}
}

function build {
  cp ${scripts}/otp-${linux}.dockerfile .
  cp ${scripts}/build_otp_*.sh .

  docker build -t ${image} -f otp-${linux}.dockerfile .
  docker rm ${container} || true
  docker run -t -e OTP_REF=${ref_name} --name=${container} ${image}

  docker cp ${container}:/build/${ref_name}.tar.gz ${ref_name}.tar.gz
  docker rm ${container} || true
}

function upload {
  aws s3 cp ${ref_name}.tar.gz s3://s3.hex.pm/builds/otp/${linux}/${ref_name}.tar.gz --cache-control "public,max-age=3600" --metadata '{"surrogate-key":"otp-builds","surrogate-control":"public,max-age=604800"}'
  fastly_purge builds/otp/${linux}/${ref_name}.tar.gz
  
  aws s3 cp s3://s3.hex.pm/builds/otp/${linux}/builds.txt builds.txt || true
  touch builds.txt
  echo -e "${ref_name} ${ref}\n$(cat builds.txt)" > builds.txt
  sort -u -k1,1 -o builds.txt builds.txt
  aws s3 cp builds.txt s3://s3.hex.pm/builds/otp/${linux}/builds.txt --cache-control "public,max-age=3600" --metadata '{"surrogate-key":"otp-builds","surrogate-control":"public,max-age=604800"}'
  fastly_purge builds/otp/${linux}/builds.txt
}

build
upload
