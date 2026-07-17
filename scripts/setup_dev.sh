#!/usr/bin/env bash
set -euo pipefail

# Install dependencies and prepare the local application state.
bundle install
bin/rails db:prepare
(cd frontend && npm ci)
git config core.hooksPath .githooks

echo "Run 'cd frontend && npm run dev' for Vite and 'bundle exec rails server' for the Rails API."
