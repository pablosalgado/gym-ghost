---
applyTo: "frontend/**/*.ts,frontend/**/*.tsx,**/*.rb"
---

# Date and time

- Store and transmit instants as UTC ISO 8601 strings; the JSON API contract stays UTC.
- Derive "today", windows, and calendar arithmetic inside an explicit IANA zone via the `frontend/src/lib/date-time.ts` helpers — never via host-local `Date` getters.
- Never hand-roll UTC offsets; never add 86 400 000 ms for a "day"; use IANA zone names only.
- On the Rails side use `Time.zone` / `ActiveSupport::TimeWithZone`, never bare `Time.now` arithmetic; serialize UTC ISO 8601.
- Format for humans only at the edge with `Intl.DateTimeFormat` and the active i18n locale.
- Tests pin explicit zones — never depend on the host `TZ`.
- The app default zone is `America/Bogota`, held in one constant (`DEFAULT_TIME_ZONE`); when a per-user or per-facility zone setting arrives, it replaces the constant at call sites, not inside the helpers.
- Colombia has no DST; when a DST-observing zone is added, re-audit arithmetic assumptions before reusing them.
