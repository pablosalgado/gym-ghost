---
applyTo: "**/*.rb,**/*.rake,Rakefile,Gemfile"
---

# Rails and Ruby

- Write idiomatic Ruby that passes the repository's RuboCop Omakase configuration. Favor small, intention-revealing methods and guard clauses over deeply nested conditionals.
- Keep HTTP concerns in versioned API controllers and domain/persistence concerns in models or focused plain Ruby objects. Controllers should coordinate request validation and responses, not contain business workflows.
- Add a service object only when a workflow has multiple meaningful steps, crosses model boundaries, or requires an explicit transaction. Do not add abstraction layers for one-off model operations.
- Preserve the API-only architecture: new endpoints belong under `/api/v1`, use the matching `Api::V1` controller module, and render explicit JSON responses.
- Keep database writes atomic when an operation changes multiple records. Put model invariants in validations or explicit domain methods; avoid callbacks unless they represent a local, unavoidable lifecycle rule.
- Prefer functional techniques for transformations: use pure functions for parsing, mapping, filtering, and calculating; do not mutate method arguments or shared state. Keep I/O, persistence, and external calls at the boundary of the operation.
- Use explicit parameter handling, narrow exception handling, and actionable failure responses. Never rescue `StandardError` merely to hide a failure.
- Define centralized, narrow `rescue_from` handlers in `ApplicationController` for expected API failures, using the JSON error shape `{ errors: [{ status: <http_code>, title: <string>, detail: <string> }] }`. Handle exceptions in individual actions only when they can meaningfully recover; never return raw exception messages to the client.
- Filter parameters through strong params in every controller. Never permit attributes directly from `params` without a permitted list.
- Never run destructive migrations (`drop_table`, `remove_column`, `change_column_default` to a breaking value) without a reversible step or a comment explaining the production impact. Prefer `change_column_null` and backfill patterns over `remove_column`.
- Keep CORS disabled for the built-in frontend: development uses Vite's `/api` proxy and production serves the frontend and API from the same origin. Enable `rack-cors` only for a deliberate cross-origin browser client, with explicit allowed origins from configuration; never use a wildcard origin for authenticated endpoints.
- Add or update an RSpec example for behavior changes. Run `bin/rubocop` for Ruby changes and use the smallest relevant RSpec command.
