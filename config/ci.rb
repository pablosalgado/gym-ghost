# Run using bin/ci

CI.run do
  step "Setup", "bin/setup --skip-server"

  step "Style: Ruby", "bin/rubocop"

  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Brakeman code analysis", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
  step "Tests: RSpec", "bundle exec rspec"
  step "Setup: Frontend", "cd frontend && npm ci"
  step "Tests: Frontend", "cd frontend && npm run test"
  step "Build: Frontend", "cd frontend && npm run build"
  step "Smoke test: Docker deployment", "script/verify_docker.sh"
  step "E2E: Install Playwright browsers", "cd frontend && npx playwright install --with-deps chromium"
  step "E2E: Schedule page smoke test", "script/e2e_smoke.sh"

  # Optional: set a green GitHub commit status to unblock PR merge.
  # Requires the `gh` CLI and `gh extension install basecamp/gh-signoff`.
  # if success?
  #   step "Signoff: All systems go. Ready for merge and deploy.", "gh signoff"
  # else
  #   failure "Signoff: CI failed. Do not merge or deploy.", "Fix the issues and try again."
  # end
end
