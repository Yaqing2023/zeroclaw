# Railway-compatible Dockerfile (no BuildKit cache mounts)

# ── Stage 1: Build ────────────────────────────────────────────
FROM rust:latest AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# 1. Copy manifests to cache dependencies
COPY Cargo.toml Cargo.lock ./
COPY crates/robot-kit/Cargo.toml crates/robot-kit/Cargo.toml
RUN mkdir -p src benches crates/robot-kit/src \
    && echo "fn main() {}" > src/main.rs \
    && echo "fn main() {}" > benches/agent_benchmarks.rs \
    && echo "pub fn placeholder() {}" > crates/robot-kit/src/lib.rs
RUN cargo build --release --locked
RUN rm -rf src benches crates/robot-kit/src

# 2. Copy source
COPY src/ src/
COPY benches/ benches/
COPY crates/ crates/
COPY firmware/ firmware/
COPY web/ web/
RUN mkdir -p web/dist && \
    if [ ! -f web/dist/index.html ]; then \
      printf '%s\n' \
        '<!doctype html>' \
        '<html lang="en">' \
        '  <head>' \
        '    <meta charset="utf-8" />' \
        '    <meta name="viewport" content="width=device-width,initial-scale=1" />' \
        '    <title>ZeroClaw Dashboard</title>' \
        '  </head>' \
        '  <body>' \
        '    <h1>ZeroClaw Dashboard Unavailable</h1>' \
        '    <p>Frontend assets are not bundled in this build.</p>' \
        '  </body>' \
        '</html>' > web/dist/index.html; \
    fi
RUN cargo build --release --locked && \
    cp target/release/zeroclaw /app/zeroclaw && \
    strip /app/zeroclaw
# Prepare runtime directory (config.toml created by entrypoint)
RUN mkdir -p /zeroclaw-data/.zeroclaw /zeroclaw-data/workspace && \
    chown -R 65534:65534 /zeroclaw-data

# Copy workspace with skills
COPY workspace/ /zeroclaw-data/workspace/

# ── Stage 2: Production Runtime (trixie for glibc 2.39+) ─────
FROM debian:trixie-slim AS release

# Cache bust - this ARG must be used to invalidate cache
ARG CACHEBUST=12
RUN echo "Cache bust: $CACHEBUST" && apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    jq \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 22 LTS for moltspay
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install moltspay globally
RUN npm install -g moltspay@latest

COPY --from=builder /app/zeroclaw /usr/local/bin/zeroclaw
COPY --from=builder /zeroclaw-data /zeroclaw-data
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Fix permissions: COPY doesn't preserve ownership, create .moltspay dir
RUN mkdir -p /zeroclaw-data/.moltspay && \
    chown -R 65534:65534 /zeroclaw-data

ENV ZEROCLAW_WORKSPACE=/zeroclaw-data/workspace
ENV ZEROCLAW_CONFIG_DIR=/zeroclaw-data/.zeroclaw
ENV HOME=/zeroclaw-data
ENV ZEROCLAW_GATEWAY_PORT=8080
ENV ZEROCLAW_MODEL=claude-sonnet-4-5-20250929
# ZEROCLAW_PAIRED_TOKENS is set by MoltsPay during provisioning
# Discord config via env vars:
#   ZEROCLAW_DISCORD_BOT_TOKEN - Discord bot token
#   ZEROCLAW_DISCORD_GUILD_ID - Optional guild/server ID
#   ZEROCLAW_DISCORD_ALLOWED_USERS - Comma-separated user IDs (empty = open)
#   ZEROCLAW_DISCORD_MENTION_ONLY - true/false (default: false)

WORKDIR /zeroclaw-data
# Note: No USER directive - entrypoint starts as root, fixes volume permissions,
# then drops to 65534:65534 via gosu for security
EXPOSE 8080
ENTRYPOINT ["docker-entrypoint.sh", "zeroclaw"]
CMD ["daemon"]
