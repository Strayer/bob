#!/bin/bash

set -e -u

action=$1
ref=$2
cwd=$(pwd)
scripts="${cwd}/../../scripts"
priv="${cwd}/../../priv"
image=elixir-build
container=elixir-guides-${ref}

# fastly_hexpm=$BOB_FASTLY_SERVICE_HEXPM

# $1 = service
# $2 = key
function fastly_purge {
  curl \
    -X POST \
    -H "Fastly-Key: ${BOB_FASTLY_KEY}" \
    -H "Accept: application/json" \
    -H "Content-Length: 0" \
    "https://api.fastly.com/service/${1}/purge/${2}"
}

function build {
  cp ${scripts}/elixir.dockerfile .
  cp ${scripts}/asdf_install_otp.sh .
  cp ${scripts}/build_elixir_guides.sh .
  cp ${scripts}/*.exs .
  cp -r ${priv} priv

  docker build -t ${image} -f elixir.dockerfile .

  docker rm ${container} || true
  docker run -t --name=${container} -it ${image} "/app/build_elixir_guides.sh"

  rm -rf epub || true
  docker cp ${container}:/app/epub epub
  docker rm ${container} || true
}

function upload {
  pushd epub

  for file in *.epub
  do
    echo $file
    aws s3 cp "${file}" "s3://s3.hex.pm/guides/elixir/${file}" --content-type "application/epub+zip" --cache-control "public,max-age=3600" --metadata '{"surrogate-key":"guides","surrogate-control":"public,max-age=604800"}'
  done

  fastly_purge ${fastly_hexpm} guides

  popd
}

if [ "$1" == "push" ] && [ "$2" == "master" ]; then
  build
  # upload
fi
