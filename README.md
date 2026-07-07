# Mouse Studio

A generic, open-source, native macOS mouse automation platform. Mouse Studio turns a
generic gaming/office mouse into a productivity mouse (MX Master class) by resolving rich
gestures — single, double, long press, chords, and chord + scroll — from a small set of
physical buttons and mapping them to fully configurable actions.

- **Native Swift.** No Hammerspoon, no external runtime.
- **Config-driven.** Zero hardcoded shortcuts; every trigger, condition, and action is JSON.
- **Device-generic.** ANT Esports GM100 is one supported profile; unknown mice fall back to
  generic profiles, and new devices are added as JSON — no engine changes.
- **Event-driven.** No polling; target dispatch latency < 5 ms.

> Status: **Phase 0 scaffold.** The engine is not yet wired. See the design in
> [`docs/TechnicalDesignDocument.md`](docs/TechnicalDesignDocument.md).

## Architecture (layers)

```
Installer  →  GUI App (SwiftUI)  ⇄ IPC ⇄  Background Service  →  Core Engine  →  Config (JSON)
```

| Module | Responsibility |
|--------|----------------|
| `MouseStudioShared`  | Pure models, enums, IPC contracts (no internal deps) |
| `MouseStudioCore`    | Automation engine: EventTap → StateMachine → RuleEngine → ActionDispatcher (no UI) |
| `MouseStudioActions` | Concrete actions: app, clipboard, screenshot, volume, brightness, desktop, keystroke |
| `MouseStudioConfig`  | JSON config store: validation, atomic saves, import/export, backup/restore |
| `MouseStudioService` | Background daemon + XPC IPC server; the only process tapping input |
| `MouseStudioGUI`     | SwiftUI configuration app (rule editor, wizard, live tester, logs) |

## Build

```sh
swift build
swift test
```

Requires Swift 5.9+ and macOS 13+ (target platform: macOS Sequoia, Apple Silicon).

## Roadmap (MVP)

Phase 0 (scaffold) → 1 Core engine → 2 Config + device profiles → 3 Actions →
4 Background service → 5 GUI (rule editor + live tester) → 6 Import/Export + Logs →
7 Installer/Uninstaller. See the TDD for full detail.

## License

MIT — see [`LICENSE`](LICENSE).
