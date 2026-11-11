# syntax=docker/dockerfile:1.19
ARG DATA_IMAGE=no-data

FROM golang:1.27.3-alpine3.24 AS caddy
ARG CADDY_VERSION=2.11.7

RUN apk -U upgrade
RUN go install github.com/caddyserver/xcaddy/cmd/xcaddy@v0.4.7

WORKDIR /src
ENV XCADDY_GO_BUILD_FLAGS='-trimpath -ldflags "-s -w -extldflags -static" -tags "osusergo,netgo"'
RUN /go/bin/xcaddy build v$CADDY_VERSION --with github.com/ueffel/caddy-brotli

FROM ruby:4.0.9-alpine3.24 AS base
RUN apk add --no-cache -U ca-certificates gcompat jemalloc libpq-dev libxml2 libxslt yaml && \
    update-ca-certificates

ENV BUNDLE_WITHOUT="development:test"
ENV BUNDLER_FORCE_PLATFORM=true
ENV LD_PRELOAD=libjemalloc.so.2
ENV MALLOC_CONF=background_thread:true
ENV RAILS_ENV=production
ENV RUBY_YJIT_ENABLE=1

FROM base AS no-data
RUN mkdir /data && touch /data/geo_names.sqlite3 /data/overture.sqlite3

FROM ${DATA_IMAGE} AS data

FROM base AS build
RUN apk add --no-cache --virtual .gem-installdeps build-base \
                                                  git \
                                                  libxml2-dev \
                                                  libxslt-dev \
                                                  linux-headers \
                                                  yaml-dev

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock

WORKDIR /app

RUN gem update --system && gem install bundler -v $(grep -A 1 "BUNDLED WITH" Gemfile.lock | tail -n 1 | tr -d '[:space:]')
RUN bundle config set --global frozen 1 && \
    bundle install -j $(nproc) --retry 5

COPY . /app
RUN bundle exec bootsnap precompile app/ lib/
RUN rm -rf $GEM_HOME/cache && \
    find $GEM_HOME -name "*.c" -delete && \
    find $GEM_HOME -name "*.o" -delete && \
    rm -rf $GEM_HOME/*/doc $GEM_HOME/*/cache/*.gem && \
    apk del .gem-installdeps

FROM base AS runtime

RUN apk add --no-cache curl

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
COPY --from=caddy /src/caddy /usr/local/bin/caddy

WORKDIR /app

RUN mkdir -p tmp/pids tmp/sockets

ENV PORT=4743
ENV PUMA_SOCKET=/app/tmp/sockets/puma.sock
ENV RACK_ENV=production

RUN addgroup -g 1000 grid && adduser -u 1000 -G grid -s /bin/sh -D grid
RUN chown -R grid:grid /app

ENV GEO_NAMES_DATABASE=/usr/share/grid/geo_names.sqlite3
ENV OVERTURE_DATABASE=/usr/share/grid/overture.sqlite3
COPY --link --from=data /data/geo_names.sqlite3 /usr/share/grid/geo_names.sqlite3
COPY --link --from=data /data/overture.sqlite3 /usr/share/grid/overture.sqlite3

USER grid

EXPOSE 4743
CMD ["./web.sh"]
