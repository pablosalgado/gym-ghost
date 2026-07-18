# Gym Ghost Copilot Instructions

## What this app does

Gym Ghost manages gym class schedules and member bookings. It is a solo project — keep the architecture simple and resist premature abstraction.

## Project shape

- Gym Ghost is an API-only Rails application (`config.api_only = true`) with a separate React/Vite frontend in `frontend/`.
- Rails serves the JSON API on port 3000. Routes are versioned under `/api/v1`; match the nested controller module and path (for example, `Api::V1::HelloController` in `app/controllers/api/v1/hello_controller.rb`) and render JSON responses.
- The frontend runs independently through Vite on port 5173 during development. Its React entry point is `frontend/src/main.tsx`, and global styling starts in `frontend/src/index.css` with Tailwind CSS.
- For a non-Docker static deployment, build in `frontend/`, then copy `frontend/dist/.` into `public/`. The production Docker image performs that handoff itself; `docker-compose.yml` runs it with a persistent SQLite volume and requires `APP_HOSTS` and `SECRET_KEY_BASE` in a local `.env` file. Production assumes a TLS-terminating proxy that forwards the original HTTPS scheme.
- Local development and test data use SQLite databases under `storage/`. The test database schema is maintained automatically by `spec/rails_helper.rb`.
- `config/initializers/cors.rb` is only a commented template, and `rack-cors` is not enabled. Configure both deliberately before browser code makes cross-origin calls from Vite to the Rails API.
- Date and time handling rules live in `.github/instructions/date-time.instructions.md`; the app default zone is America/Bogota and the API contract stays UTC.

## File structure

```
app/controllers/api/v1/   — API controllers
app/models/               — ActiveRecord models
config/routes.rb          — API routes
frontend/src/             — React components, hooks, and utilities
spec/requests/            — Request specs
```

## Setup and development

- Install Ruby dependencies and prepare the database with `bin/setup`. Use `bin/setup --reset` only when a database reset is intended.
- Install frontend dependencies with `cd frontend && npm ci`.
- Run the two development processes separately:
  - Rails API: `bundle exec rails server`
  - Vite frontend: `cd frontend && npm run dev`
- The repository and production Docker image use Ruby 3.4.9. Node 24.18.0 is pinned in `.nvmrc` and used by GitHub Actions and the production frontend build.

## Build, test, and lint

- Build the frontend: `cd frontend && npm run build`
- Type-check the frontend: `cd frontend && npm run typecheck`
- Run frontend tests: `cd frontend && npm run test`
- Run the RSpec suite (the test command used by GitHub Actions): `bundle exec rspec`
- Run one RSpec file: `bundle exec rspec spec/path/to/example_spec.rb`
- Run one RSpec example by line: `bundle exec rspec spec/path/to/example_spec.rb:42`
- `bin/ci` runs setup, Ruby linting, security scans, RSpec, frontend dependency installation/tests/build, and an isolated Docker deployment smoke test. The pre-push hook runs `bin/ci` and blocks failed pushes.
- `script/verify_docker.sh` builds Compose with an isolated project, volume, and port 3001; it verifies `/up` and that Rails runs as the non-root `app` user.
- Lint Ruby: `bin/rubocop`. It inherits the `rubocop-rails-omakase` ruleset from `.rubocop.yml`.
- No frontend linter is configured. Frontend quality gates are TypeScript, Vitest, and the production build.

## Automation consistency

- Treat `.github/workflows/ci.yml`, `config/ci.rb`, `.githooks/`, `scripts/setup_dev.sh`, `README.md`, and this file as one validation contract. When changing a runtime version, validation command, or build/deployment step, update every affected surface in the same change.
- `bin/ci` is the complete local equivalent of the GitHub Actions checks. The pre-push hook runs it automatically, so do not weaken or bypass that hook without explicit approval.

## Code and test conventions

- Keep API routes versioned in `config/routes.rb` and controllers under the corresponding `app/controllers/api/v1/` module hierarchy.
- This is a JSON API: controllers inherit from `ApplicationController`, which inherits `ActionController::API`, rather than the full HTML controller stack.
- RSpec is configured with transactional fixtures and verifies partial doubles. `infer_spec_type_from_file_location!` is not enabled, so Rails specs should declare their type explicitly when Rails behavior is needed (for example, `type: :request`).
- The frontend uses strict TypeScript and TSX. Tailwind scans `frontend/index.html` and `frontend/src/**/*.{ts,tsx}`; place class-bearing UI code under those paths.

## Git conventions

- Branch naming: `feature/<short-description>`, `fix/<short-description>`, `chore/<short-description>`. Use lowercase and hyphens, no slashes beyond the prefix.
- Commit messages: imperative mood, max 72 characters for the subject line, reference the issue number when applicable (for example, `Add validation for email field (#12)`).
- Keep PRs focused on a single concern. Do not bundle unrelated changes in the same pull request.
- Rebase on `main` before opening a PR if the branch has fallen behind. Do not merge `main` into a feature branch.
