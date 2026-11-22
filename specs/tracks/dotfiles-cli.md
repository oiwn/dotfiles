# Track: dotfiles CLI — rmux workspace loader

> **Retired 2026-11-22** — superseded by `specdev ws` + herdr (grammar and
> design in `specs/herdr.md` in `~/code/specdev`). The `dotfiles` binary and
> `tools/dotfiles/` are gone, rmux is out of the config, and per-project
> `.ws.ron` files now use specdev's tree format. This track remains as history
> of the rmux loader.

## Goal

A personal `dotfiles` cargo bin in this repo (`tools/dotfiles/`) that replaces tmuxp: `dotfiles ws load` and `dotfiles ws init` manage rmux workspaces from `.ws.ron` via `rmux-sdk`, then the whole tmux/tmuxp/shim stack is retired.

## State

- **tmux/tmuxp/shim retired from the config**: brew list has `rmux` (declared) + `zellij`; no `tmuxp`, no nix `tmux`, no shim, no `~/.tmux.conf`, no tmuxp/tmux dots or fish wrappers.
- **`tools/dotfiles` crate** (member of the root virtual Cargo workspace — `Cargo.lock`/`target/` at repo root): `ws load [--detach]` + `ws init` via rmux-sdk, e2e-verified (windows/panes/env/focus/idempotency); installed with `just install-tool`.
- **Workspace files**: `.ws.ron` per project (gitignored); template `dots/dotfiles/ws.ron` → `~/.config/dotfiles/ws.ron`; this repo dogfoods `.ws.ron` (session `oiwn-dotfiles`).
- `dots/rmux.conf` (ex `.tmux.conf`) → `~/.config/rmux/rmux.conf`.
- Waiting on user: `just install-tool`, rebuild switch, `brew uninstall tmux tmuxp`, post-switch verification (unit 1 plan).
- rmux 0.10.0 (brew, declared); `rmux-sdk` 0.10.0 must track the brew version.
- 3rd-party skills (`.agents/skills/{specdev,decide,code-health}`) untracked + gitignored (history scrubbed via filter-repo 2026-11-20); only `.agents/skills/dotfiles/` is versioned.

## Decisions

