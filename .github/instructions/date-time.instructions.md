---
applyTo: "frontend/**/*.ts,frontend/**/*.tsx,**/*.rb"
---

# Date and time

- Store and transmit instants as UTC ISO 8601 strings; the JSON API contract stays UTC.
- Derive "today", windows, and calendar arithmetic inside an explicit IANA zone via the `frontend/src/lib/date-time.ts` helpers — never via host-local `Date` getters.
- Never hand-roll UTC offsets; never add 86 400 000 ms for a "day"; use IANA zone names only.
- Backend controllers operate in UTC: use `Time.zone` / `ActiveSupport::TimeWithZone` for date derivation and `Time.current` for comparisons, never bare `Time.now`. Keep arithmetic in UTC — `start_time - 24.hours` instead of converting to a local zone first. Serialize UTC ISO 8601.
- `lib/holiday_service.rb` is the single backend location that resolves dates in a named zone (`America/Bogota`); it holds its own `DEFAULT_TIME_ZONE` constant for that purpose.
- Format for humans only at the edge with `Intl.DateTimeFormat` and the active i18n locale.
- Tests pin explicit zones — never depend on the host `TZ`.
