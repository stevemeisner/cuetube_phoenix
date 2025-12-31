# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian
# instead of Alpine to avoid musl libc issues.
ARG ELIXIR_VERSION=1.18.4
ARG OTP_VERSION=26.0.1
ARG DEBIAN_VERSION=bookworm-20251229-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} as builder

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build step
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before compiling dependencies
COPY config/config.exs config/prod.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

# install JS dependencies
# if you have any npm dependencies, add them here
# RUN npm install --prefix assets

# Compile the release
RUN mix compile

# create assets directories
RUN mkdir -p priv/static/assets/js priv/static/assets/css

# compile assets
RUN mix assets.deploy

# Changes to config/runtime.exs don't require recompiling the code
COPY config/runtime.exs config/

COPY rel rel
RUN mix release

# make sure the scripts are executable
RUN chmod +x _build/${MIX_ENV}/rel/cuetube/bin/cuetube
RUN chmod +x _build/${MIX_ENV}/rel/cuetube/bin/server
RUN chmod +x _build/${MIX_ENV}/rel/cuetube/bin/migrate

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
  apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"
RUN chown nobody /app

# set runtime ENV
ENV MIX_ENV="prod"

COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/cuetube ./

# Ensure the binaries are executable
RUN chmod +x bin/cuetube bin/server bin/migrate

USER nobody

# If using Phoenix 1.7+, we can use the server script
CMD ["/app/bin/server"]


