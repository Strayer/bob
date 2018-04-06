FROM alpine:3.7 AS builder

RUN mkdir /build
WORKDIR /build

ENV APP_NAME=bob
ENV ERLANG_VERSION=20.3
ENV ELIXIR_VERSION=1.6.4
ENV MIX_ENV=prod

RUN apk --no-cache upgrade

RUN apk add --update \
  bash \
  openssl \
  erlang=${ERLANG_VERSION}-r0 \
  erlang-crypto=${ERLANG_VERSION}-r0 \
  erlang-runtime-tools=${ERLANG_VERSION}-r0 \
  erlang-syntax-tools=${ERLANG_VERSION}-r0 \
  elixir=${ELIXIR_VERSION}-r0

COPY mix.exs mix.lock /build/
COPY config /build/config
COPY priv /build/priv

RUN \
  mix local.hex --force && \
  mix local.rebar --force && \
  mix deps.get && \
  mix deps.compile

COPY lib /build/lib
COPY rel/config.exs /build/rel/config.exs

RUN \
  mix compile && \
  mix release --env=$MIX_ENV

RUN mv _build/$MIX_ENV/rel/$APP_NAME/releases/*/$APP_NAME.tar.gz .



FROM alpine:3.7 as app

ENV APP_NAME=bob

RUN apk --no-cache upgrade

RUN apk add --update \
  py2-pip \
  tarsnap \
  bash \
  openssl

RUN pip install awscli --upgrade --user

COPY --from=builder /build/$APP_NAME.tar.gz ./
RUN mkdir /app && tar xf $APP_NAME.tar.gz -C /app && rm $APP_NAME.tar.gz
WORKDIR /app

# Hardocded app name :(
ENTRYPOINT ["bin/bob", "foreground"]




# RUN apt install -y docker docker.io
# RUN groupadd docker
# RUN usermod -aG docker $USER
