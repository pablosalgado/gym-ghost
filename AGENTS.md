# Project conventions

## Stack
- Ruby on Rails 8.1, Ruby 3.4.8 (via mise)
- SQLite, Solid Queue/Cache/Cable
- Hotwire (Turbo + Stimulus), importmaps
- Bootstrap (via CDN/gem, NOT Tailwind)
- RSpec + FactoryBot + Shoulda Matchers
- Propshaft (no Sprockets or Webpack)

## Testing
- Prefer `let` / `let!` over instance variables in specs
- Use FactoryBot factories, not fixtures
- Wrap locale-sensitive specs in `I18n.with_locale(:en)`
- Smoke specs tagged `:smoke` use `:es` locale

## Code style
- No comments in production code
- Prefer short, single-purpose methods
- Use `Time.zone` helpers over raw `Time`

## Git
- Protected `main` — work in feature branches, PR via GitHub
- No commits directly to any branch
- Branch naming: `fix/short-description`, `feat/short-description`, `chore/short-description`

## GitHub (solo project with AI-assisted issue tracking)
- AI creates issues proactively — tech debt, UX paper cuts, potential bugs, refactoring opportunities
- Title: descriptive, minimal; body: short context, no template
- No labels, milestones, or assignees
- PRs reference issues when applicable: `Closes #N` or `Refs #N` in body
- PR title: concise, conventional-commit style (e.g., `Fix: description`, `Add: description`)
- PR body: auto-generated bullet summary from the diff
- Open as ready (not draft); skip labels and reviewers
- Pre-PR: `bundle exec rspec` must pass, smoke test must pass
- Workflow: fix an issue → show the result to me for review → only then open a PR on my go-ahead
