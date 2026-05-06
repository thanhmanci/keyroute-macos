# Contributing

Thanks for considering a contribution to KeyRoute.

## Local Setup

```sh
swift build
swift run keyroute-selftest
scripts/build-app.sh
```

## Pull Request Checklist

- Keep the app native and lightweight.
- Avoid adding external dependencies unless the tradeoff is clear.
- Run `swift build` and `swift run keyroute-selftest`.
- Update `README.md` or `docs/wiki/` when user-facing behavior changes.
- Keep generated artifacts such as `.build/` and `dist/` out of commits.

## Coding Notes

- `KeyRouteKit` should stay platform-light and testable.
- `KeyRoute` owns AppKit, Accessibility, and menu bar UI behavior.
- `keyroutectl` should remain a small manual testing utility.
