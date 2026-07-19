# Gym Ghost

Gym Ghost is a lightweight "majestic monolith" scaffold for a gym booking helper app.
It combines a Rails 8 API backend with a React (Vite) frontend served during development from ./frontend.

Stack
- Ruby 3.4.9, Rails 8 (API mode)
- SQLite (local dev)
- React + TypeScript + Vite frontend (./frontend)
- Tailwind CSS
- RSpec, FactoryBot, Shoulda-matchers for tests
- RuboCop for linting

Quickstart (local)
1. cd gym-ghost
2. bin/setup           # rails-provided setup script (installs gems, sets up DB if necessary)
3. In terminal A: cd frontend && npm ci && npm run dev   # starts Vite (http://localhost:5173)
4. In terminal B: bundle exec rails server     # starts Rails API (http://localhost:3000)
5. Verify endpoint protection: `curl -i http://localhost:3000/api/v1/schedule` (returns `401 Unauthorized` without a valid bearer token)

Node & Vite notes
- Node 24.18.0 is required. With nvm, run `nvm install` and `nvm use` from the repository root.
- You do NOT need a global `vite` install. `npm run dev` uses the local devDependency installed by `npm ci`.
- If you prefer a global vite CLI: `npm install -g vite` (not required).

### Accessing Vite from other devices on the LAN

The Vite dev server binds to `0.0.0.0` by default, so devices on the same network (phones, tablets, other laptops) can reach it.

1. Find your machine's LAN IP:
   - macOS: `ipconfig getifaddr en0` (Wi-Fi) or `ipconfig getifaddr en1`
   - Linux: `hostname -I`
2. Open `http://<LAN_IP>:5173` on the other device.
3. API calls are proxied through Vite to the Rails API on port 3000 — no extra CORS config needed.

To override the bind address, set `VITE_DEV_HOST` in `frontend/.env`:
```
VITE_DEV_HOST=192.168.1.100   # bind to a specific IP
```
Set it to `localhost` to restrict to the local machine only.

Notes
- The devcontainer runs ./scripts/setup_dev.sh after creation to install deps automatically.

Building frontend for Rails
- npm run build (in ./frontend) produces a dist; run `npm run build` then `cp -a frontend/dist/. public/` to let Rails serve the static files in production.

Testing
- Backend: `bundle exec rspec`
- Frontend: `cd frontend && npm run test`
- Frontend type-check and production build: `cd frontend && npm run build`
- Full local CI, including an isolated Docker deployment smoke test: `bin/ci`

Git automatically runs `bin/ci` before each push after `scripts/setup_dev.sh` configures the repository hooks. A failed check blocks the push.

### Smoke tests (live integration tests)

Smoke tests exercise real downstream APIs without mocking. They are tagged `smoke: true` and excluded from `bundle exec rspec` by default.

#### Setup

Copy `.env.example` to `.env` and set the following required environment variables:

```
PARTNER_API_BASE_URL=http://localhost:9000
TEST_PARTNER_AUTH_PARTNER_NAME=TestPartner
TEST_PARTNER_AUTH_BRANCH_ID=6
TEST_PARTNER_AUTH_BRANCH_NAME=Test Branch
TEST_PARTNER_AUTH_TOKEN_BRANCH=TOKEN001
TEST_PARTNER_AUTH_COUNTRY_CODE=CO
TEST_PARTNER_AUTH_REFERER=https://partner-site.com
TEST_PARTNER_AUTH_ORIGIN=https://partner-site.com
TEST_PARTNER_AUTH_EMAIL=your-test-member@partner.com
TEST_PARTNER_AUTH_PASSWORD=your-test-password
```

#### Running smoke tests

- Run all smoke tests:
  ```
  bundle exec rspec --tag smoke
  ```

- Run a specific smoke test (override the exclusion with `--tag smoke`):
  ```
  bundle exec rspec spec/smoke/partner/auth_service_smoke_spec.rb --tag smoke
  ```

#### Adding a new smoke test

Create a new test file following this convention:

- Location: `spec/smoke/<area>/<name>_spec.rb`
- Tag the top-level `describe` with `smoke: true`
- Use a `before` block with `skip` when required ENV vars are missing
- Skip gracefully when required ENV is missing

Example structure:

```ruby
RSpec.describe Partner::AuthService, smoke: true do
  use_transactional_tests false

  # Skip gracefully when required environment variables are missing
  skip "Set PARTNER_API_BASE_URL and all TEST_PARTNER_AUTH_* vars to run smoke tests" unless (
    ENV["PARTNER_API_BASE_URL"].present? &&
    ENV["TEST_PARTNER_AUTH_EMAIL"].present? &&
    ENV["TEST_PARTNER_AUTH_PASSWORD"].present? &&
    ENV["TEST_PARTNER_AUTH_PARTNER_NAME"].present? &&
    ENV["TEST_PARTNER_AUTH_BRANCH_ID"].present? &&
    ENV["TEST_PARTNER_AUTH_BRANCH_NAME"].present? &&
    ENV["TEST_PARTNER_AUTH_TOKEN_BRANCH"].present? &&
    ENV["TEST_PARTNER_AUTH_COUNTRY_CODE"].present? &&
    ENV["TEST_PARTNER_AUTH_REFERER"].present? &&
    ENV["TEST_PARTNER_AUTH_ORIGIN"].present?
  )

  # ... test implementation
end
```

Devcontainer
- A .devcontainer/ is included. Open the folder in VS Code Remote Containers or Codespaces; postCreateCommand runs setup.

Deployment (small VPS)
1. Copy `.env.example` to `.env`, set `APP_HOSTS` to the public hostname (comma-separate multiple hostnames), and set `SECRET_KEY_BASE` to a long random value (generate one with `bin/rails secret`).
2. Run `docker compose up --build -d`.
3. Put a TLS-terminating reverse proxy in front of the host's port 3000. Compose binds that port to loopback only; the proxy must forward the original HTTPS scheme.

The production image builds the Vite frontend and copies it to Rails' `public/` directory. SQLite data persists in the named `gym_ghost_storage` Docker volume. Back up that volume before relying on it for production data.

Contributing
- This is a personal project scaffold. Open issues/PRs as needed; include tests for new behavior.

License
- MIT

Contact
- Solo project; maintained by the repository owner.
