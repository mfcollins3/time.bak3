# Copyright 2026 Michael F. Collins, III
# Licensed under the Naked Time license. See LICENSE.md for details.

# Builds the release for the Naked Time web application and packages it in a
# small Debian runtime image.
#
# The stages are ordered so that Docker's layer cache (and the GitHub Actions
# cache backend that CI uses) can reuse the dependency layers until mix.lock
# or the compile-time configuration changes. Only the layers that copy and
# compile the application source are rebuilt for a normal code change.
#
# The final image is selected with the RUNTIME_IMAGE build argument. It
# defaults to the `runtime` stage below, which builds the release from
# source. CI builds the image once and pushes it to GitHub Packages. The
# Aspire deployment then sets RUNTIME_IMAGE to that image so that BuildKit
# skips the build stages and only re-tags the image for Azure Container
# Registry.
#
# Find base image tags at https://hub.docker.com/r/hexpm/elixir/tags.

ARG ELIXIR_VERSION=1.20.5
ARG OTP_VERSION=29.1.2
ARG DEBIAN_VERSION=trixie-20261104-slim
# Node.js and pnpm are only needed in the builder stage to run Vite. Keep the
# Node.js major version in sync with .node-version at the repository root and
# the pnpm major version in sync with PNPM_VERSION in
# .github/workflows/web.yml. Find Node.js image tags at
# https://hub.docker.com/_/node/tags.
ARG NODE_VERSION=26
ARG PNPM_VERSION=12
ARG NODE_IMAGE="docker.io/node:${NODE_VERSION}-trixie-slim"

ARG BUILDER_IMAGE="docker.io/hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="docker.io/debian:${DEBIAN_VERSION}"

ARG RUNTIME_IMAGE=runtime

FROM ${NODE_IMAGE} AS node

FROM ${BUILDER_IMAGE} AS builder

# Install the build dependencies. git is required for the heroicons
# dependency, which is fetched from GitHub.
RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential git ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Copy Node.js and npm from the official Node image, then use npm to install
# pnpm. Only the Node files are copied so that the Elixir installation in
# /usr/local is left untouched.
ARG PNPM_VERSION
COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s ../lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
  && npm install --global --no-fund --no-audit "pnpm@${PNPM_VERSION}" \
  && node --version \
  && pnpm --version

WORKDIR /app

RUN mix local.hex --force \
  && mix local.rebar --force

ENV MIX_ENV="prod"

# Install the mix dependencies. These layers are reused until mix.exs or
# mix.lock changes.
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy the compile-time config files before compiling the dependencies so
# that changes to the config files trigger recompiling the dependencies.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Install the Node.js packages in their own layer, which is reused until
# package.json or pnpm-lock.yaml changes. The phoenix,
# phoenix_html, phoenix_live_view and phoenix_vite packages come from deps/,
# so this runs after mix deps.get. --frozen-lockfile installs exactly what
# the lockfile lists and fails if the lockfile is out of date.
COPY assets/package.json assets/pnpm-lock.yaml assets/
RUN pnpm --dir assets install --frozen-lockfile

COPY priv priv
COPY lib lib

# Compile the release.
RUN mix compile

# Assets are built after compiling because Phoenix colocated hooks and
# Tailwind's source scanning depend on the compiled application. Vite writes
# the bundles and its manifest to priv/static, which mix release then copies
# into the release.
COPY assets assets
RUN mix assets.deploy

# Changes to config/runtime.exs don't require recompiling the code.
COPY config/runtime.exs config/
COPY rel rel
RUN mix release

# Builds the runtime image with the release from the builder stage.
FROM ${RUNNER_IMAGE} AS runtime

RUN apt-get update \
  && apt-get install -y --no-install-recommends libstdc++6 openssl libncurses6 locales ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Set the locale.
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
  && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

ENV MIX_ENV="prod"
ENV PHX_SERVER="true"
ENV PORT="4000"

COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/web ./

USER nobody

EXPOSE 4000

# Running the migrations uses the same image with the command
# /app/bin/migrate.
CMD ["/app/bin/server"]

# The image that is published. See the RUNTIME_IMAGE argument above.
FROM ${RUNTIME_IMAGE} AS final
