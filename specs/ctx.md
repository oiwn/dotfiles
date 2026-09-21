# Current Task Context: One-line status footer extension
State: in progress
## Plan
- [x] `modes/index.ts`: always-on footer status — `updateStatus()` currently clears the status in implement mode; make it set a dim `⚙ implement` instead (research `🔍`, plan `🧭` unchanged). The footer extension then always has the current mode via `footerData.getExtensionStatuses()`; the default footer benefits too.
- [x] New `dots/pi/agent/extensions/footer/index.ts` — `/footer` toggle (default **on** at `session_start`), replaces the default multi-segment footer with ONE line:
  `~/code/dotfiles · ↑1.4M ↓108k · 17.2%/1.0M · glm-5.3 · 🧭 plan`
  - pwd: `ctx.cwd`, home abbreviated to `~`, long middles truncated
  - tokens: cumulative `usage.input`/`usage.output` summed over session entries **including** `branch_summary`/`compaction` usage blocks (mirror the default footer so counts survive compaction — not the example's branch-only sum)
  - context: `percent`/`contextWindow`, colorized like pi (>70 warning, >90 error), `(auto)` dropped
  - model: `ctx.model?.id`; mode: statuses map (`modes` key)
  - dropped segments: `R`/`W` (cache read/write), `CH%`, `$` cost — noise for this workflow
  - `formatTokens` (k/M) reimplemented locally; `truncateToWidth` from pi-tui for narrow terminals; reactive via `footerData.onBranchChange` + `tui.requestRender()` (+ re-render on `model_select`/`agent_end`); `dispose` cleanup
- [x] Verify against pi SDK types during implementation: extension access to compaction-aware usage totals and `getContextUsage()` equivalent (`ctx.sessionManager` API surface). Fallback if not exposed: compute context % from the latest assistant `usage` (input+cacheRead+cacheWrite) over `ctx.model.contextWindow`; tokens from `getBranch()` + compaction entries if reachable.
- [x] `home/dotfiles.nix`: wire `.pi/agent/extensions/footer/index.ts` symlink; `git add -N` the new file.
- [x] Verify + hand over
- [x] Follow-up (user feedback round 1): footer polish — (a) spacer line after the status line (`return [line, ""]`) for breathing room before the editor; (b) mode slot moves into the left block immediately after cwd, left-aligned, padded to the widest mode status (visibleWidth-aware: `🔍 research`/`🧭 plan`/`⚙ implement` differ; emoji are width-2) — mode switches must not shift tokens/context/model; (c) right block becomes `ctxTokens · model` where ctxTokens = `ctx.getContextUsage()?.tokens` formatted via formatTokens (`?` when null post-compaction); (d) modes' `Mode: X — description` notification STAYS (user decision). Tests unaffected (no gate logic); hand over switch.: `node --test` green (no gate changes); user runs switch; fresh session — footer is ONE line, segment numbers match the default footer's, `/footer` toggles back, narrow-terminal truncation sane.
## Findings
- API verification resolved better than planned: the extension context exposes `ctx.getContextUsage(): { tokens, contextWindow, percent }` (compaction-aware, nulls post-compaction → render `?/window`). **No fallback computation needed.** Cumulative tokens from `getEntries()` incl. `branch_summary`/`compaction` usage blocks (branch-only sums reset at compaction).
- Default footer decoded (pi `dist/.../components/footer.js`): `↑` cumulative input, `↓` cumulative output, `R` = **cache-read** (not reasoning; `W` = cache-write), `CH%` = latest-request cache-hit rate = cacheRead/(input+cacheRead+cacheWrite), `$` cost, `pct/window` context usage via `session.getContextUsage()` (compaction-aware), `(auto)` compaction mode. >70%/>90% color thresholds.
- `ctx.ui.setFooter((tui, theme, footerData) => …)` replaces the entire footer; `footerData` exposes `getGitBranch()`, `getExtensionStatuses()`, `onBranchChange()`; `ctx.model`, `ctx.sessionManager` already accessible (pi's `custom-footer.ts` example = the pattern).
- User decisions: keep pwd + ↑/↓ tokens + context % + model + mode on one line; `$` irrelevant; CH/R not requested.
## Context
- Files: `dots/pi/agent/extensions/modes/index.ts` (updateStatus only), new `dots/pi/agent/extensions/footer/index.ts`, `home/dotfiles.nix`, this file. `modes.test.ts` untouched (no gate logic changes).
- New file must be git-visible before switch (`git add -N dots/pi/agent/extensions/footer/index.ts`).
- Apply loop is user-run: `sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)`.
## Next
Done — hand over the switch; fresh session: spacer line under the status, mode slot frozen after cwd, ctx tokens before model, mode notification unchanged.
