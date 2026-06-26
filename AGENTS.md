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

## Workflow (mandatory, in order)

Phases:
- **Discussion** — Questions, proposals, "what do you think?" → conversation only, no issues or branches.
- **Work** — An explicit go-ahead ("yes, implement it", "go ahead", "let's do it", or a direct instruction to build something). This triggers the sequence below.

When in **work** phase, follow this exact order:

1. **Issue first** — Create a GitHub issue before writing any code. Issues are descriptive, minimal, and actionable.
2. **Branch second** — Create a feature branch before editing any file. Never edit on `main`.
3. **Work third** — Implement on the branch, committing as you go.
4. **Show** — Present the result for review.
5. **PR on go-ahead** — Only open a PR when I explicitly say so.

## Git
- Never commit or edit on `main`. Always branch first, before touching any file. If you land on `main` when a task starts, the first step is `git checkout -b <branch>`.
- Branch naming: `fix/short-description`, `feat/short-description`, `chore/short-description`

## GitHub issues
- No labels, milestones, or assignees
- Title: descriptive, minimal; body: short context, no template

## Pull requests
- Reference issues: `Closes #N` or `Refs #N` in body
- Title: concise, conventional-commit style (e.g., `Fix: description`, `Add: description`)
- Body: auto-generated bullet summary from the diff
- Open as ready (not draft); skip labels and reviewers
- Pre-PR: `bundle exec rspec` must pass, smoke test must pass
