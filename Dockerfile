# =============================================================================
# Stage 1: Elixir Backend Build
# =============================================================================
FROM elixir:1.17-otp-27-alpine AS backend-build

RUN apk add --no-cache build-base git curl

WORKDIR /app/backend

COPY backend/mix.exs backend/mix.lock* ./
RUN mix local.hex --force && mix local.rebar --force
RUN MIX_ENV=prod mix deps.get --only prod
RUN MIX_ENV=prod mix deps.compile

COPY backend/config config/
COPY backend/lib lib/

RUN MIX_ENV=prod mix compile
RUN MIX_ENV=prod mix release

# =============================================================================
# Stage 2: Elixir Backend Runtime
# =============================================================================
FROM alpine:3.20 AS backend

RUN apk add --no-cache libstdc++ openssl ncurses-libs curl

WORKDIR /app

COPY --from=backend-build /app/backend/_build/prod/rel/tempo ./
COPY data/ /app/data/

ENV PHX_SERVER=true
ENV PORT=4000

EXPOSE 4000

CMD ["bin/tempo", "start"]

# =============================================================================
# Stage 3: Angular Dashboard Build
# =============================================================================
FROM node:22-alpine AS dashboard-build

WORKDIR /app/dashboard

COPY dashboard/package.json dashboard/package-lock.json* ./
RUN npm ci --ignore-scripts

COPY dashboard/ ./
RUN npm run build

# =============================================================================
# Stage 4: Angular Dashboard Runtime (nginx)
# =============================================================================
FROM nginx:alpine AS dashboard

COPY --from=dashboard-build /app/dashboard/dist/tempo-dashboard/browser /usr/share/nginx/html

# nginx config to proxy API calls to backend
RUN printf 'server {\n\
  listen 80;\n\
  root /usr/share/nginx/html;\n\
  index index.html;\n\
  location /api/ {\n\
    proxy_pass http://backend:4000;\n\
    proxy_set_header Host $host;\n\
    proxy_set_header X-Real-IP $remote_addr;\n\
  }\n\
  location / {\n\
    try_files $uri $uri/ /index.html;\n\
  }\n\
}\n' > /etc/nginx/conf.d/default.conf

EXPOSE 80
