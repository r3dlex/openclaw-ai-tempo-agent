# --- Build stage ---
FROM elixir:1.17-slim AS build

RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

ENV MIX_ENV=prod

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy dependency manifests first for layer caching
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod && mix deps.compile

# Copy application source
COPY config config
COPY lib lib

# Compile and build release
RUN mix compile && mix release

# --- Runtime stage ---
FROM debian:bookworm-slim AS runtime

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates libstdc++6 openssl libncurses6 locales python3 && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8
ENV MIX_ENV=prod
ENV PHX_SERVER=true

WORKDIR /app

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/tempo ./

EXPOSE 4000

CMD ["bin/tempo", "start"]
