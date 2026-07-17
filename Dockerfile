# syntax=docker/dockerfile:1

FROM node:24.18.0-bookworm-slim AS frontend-build

WORKDIR /frontend

COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

COPY frontend/ ./
RUN npm run build

FROM ruby:3.4.9-slim-bookworm

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_WITHOUT="development:test"

WORKDIR /app

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential gosu libsqlite3-dev && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd --system app && useradd --system --gid app --create-home app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . ./
COPY --from=frontend-build /frontend/dist/ ./public/
COPY --chmod=755 bin/docker-entrypoint /usr/local/bin/docker-entrypoint
RUN chown -R app:app /app

ENTRYPOINT ["docker-entrypoint"]

EXPOSE 3000

CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
