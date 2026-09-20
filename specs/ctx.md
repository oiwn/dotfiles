# Current Task Context

## Fix: web-search server → web_search_prime (2026-09-20)

State: **plan written — awaiting /mode implement.**

### What was wrong (user caught it)

The search 429s were **not account-side**: `dots/pi/agent/mcp.json` pointed at
the wrong endpoint. I pattern-matched `…/mcp/web_search/mcp` from the reader
URL instead of reading the search MCP docs page. That endpoint exists
(initializes fine — which masked the mistake) but serves the legacy
open-platform tools (`webSearch{Sogou,Quark,Pro,Std}`) → "no resource
package" 429. The GLM Coding Plan search server per current devpack docs
(page's Roo/Kilo tab, user-provided; confirmed via llms-full.txt) is:

- name `web-search-prime`, url `https://api.z.ai/api/mcp/web_search_prime/mcp`
- tool `webSearchPrime` (premium engine)
- endpoint existence re-verified: keyless GET → 1001 auth-wanted, same as
  known-good endpoints

### Plan

- [x] `dots/pi/agent/mcp.json`: `web-search` entry replaced with
      `"web-search-prime"` → `https://api.z.ai/api/mcp/web_search_prime/mcp`
      (same `auth: "bearer"` + `!jq` bearerToken; `web-reader` unchanged).
      Valid JSON; servers now `web-reader` + `web-search-prime`.
- [ ] User: git (their flow) + `sudo darwin-rebuild switch --flake
      .#$(scutil --get LocalHostName)`.
- [x] **Pre-switch probes (raw JSON-RPC, saved a blind switch cycle):**
      initialize → 200 `mcp-web-search-prime v0.0.1` (key accepted);
      `tools/list` → real tool name is **`web_search_prime`** (docs'
      `webSearchPrime` is wrong); params: `search_query` (req),
      `search_domain_filter`, `search_recency_filter`, `content_size`
      (medium/high), `location` (cn/us); **no `count`**, strict schema
      (`additionalProperties: false`). Billable `tools/call` → **live
      results, no 429** — plan credits apply. ✅
- [ ] After switch: `connect web-search-prime` via the adapter (restart
      session if it holds the stale `web-search` registration), probe
      `web_search_prime` through the gateway; re-diff repo vs deployed
      store copy; close out.

### Risks

- None new: same auth mechanism (source-verified in the adapter), same file
  wiring; only URL/name change.
- Stale `web-search` registration in the live session until restart —
  harmless.

## History: z.ai web tools (option A pivot, 2026-09-19 → 09-20)

Goal: live-web tools in pi via z.ai remote MCP servers, billed to GLM Coding
Plan credits; key exclusively in `~/.pi/agent/auth.json` via adapter
command-secret (`!jq -r .zai.key ~/.pi/agent/auth.json` under
`auth: "bearer"`) — zero env vars, zero key copies in git/store.

Done & verified:

- [x] Earlier REST-extension route (search `/paas/v4/web_search`, reader
      `/paas/v4/reader`) built, wired, switched — then removed: REST tools
      are open-platform pay-per-use (plan key gets 1113). Extensions dir back
      to `modes.ts` only.
- [x] `dots/pi/agent/mcp.json` created (web-search + web-reader) + wired via
      `home/dotfiles.nix` (symlink-safe: adapter never rewrites the source).
- [x] Switched (user), deployed store copy verified identical to repo,
      key-leak audit clean (jq-reference only; key never in any managed file).
- [x] Both servers connected with the command-secret auth.
      **web-reader ✅ works** (`web-reader_webReader`: title/content/metadata
      on example.com, plan-credit billing).
      **web-search ❌ 429** — misdiagnosed account-side at the time; actual
      cause: wrong endpoint (see fix above).

### Findings (durable)

- REST `/paas/v4/*` (and `/api/coding/paas/v4/*`): open-platform, pay-per-use
  — plan credits don't apply (1113). MCP is the plan-billed route.
- Coding-plan chat base (models.dev `zai-coding-plan`):
  `https://api.z.ai/api/coding/paas/v4` — distinct from open-platform
  `/api/paas/v4` and from MCP bases.
- Adapter auth (source-verified, pi-mcp-adapter @ ~/.pi/agent/npm):
  `bearerToken` requires `auth: "bearer"`; `!cmd` secrets run via
  `spawnSync(cmd, { shell: true })` — `~` expands; jq resolves via inherited
  PATH (`/etc/profiles/per-user/alexch/bin`).
- Legacy search server tool params (for reference): `search_query` (req),
  `count`, `search_domain_filter`, `search_recency_filter`, `content_size`.
- **Lesson: read the actual docs page for each endpoint — don't infer URLs by
  pattern from sibling services; a wrong-but-existing endpoint initializes
  fine and hides the mistake until first billable call.**
