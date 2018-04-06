#!/bin/bash

set -e -u

cwd=$(pwd)

function build {
  git clone git://github.com/elixir-lang/elixir-lang.github.com.git --quiet --depth 1 --branch master
  cd elixir-lang.github.com/_epub

  mix deps.get
  mix compile
  mix epub

  mkdir -p ${cwd}/epub
  cp *.epub ${cwd}/epub
}

build
