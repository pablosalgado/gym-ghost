---
applyTo: "spec/**/*_spec.rb"
---

# RSpec

- Use RSpec exclusively; do not add Minitest tests or a `test/` directory.
- Require `rails_helper` for Rails-integrated specs. Declare the spec type explicitly (for example, `type: :request` or `type: :model`) because type inference from file location is disabled.
- Test observable behavior and contracts. Request specs should assert meaningful status codes and JSON payloads; model specs should cover validations, invariants, and public behavior.
- Keep examples independent and deterministic. The suite uses transactional fixtures, and partial doubles are verified. Build only the records necessary for the behavior under test.
- Prefer FactoryBot for persisted records when factories exist; add a focused factory only when it removes repeated, meaningful setup.
- Add regression coverage with the behavior change and run the narrowest relevant example first, then `bundle exec rspec` when practical.