- **Tool named `dotfiles`** — personal, not for distribution; session commands namespaced under `ws` so the root namespace stays free for future workflow commands.
- **Flattened RON schema** — `session`, `environment` (map), `before`, one-line windows (`name`/`focus`/`commands`), optional `panes` as the multi-pane escape hatch. **No `dir` field — windows always open in the loader's current directory** (removed after the daemon-cwd bug: relative dirs resolved against the daemon's own cwd, shipping one project's panes inside another's session). A verbatim tmuxp-schema RON translation (`panes:` → `shell_command:` nesting) was reviewed and rejected as noisy; TOML and YAML were compared and declined — YAML kept zero-migration appeal but RON's flattened one-line windows won on compactness.
- **No `.tmuxp.yaml` fallback** — the tool reads only `.ws.ron`; legacy project files get a one-shot conversion when touched. Moving to rmux + new session-creation methods wholesale.
- **Default template** (`dots/dotfiles/ws.ron`): windows `spec` (`specdev tui`, focused), `agents` (`herdr --session <name>`, no stop command), `code` (`hx`), `cmd1`, `cmd2`, `yazi` 6th; env `RUST_LOG` + `<SESSION>_ENV`; the `pick-a-name` placeholder substitutes into the session field, the herdr command, and the env key in one pass. The derived env key is uppercased and dash-sanitized (`oiwn-dotfiles` → `OIWN_DOTFILES_ENV`) — fish rejects dashes in variable names.
- **`rmux-sdk` daemon IPC, not tmux-shim shelling** — the tool speaks native rmux; `rmux-sdk = "0.10.0"` must match the brew daemon version.
- **Two commands only: `ws load` + `ws init`.** No ls/kill/doctor/convert/save/pickers — rmux already provides listing, diagnostics, killing; we don't duplicate rmux.
- **Attach via `exec rmux attach -t <session>`** as the final step — inherited TTY, no pipes, so the tmuxp hang is structurally impossible.
- **Existing session → attach only** (tmuxp parity via `EnsureSessionPolicy::CreateOrReuse` preceded by a `has_session` check).
- **Install via `cargo install --path tools/dotfiles`** (Justfile recipe); not built through Nix — cargoHash churn and a rebuild per edit kill iteration.
- **Creation is daemon-side and detached**; `load` takes `--detach` (tmuxp `-d` parity) so e2e checks run without a TTY.
- **Harness env is scrubbed** before connecting (`RUSTUP_TOOLCHAIN`, `RUSTUP_TOOLCHAIN_SOURCE`, `CARGO`, `RUSTC` removed from the tool's process) — new sessions snapshot the creating client's env, and agent-launched loads must not bake agent-harness toolchain overrides into interactive shells; also keeps any future agent-spawned daemon clean.

## Units

### 1. Retire tmux / tmuxp / shim

Goal: tmux-free machine; specs reflect reality.

Plan:
- [x] delete `dots/fish/functions/rmuxp.fish`, `dots/fish/functions/tmuxp-init.fish`, `dots/tmuxp/` and their entries in `home/dotfiles.nix`
- [x] `hosts/macbook.nix`: drop brew `tmuxp`; `home/packages.nix`: drop nix `tmux` — also declared brew `rmux` (it was ad-hoc installed, invisible to the config)
- [x] remove the shim: `xdg.configFile."rmux/shim/tmux"` entry in `home/dotfiles.nix` + the `fish_add_path` shim block in `home/terminal.nix`
- [x] rename `dots/.tmux.conf` → `dots/rmux.conf`; keep single `xdg.configFile."rmux/rmux.conf"`; drop `home.file.".tmux.conf"` (fixed a lurking misspelling of "aggressive" so prek/typos passes)
- [x] `specs/overview.md`: multiplexer + `dotfiles` CLI design decisions, `dots/`+`tools/` tree, live-server nudge gotcha → rmux; `README.md` multiplexer line
- [x] remove the realized idea from `specs/ideas.md` ("Tiny native tmuxp loader")
- [x] dogfood: this repo loads its own `.ws.ron` (session `oiwn-dotfiles`) — all windows, focused window correct, stable
- [ ] user: `just install-tool`; rebuild switch; `brew uninstall tmux tmuxp` (leftovers — `cleanup = "none"`); confirm `command -v tmux` finds nothing and `dotfiles ws load` works on a real project
- [ ] reconcile `specs/ctx.md` trial section (decide: still report the attach bug upstream? — user's call; repro in the Notes below)

Notes: upstream repro if reported — `script -q /dev/null sh -c 'timeout 3 tmux attach -t <session> > /dev/null 2>&1; echo $?'` → rmux: no output, exit 124; real tmux: UI renders to the pty. Env: rmux 0.10.0, macOS, fish, tmuxp 1.76/libtmux 0.62. Suggestion: `attach-session` should open `/dev/tty` when stdin/stdout aren't TTYs, or fail fast instead of blocking.

## Acceptance

Run at every checkpoint:
- [x] `cargo fmt --all --check && cargo build --locked` (repo root)
- [x] `cargo test --locked` (repo root)
- [x] `cargo clippy --all-targets --locked -- -D warnings` (repo root)
- [x] `prek run --all-files`
- [x] `specdev check`

Unit-specific:
- [ ] Unit 1 e2e: `dotfiles ws load --detach` on a converted workspace, then `rmux list-windows -t <session>` shows the expected windows in order (human check: attach renders fullscreen with commands already running) — agent-verified via `list-windows`/`capture-pane`; the fullscreen attach itself is the user's check at final handover
- [ ] Unit 3 e2e: after the user's switch, `command -v tmux` returns nothing; `dotfiles ws load` works on a real project

## Learned

- **Window/pane indexes are config-dependent** — this setup's `rmux.conf` sets `base-index 1` / `pane-base-index 1`, so the SDK's 0-based examples (`session.pane(0, 0)`) fail with `InvalidTarget`. The tool discovers real indexes at runtime: `find_panes().session(..)` after creation, and `Window::panes()` targets for later windows. No index math anywhere.
- **Initial pane needs a readiness gate** — commands sent immediately after `ensure_session` were swallowed (shell not yet booted); later windows were fine. Fix: `pane.wait_for_load_state(TerminalLoadState::Quiet).timeout(5s)` before sending (best-effort, warns and continues on timeout). No sleeps needed.
- **SDK shape notes**: `rmux.ensure_session(builder)` is the future (the builder is not `IntoFuture`); `NewWindowBuilder` from `session.new_window_with()` IS `IntoFuture` (`.await` gives the `Window`). `Pane`/`Window` handles are `Clone`.
- **rmux-sdk 0.10.0 ↔ daemon 0.10.0** work together; the typed-IPC version pin is real and needs a matching bump when brew upgrades rmux.
- Load is idempotent: an existing session is attached untouched (no re-sends) — verified via double `--detach` load.
- **Focus selection verified deterministic**; one transient on the very first cold-boot of the TUI apps never reproduced — likely a daemon-side cold-start race, not the tool's flow.
- **filter-repo incident (2026-11-20)**: the batch was staged (`git add --all`) but not committed when `git filter-repo` ran — its hard reset to the rewritten HEAD discarded all staged work; ignored files survived. Fully rebuilt from the session. Lesson: history surgery only on a committed tree; stage ≠ commit.
- The renamed `dots/rmux.conf` carried a pre-existing misspelling of "aggressive" — prek/typos caught it on the rename; fixed.
- **`<session>_ENV` keys must be sanitized** (hit 2026-11-20): a session name with a dash (`oiwn-dotfiles`) produces an invalid fish/bash variable name, and every pane's fish startup spams `set: invalid variable name` through nix-darwin's foreign-env plugin. `ws init` now uppercases and dash-sanitizes the derived key; the workspaces env map otherwise passes through verbatim.
- **Relative window dirs resolve against the daemon's cwd, not the client's** (hit 2026-11-21): `.ws.ron` `dir: "./"` shipped dotfiles-repo shells inside a `specdev`-named session (daemon started Nov 15 in the dotfiles repo — `--config-cwd` in `ps`). Fix: the `dir` field was removed entirely; the tool passes `current_dir()` (absolute, client-resolved) to every window. E2E now asserts `#{pane_current_path}`.
- **The daemon stamps its base env on every pane it forks** (hit 2026-11-21): the Nov 15 daemon carried agent-harness vars (`RUSTUP_TOOLCHAIN`, `CARGO`) from its start context into every pane — client-side scrubbing alone can't reach that. Remedy: `rmux set-environment -g -u <VAR>` per var (verified with a fork-probe: `sleep` process env clean after). A daemon restarted from a clean shell is clean from birth; the tool's scrub keeps agent-spawned daemons clean too.

## Checkpoints

- 2026-11-21 — Windows always load in client PWD (dir field removed, daemon-cwd bug fixed — panes were landing in the daemon's start dir); harness env scrubbed client-side + daemon global env cleaned via set-environment -g -u; 8 tests, cwd+env e2e-verified
- 2026-11-20 — Env-key sanitization: <session>_ENV renders uppercased/dash-free (fish rejects dashes in var names — every pane's fenv startup errored); README gains the install-tool bootstrap step; 7 tests, e2e re-verified with clean fish startup
- 2026-11-20 — Rebuild after filter-repo incident (staged-not-committed batch lost to the hard reset): crate + template + configs + specs regenerated from session; new default template (spec/agents/code/cmd1/cmd2/yazi); acceptance green from root; full e2e re-verified
- 2026-11-20 — Unit 3 (agent side): tmux/tmuxp/shim retired from config — rmux declared in brews, dots/rmux.conf renamed, fish wrappers + tmuxp dots deleted, specs/README updated, repo dogfoods .ws.ron; user apply steps pending
- 2026-11-20 — Unit 2: ws init (scaffold from managed dots/dotfiles/ws.ron template, placeholder substitutes session/env-key/herdr, all paths e2e-verified) + xdg.configFile symlink, just install-tool
- 2026-11-20 — Unit 1: tools/dotfiles crate + ws load via rmux-sdk (flattened RON schema, windows/panes/env/focus e2e-verified, idempotent, parse tests, fmt/test/clippy/prek green)
