FROM node:24.18.0-bookworm-slim AS node

FROM ruby:3.4.9-bookworm

COPY --from=node /usr/local /usr/local

RUN apt-get update && \
    apt-get install --no-install-recommends -y build-essential git libsqlite3-dev sudo && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --gid 1000 vscode && \
    useradd --uid 1000 --gid vscode --create-home --shell /bin/bash vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode

USER vscode
WORKDIR /workspace
