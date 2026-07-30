# Gym Ghost

Gym Ghost is a lightweight "majestic monolith" scaffold for a gym booking helper app.
It combines a Rails 8 API backend with a React (Vite) frontend served during development from ./frontend.

## Stack
- Ruby 3.4.9, Rails 8 (API mode)
- SQLite (local dev)
- React + TypeScript + Vite frontend (./frontend)
- Tailwind CSS
- RSpec, FactoryBot, Shoulda-matchers for tests
- RuboCop for linting

## Quickstart (local)
1. cd gym-ghost
2. bin/setup           # rails-provided setup script (installs gems, sets up DB if necessary)
3. In terminal A: cd frontend && npm ci && npm run dev   # starts Vite (http://localhost:5173)
4. In terminal B: bundle exec rails server     # starts Rails API (http://localhost:3000)
5. Verify endpoint protection: `curl -i http://localhost:3000/api/v1/schedule` (returns `401 Unauthorized` without a valid bearer token)

## Node & Vite notes
- Node 24.18.0 is required. With nvm, run `nvm install` and `nvm use` from the repository root.
- You do NOT need a global `vite` install. `npm run dev` uses the local devDependency installed by `npm ci`.
- If you prefer a global vite CLI: `npm install -g vite` (not required).

## Native dependencies

`ruby-vips` requires the `libvips` C library. Install it with the appropriate package manager for your platform.

### macOS

```bash
brew install vips
```

### Linux (Debian/Ubuntu)

```bash
sudo apt-get install libvips
```

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

## Notes
- The devcontainer runs ./scripts/setup_dev.sh after creation to install deps automatically.

## Building frontend for Rails
- npm run build (in ./frontend) produces a dist; run `npm run build` then `cp -a frontend/dist/. public/` to let Rails serve the static files in production.

## Testing
- Backend: `bundle exec rspec`
- Frontend: `cd frontend && npm run test`
- Frontend type-check and production build: `cd frontend && npm run build`
- E2E smoke: `cd frontend && npm run test:e2e` (Playwright, requires a running backend)
- Full local CI, including an isolated Docker deployment smoke test: `bin/ci`

Git automatically runs `bin/ci` before each push after `scripts/setup_dev.sh` configures the repository hooks. A failed check blocks the push.

### Live integration tests

Integration tests exercise real downstream APIs without mocking. They are tagged `integration: true` and excluded from `bundle exec rspec` by default.

#### Setup

Copy `.env.example` to `.env` and set the following required environment variables:

```
PARTNER_API_BASE_URL=http://localhost:9000
PARTNER_ACTIVITIES_TOKEN=your-activities-api-token
TEST_PARTNER_AUTH_PARTNER_NAME=TestPartner
TEST_PARTNER_AUTH_BRANCH_ID=6
TEST_PARTNER_AUTH_BRANCH_NAME=Test Branch
TEST_PARTNER_AUTH_TOKEN_BRANCH=TOKEN001
TEST_PARTNER_AUTH_COUNTRY_CODE=CO
TEST_BRANCH_TOKEN=TOKEN001
PARTNER_AUTH_REFERER=https://partner-site.com
PARTNER_AUTH_ORIGIN=https://partner-site.com
TEST_PARTNER_AUTH_EMAIL=your-test-member@partner.com
TEST_PARTNER_AUTH_PASSWORD=your-test-password
```

#### Running integration tests

- Run all integration tests:
  ```
  bundle exec rspec --tag integration
  ```

- Run a specific integration test (override the exclusion with `--tag integration`):
  ```
  bundle exec rspec spec/integration/partner/auth_service_spec.rb --tag integration
  ```

  ```
  bundle exec rspec spec/integration/partner/activities_service_spec.rb --tag integration
  ```

  ```
  bundle exec rspec spec/integration/partner/facilities_service_spec.rb --tag integration
  ```

  ```
  bundle exec rspec spec/integration/partner/booking_service_spec.rb --tag integration
  ```

#### Adding a new integration test

Create a new test file following this convention:

- Location: `spec/integration/<area>/<name>_spec.rb`
- Tag the top-level `describe` with `integration: true`
- Use a `before` block with `skip` when required ENV vars are missing
- Skip gracefully when required ENV is missing

Example structure:

```ruby
RSpec.describe Partner::AuthService, integration: true do
  use_transactional_tests false

  # Skip gracefully when required environment variables are missing
  skip "Set PARTNER_API_BASE_URL and all TEST_PARTNER_AUTH_* vars to run integration tests" unless (
    ENV["PARTNER_API_BASE_URL"].present? &&
      ENV["TEST_PARTNER_AUTH_EMAIL"].present? &&
      ENV["TEST_PARTNER_AUTH_PASSWORD"].present? &&
      ENV["TEST_PARTNER_AUTH_PARTNER_NAME"].present? &&
      ENV["TEST_PARTNER_AUTH_BRANCH_ID"].present? &&
      ENV["TEST_PARTNER_AUTH_BRANCH_NAME"].present? &&
      ENV["TEST_PARTNER_AUTH_TOKEN_BRANCH"].present? &&
      ENV["TEST_PARTNER_AUTH_COUNTRY_CODE"].present? &&
      ENV["PARTNER_AUTH_REFERER"].present? &&
      ENV["PARTNER_AUTH_ORIGIN"].present?
  )

  # ... test implementation
end
```

### E2E smoke test (Playwright)

