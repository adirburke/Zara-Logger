# AGENT.md

## What This Module Owns
`Zara-Logger` is the shared logging layer used by most server-side modules.

## Targets And Layout
- Product: `Zara-Logger` (library)
- Target: `Zara-Logger`
- No test target
- Key files:
  - `Sources/Zara-Logger/LogService.swift`
  - `Sources/Zara-Logger/Protocol.swift`
  - `Rakefile`

## Build
From `Zara-Logger/`:

```bash
swift package resolve
swift build --target Zara-Logger
```

## Repo-Specific Gotchas
- Linux + `APP` mode uses private dependency URLs via `GITHUBNAME` and `GITHUBSECRET`.
- Default file log location is hardcoded (`/Users/server/logs/...`) in `LogService.swift`; local runs may need path/permissions.
- No tests protect log format/rotation behavior.

## Editing Rules For Agents
- Treat log keys/levels as compatibility-sensitive for downstream observability.
- Avoid blocking I/O in hot code paths.
- Keep changes additive and verify at least one consumer package still builds.
