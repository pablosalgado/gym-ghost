# Gym Ghost

Rails 8.1 app that scrapes a gym's class schedule and auto-reserves classes via Selenium + Firefox.

## Stack

- **Ruby** 3.4.8
- **Rails** 8.1, **SQLite**, **Solid Queue** / **Solid Cache** / **Solid Cable**
- **Hotwire** (Turbo + Stimulus), importmaps
- **Bootstrap 5** (via CDN)
- **Propshaft** (no Sprockets, no Webpack)
- **Selenium WebDriver** + **Firefox** / **geckodriver** (scraping)
- **RSpec** + **FactoryBot** + **Shoulda Matchers**

## Prerequisites

- Ruby 3.4.8 (`.ruby-version`)
- Firefox (latest) + `geckodriver` on PATH
- `bundler`

## Setup

```bash
git clone <repo>
cd gym-ghost

bundle install
bin/rails db:prepare
```

### Credentials

`config/credentials.yml.enc` is git-ignored. You need the `config/master.key`
or `RAILS_MASTER_KEY` environment variable to decrypt it.

Required entries under the `gym` namespace:

```yaml
gym:
  url: https://gym-website.example.com
  username: your-email@example.com
  password: your-password
```

To edit:

```bash
bin/rails credentials:edit
```

## Running

```bash
# Development server
bin/dev

# Or direct
bin/rails server
```

Then open http://localhost:3000.

### Environment variables

| Variable | Default | Description |
|---|---|---|
| `HEADLESS_SCRAPING` | `true` | Set to `false` to show the Firefox window during scraping |
| `RAILS_MASTER_KEY` | — | Decrypts credentials (prod / CI) |

## Testing

```bash
# Full test suite (excludes smoke tests)
bundle exec rspec

# Smoke tests only — hit the real gym website. Requires credentials.
bundle exec rspec spec/smoke --tag smoke --format documentation

# Via Rake
bundle exec rake spec:smoke
```

Smoke tests use the `:es` locale; regular tests use `:en`.

## How it works

1. **Scrape locations** — Crawls the gym site for cities and facilities.
2. **Scrape schedules** — For a given day + facility, scrapes all class times.
3. **Reserve** — Logs in and clicks the reserve button for a specific class.
   - If the class is > 24 h away, the job runs 24 h before.
   - If ≤ 24 h away, it runs immediately.
4. **Statuses** — `programmed` → `reserved` / `failed` / `canceled`.

## Time zone

`America/Bogota` — the app is built for Bogotá, D.C.

## I18n

Default locale is `:es` (Spanish). Translations are in `config/locales/`.