A Playwright test verifies the user-facing schedule page works end-to-end against a live backend.

#### Running locally

1. Start the Rails server: `bundle exec rails server`
2. Seed the smoke test data:
   ```
   SMOKE_USER_EMAIL=smoke-test@gymghost.test SMOKE_USER_PASSWORD=SmokeTest123! bin/rails db:seed
   ```
3. Install Playwright browsers: `cd frontend && npx playwright install --with-deps chromium`
4. Run the test:
   ```
   cd frontend && PLAYWRIGHT_BASE_URL=http://localhost:3000 SMOKE_USER_EMAIL=smoke-test@gymghost.test SMOKE_USER_PASSWORD=SmokeTest123! npm run test:e2e
   ```

`bin/ci` runs the e2e test automatically against a fresh Docker container — no manual setup needed in CI.

## Devcontainer
- A .devcontainer/ is included. Open the folder in VS Code Remote Containers or Codespaces; postCreateCommand runs setup.

## Deployment (Local Network & Mesh)

1. **Environment Setup**:
   - Copy `.env.example` to `.env`.
   - Set `APP_HOSTS` to your local network IP(s), mesh network IP(s), or local hostname(s) (comma-separated if multiple).
   - Set `SECRET_KEY_BASE` to a long random secret value (generate one with `bin/rails secret` or `openssl rand -hex 64`).
   - Set `ATTR_ENCRYPTED_KEY` to a 32-byte encryption key (e.g., `bin/rails secret` or `openssl rand -hex 32`).

2. **Build and Run Containers**:
   - Run `docker compose up --build -d` to build the production image (which automatically compiles the React frontend into Rails' `public/` directory and runs the app as a non-root user) and start services in detached mode.

3. **Reverse Proxy, Network Access, and TLS (HTTPS)**:
   - Docker Compose binds the container port to loopback only (`127.0.0.1:3000`), protecting it from direct unvetted access.
   - **Troubleshooting Local Network or Mesh Access (`APP_HOSTS` vs Port Binding)**:
     - Setting `APP_HOSTS` to your mesh network IP or local network IP allows Rails to accept requests with that `Host` header (preventing DNS rebinding protection errors). However, because Docker binds port 3000 strictly to `127.0.0.1`, direct connection requests sent from other machines to `http://<your-ip>:3000` will fail or timeout.
     - **To access via Reverse Proxy (Recommended)**: Place a reverse proxy (Nginx, Caddy, Traefik) in front of `127.0.0.1:3000` that listens on your LAN/mesh interface or `0.0.0.0`.
     - **To access directly without a Reverse Proxy (for internal mesh/LAN testing)**: Modify `docker-compose.yml` to expose port 3000 on all interfaces by changing `127.0.0.1:${HOST_PORT:-3000}:3000` to `${HOST_PORT:-3000}:3000` (or `0.0.0.0:${HOST_PORT:-3000}:3000`), ensure `APP_HOSTS` includes your IP, and verify that host firewalls (e.g., UFW) permit inbound traffic on port 3000.
   - **Crucial Proxy Headers**: Because production Rails enforces HTTPS (`config.assume_ssl = true` and `config.force_ssl = true`), your reverse proxy **must** forward the original scheme and host headers (e.g., `X-Forwarded-Proto: https`, `X-Forwarded-For`, and `Host`), or requests will encounter infinite redirect loops or SSL verification errors.
   - **Health Checks**: The unauthenticated `/up` health check endpoint is automatically excluded from SSL redirection and host authorization, allowing local health probes to check `http://127.0.0.1:3000/up`.

4. **Verification and Management**:
   - Check container status: `docker compose ps`
   - View container logs: `docker compose logs -f web`
   - Verify health endpoint: `curl -i http://127.0.0.1:3000/up`

5. **Persistence and Backups**:
   - SQLite production data and Active Job queue state (Solid Queue, Cache, Cable) persist in the named Docker volume `gym_ghost_storage`.
     - **To create a full backup archive** (compresses the entire persistent storage volume into `gym_ghost_storage_backup.tar.gz` in your current directory):
       ```bash
       docker run --rm -v gym_ghost_storage:/volume -v $(pwd):/backup alpine tar czf /backup/gym_ghost_storage_backup.tar.gz -C /volume .
       ```
     - **To restore from a backup archive** (stop the container first, restore files into the volume, then restart):
       ```bash
       docker compose down
       docker run --rm -v gym_ghost_storage:/volume -v $(pwd):/backup alpine tar xzf /backup/gym_ghost_storage_backup.tar.gz -C /volume
       docker compose up -d
       ```
     - **To perform an online hot backup of the primary database** while the app is running:
       ```bash
       docker compose exec web bundle exec rails runner "ActiveRecord::Base.connection.execute('VACUUM INTO \"storage/production_backup.sqlite3\"')"
       ```

6. **Automatic Startup on System Boot**:
   - The container is configured with `restart: unless-stopped` in `docker-compose.yml`, which means it will automatically start whenever the Docker daemon runs.
   - To ensure Docker itself starts automatically on system boot on Ubuntu:
     ```bash
     sudo systemctl enable docker
     ```
   - Once enabled, whenever your server boots up, Docker will start the daemon, and the Gym Ghost container will automatically start up.

## Contributing
- This is a personal project scaffold. Open issues/PRs as needed; include tests for new behavior.

## License
- MIT

## Contact
- Solo project; maintained by the repository owner.
