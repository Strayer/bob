#!/bin/bash

set -e -u

ref=$1
cwd=$(pwd)

function build_all_elixir {
  mkdir builds
  git clone git://github.com/elixir-lang/elixir.git --quiet --depth 1 --branch ${ref}

  otp_versions=($(elixir ${cwd}/elixir_to_otp.exs ${ref}))
  echo "Available OTP ${otp_versions[@]}"

  for otp_version in "${otp_versions[@]}"; do
    echo "Using OTP ${otp_version}"
    asdf local erlang ${otp_version}
    build_elixir

    otp_string=$(otp_string ${otp_version})
    cp elixir/*.zip ${cwd}/builds/${ref}${otp_string}.zip

    if [ "${otp_version}" == "${otp_versions[0]}" ]; then
      cp elixir/*.zip ${cwd}/builds/${ref}.zip
    fi
  done
}

function build_elixir {
  pushd elixir
  erl +V
  make clean
  make compile
  rm *.zip || true
  make Precompiled.zip || make release_zip
  popd
}

function build_docs {
  version=$(echo "${ref}" | sed 's/^v//g')

  MIX_ARCHIVES=${cwd}/.mix
  PATH=${cwd}/elixir/bin:${PATH}
  elixir -v

  mix local.hex --force
  mkdir docs
  cp ${cwd}/priv/logo.png docs/logo.png

  git clone git://github.com/elixir-lang/ex_doc.git --quiet

  pushd ex_doc
  tags=$(git tag)
  latest_version=$(elixir ${cwd}/latest_version.exs "${tags}")
  ex_doc_version=$(elixir ${cwd}/elixir_to_ex_doc.exs "${version}" "${latest_version}")
  git checkout "${ex_doc_version}"
  mix deps.get
  mix compile --no-elixir-version-check
  popd

  pushd elixir
  sed -i -e 's/-n http:\/\/elixir-lang.org\/docs\/\$(CANONICAL)\/\$(2)\//-n https:\/\/hexdocs.pm\/\$(2)\/\$(CANONICAL)/g' Makefile
  sed -i -e 's/-a http:\/\/elixir-lang.org\/docs\/\$(CANONICAL)\/\$(2)\//-a https:\/\/hexdocs.pm\/\$(2)\/\$(CANONICAL)/g' Makefile
  CANONICAL="${version}" make docs
  mv doc ${cwd}/docs/versioned

  tags=$(git tag)
  latest_version=$(elixir ${cwd}/latest_version.exs "${tags}")

  if [ "${version}" == "${latest_version}" ]; then
    CANONICAL="" make docs
    mv doc ${cwd}/docs/root
  fi
  popd
}

# $1 = version
function otp_string {
  otp_string=$(echo "$1" | awk 'match($0, /^[0-9][0-9]/) { print substr( $0, RSTART, RLENGTH )}')
  otp_string="-otp-${otp_string}"
  echo "${otp_string}"
}

build_all_elixir
build_docs
