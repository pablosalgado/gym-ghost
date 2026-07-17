---
applyTo: "frontend/**/*.ts,frontend/**/*.tsx"
---

# TypeScript and React

- Keep TypeScript strict. Model API payloads with interfaces or type aliases, treat `response.json()` as `unknown`, and validate untrusted data with type guards before using it. Do not use `any` or unsafe type assertions to silence errors.
- Use function components and hooks. Keep components focused on one UI responsibility; extract a component or a pure helper when it clarifies a distinct concern, not simply to reduce file length.
- Keep state immutable. Prefer pure functions for derived values, formatting, mapping, filtering, and validation; isolate fetching, storage, and other effects inside hooks or event handlers.
- Handle asynchronous UI states deliberately: represent loading, success, and failure, prevent updates after cancellation or unmount, and surface user-safe errors rather than raw transport errors.
- Keep data fetching in custom hooks or small service modules. Avoid inline `useEffect` fetches in components; prefer a single source of truth for each API call so loading/error states and caching are handled once.
- Ensure `tsconfig.json` has `"strict": true` (or equivalent flags) and do not introduce `// @ts-ignore` or `@ts-expect-error` comments to silence type errors.
- Call Rails through relative `/api/v1/...` URLs. Vite proxies `/api` to Rails in local development, while production serves both from the same origin. Do not add browser CORS workarounds for this path.
- Use `import type` for type-only imports and preserve the existing Tailwind approach. Place class-bearing code under `frontend/src` so it is included by Tailwind's content scan.
- Validate frontend changes with `cd frontend && npm run typecheck` and `npm run test`; `npm run build` includes the type check.
