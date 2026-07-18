# Gym Ghost Copilot Instructions

## What this app does

Gym Ghost manages gym class schedules and member bookings. It is a solo project — keep the architecture simple and resist premature abstraction.

**Design principle**: Gym Ghost is a mobile-first webapp. The primary experience targets phones (portrait, touch). Desktop layouts are a progressive enhancement, not the default. Treat `frontend/index.html`'s viewport meta and `frontend/src/index.css`'s safe-area/dvh usage as the baseline conventions to follow.

## Branch workflow (mandatory)

The `main` branch is protected. **Never commit, push, or open a PR against `main`.**

Before making any change:

1. Check current branch: `git branch --show-current`
2. If on `main`, create a feature branch: `git checkout -b <type>/<short-description>`
3. Make changes, commit, push the branch
4. Open a PR for review

Branch naming:

- `feature/<short-description>` — new functionality
- `fix/<short-description>` — bug fixes
- `chore/<short-description>` — dependencies, tooling, refactors

Commit messages: imperative mood, max 72 characters. Reference the issue number when applicable.

## Worktrees

Always create a worktree for your work. Delete it after the PR merges.

```bash
# Create worktree and branch
git worktree add ../gym-ghost-<branch-name> -b <branch-name>

# After merge, clean up
git worktree remove ../gym-ghost-<branch-name>
```

## Project shape

- Gym Ghost is an API-only Rails application (`config.api_only = true`) with a separate React/Vite frontend in `frontend/`.
- Rails serves the JSON API on port 3000. Routes are versioned under `/api/v1`; match the nested controller module and path (for example, `Api::V1::ScheduleController` in `app/controllers/api/v1/schedule_controller.rb`) and render JSON responses.
- The frontend runs independently through Vite on port 5173 during development. Its React entry point is `frontend/src/main.tsx`, and global styling starts in `frontend/src/index.css` with Tailwind CSS.
- For a non-Docker static deployment, build in `frontend/`, then copy `frontend/dist/.` into `public/`. The production Docker image performs that handoff itself; `docker-compose.yml` runs it with a persistent SQLite volume and requires `APP_HOSTS` and `SECRET_KEY_BASE` in a local `.env` file. Production assumes a TLS-terminating proxy that forwards the original HTTPS scheme.
- Local development and test data use SQLite databases under `storage/`. The test database schema is maintained automatically by `spec/rails_helper.rb`.
- `config/initializers/cors.rb` is only a commented template, and `rack-cors` is not enabled. Configure both deliberately before browser code makes cross-origin calls from Vite to the Rails API.
- Date and time handling rules live in `.github/instructions/date-time.instructions.md`; the app default zone is America/Bogota and the API contract stays UTC.

## File structure

```
gym-ghost/
├── app/
│   ├── controllers/
│   │   ├── api/v1/          # Versioned API controllers
│   │   └── concerns/        # Authentication concern
│   └── models/              # User, Token (bcrypt + SHA256 digest)
├── config/
│   ├── ci.rb                # CI pipeline definition (bin/ci runs this)
│   ├── environments/        # Rails env configs
│   └── initializers/        # App boot config
├── db/migrate/              # ActiveRecord migrations
├── frontend/src/
│   ├── components/          # React components
│   ├── hooks/               # Custom React hooks
│   ├── App.tsx              # Root component
│   └── main.tsx             # Entry point
├── spec/
│   ├── factories/           # FactoryBot factories (users, tokens)
│   ├── models/              # Model specs
│   └── requests/api/v1/     # Request specs (type: :request required)
├── bin/                     # Executables (ci, setup, rubocop, etc.)
├── script/verify_docker.sh  # Docker smoke test
└── scripts/setup_dev.sh     # Devcontainer setup
```

## Where to look

| Task | Location | Notes |
|------|----------|-------|
| Add API endpoint | `app/controllers/api/v1/`, `config/routes.rb` | Namespace under `Api::V1`, route under `/api/v1` |
| Add model | `app/models/`, `db/migrate/` | Add factory in `spec/factories/` |
| Change auth | `app/controllers/concerns/authentication.rb` | Bearer token via `Token.digest` |
| Change error format | `app/controllers/application_controller.rb` | `{ errors: [{ status:, title:, detail: }] }` |
| Frontend component | `frontend/src/components/` | Tailwind CSS, strict TypeScript |
| Frontend hook | `frontend/src/hooks/` | Custom hooks |
| Add test | `spec/requests/api/v1/` or `spec/models/` | Declare `type: :request` or `type: :model` explicitly |
| CI pipeline | `config/ci.rb` | `bin/ci` runs all steps sequentially |
| Docker | `Dockerfile`, `docker-compose.yml` | Multi-stage build: frontend → Rails |

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

## Anti-patterns

- Do not add HTML views or ERB templates — this is API-only.
- Do not use `rescue StandardError` to hide failures.
- Do not commit directly to `main`.
- Do not skip the pre-push CI check.
- Do not add `rack-cors` without explicit allowed origins.
- Do not use wildcard CORS for authenticated endpoints.
- Do not drop tables or remove columns without reversible steps.

## Notes

- **Pre-push hook**: Runs `bin/ci` automatically. Blocks failed pushes. Do not bypass.
- **Pre-commit hook**: Runs RuboCop + TypeScript typecheck.
- **Database**: SQLite for all environments (dev, test, prod). Schema in `db/schema.rb`.
- **Auth flow**: `POST /api/v1/auth` with email+password → returns bearer token. All other endpoints require `Authorization: Bearer <token>`.
- **Schedule**: `GET /api/v1/schedule` returns mock data (hardcoded gym classes in Bogota/Medellin). Partner API integration upcoming.
- **Docker**: Multi-stage build. Frontend built in Node stage, copied to Rails `public/`. Production serves both from port 3000.
- **CI sync**: `.github/workflows/ci.yml`, `config/ci.rb`, `.githooks/`, `scripts/setup_dev.sh`, `README.md`, and this file are one validation contract. Update all affected surfaces when changing build/test steps.
