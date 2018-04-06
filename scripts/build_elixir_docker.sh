#!/bin/bash

set -e -u

action=$1
ref=$2
cwd=$(pwd)
scripts="${cwd}/../../scripts"
priv="${cwd}/../../priv"
version=$(echo "${ref}" | sed 's/^v//g')
image=elixir-build
container=elixir-build-${ref}

apps=(eex elixir ex_unit iex logger mix)
# fastly_hexpm=$BOB_FASTLY_SERVICE_HEXPM
# fastly_hexdocs=$BOB_FASTLY_SERVICE_HEXDOCS

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
  cp ${scripts}/build_elixir.sh .
  cp ${scripts}/*.exs .
  cp -r ${priv} priv

  docker build -t ${image} -f elixir.dockerfile .

  docker rm ${container} || true
  docker run -t --name=${container} -it ${image} "/app/build_elixir.sh ${ref}"

  rm -rf builds docs || true
  docker cp ${container}:/app/builds builds
  docker cp ${container}:/app/docs docs
  docker rm ${container} || true
}

function upload_builds {
  pushd builds

  for zip in *.zip; do
    aws s3 cp ${zip} "s3://s3.hex.pm/builds/elixir/${zip}" --cache-control "public,max-age=3600" --metadata '{"surrogate-key":"builds","surrogate-control":"public,max-age=604800"}'
  done

  fastly_purge ${fastly_hexpm} builds

  popd
}

function upload_docs {
  pushd docs

  pushd versioned
  for app in "${apps[@]}"; do
    aws s3 cp "${app}" "s3://hexdocs.pm/${app}/${version}" --recursive --cache-control "public,max-age=3600" --metadata "{\"surrogate-key\":\"docspage/${app}/${version}\",\"surrogate-control\":\"public,max-age=604800\"}"
    fastly_purge ${fastly_hexdocs} "docspage/${app}/${version}"

    tar -czf "${app}-${version}.tar.gz" -C "${app}" .
    aws s3 cp "${app}-${version}.tar.gz" "s3://s3.hex.pm/docs/${app}-${version}.tar.gz" --cache-control "public,max-age=3600" --metadata "{\"surrogate-key\":\"docs/${app}-${version}\",\"surrogate-control\":\"public,max-age=604800\"}"
    fastly_purge ${fastly_hexpm} "docs/${app}-${version}"
  done
  popd

  if [ -d root ]; then
    pushd root
    for app in "${apps[@]}"; do
      aws s3 cp "${app}" "s3://hexdocs.pm/${app}" --recursive --cache-control "public,max-age=3600" --metadata "{\"surrogate-key\":\"docspage/${app}\",\"surrogate-control\":\"public,max-age=604800\"}"
      fastly_purge ${fastly_hexdocs} "docspage/${app}"
    done
    popd
  fi

  popd
}

function delete {
  aws s3 rm "s3://s3.hex.pm/builds/elixir/${ref}.zip"
  aws s3 rm "s3://s3.hex.pm" --recursive --exclude "*" --include "builds/elixir/${ref}-otp-*.zip"

  for app in "${apps[@]}"; do
    aws s3 rm "s3://s3.hex.pm/docs/${app}-${version}.tar.gz"
    fastly_purge ${fastly_hexpm} builds

    aws s3 rm "s3://hexdocs.pm/${app}/${version}" --recursive
    fastly_purge ${fastly_hexdocs} "docspage/${app}/${version}"
  done
}

case ${action} in
  "push" | "create")
    build
    # upload_builds
    # upload_docs
    ;;

  "delete")
    delete
    ;;
esac
