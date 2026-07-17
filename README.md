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
5. Verify endpoint protection: `curl -i http://localhost:3000/api/v1/hello` (returns `401 Unauthorized` without a valid bearer token)

Node & Vite notes
- Node 24.18.0 is required. With nvm, run `nvm install` and `nvm use` from the repository root.
- You do NOT need a global `vite` install. `npm run dev` uses the local devDependency installed by `npm ci`.
- If you prefer a global vite CLI: `npm install -g vite` (not required).

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
