# Current Task Context

## Task: z.ai web tools (search + reader) via remote MCP — option A pivot

State: implement — file-side done; **waiting on user git + switch**.

### Goal

Live-web tools in pi via z.ai's remote MCP servers, billed to the GLM Coding
Plan credits (verified included: "MCP tool credit usage = Number of calls ×
Output multiplier"). Key stays exclusively in `~/.pi/agent/auth.json` — read
at connect time by the adapter's command-secret; zero env vars, zero key
copies in git/nix store/managed files. The REST extensions built earlier are
removed (dead code: REST endpoints are pay-per-use open-platform APIs, plan
key gets 1113 there).

### Deliverable — `dots/pi/agent/mcp.json`

```json
{
  "mcpServers": {
    "web-search": {
      "url": "https://api.z.ai/api/mcp/web_search/mcp",
      "auth": "bearer",
      "bearerToken": "!jq -r .zai.key ~/.pi/agent/auth.json"
    },
    "web-reader": {
      "url": "https://api.z.ai/api/mcp/web_reader/mcp",
      "auth": "bearer",
      "bearerToken": "!jq -r .zai.key ~/.pi/agent/auth.json"
    }
  }
}
```

### Decisions (source-verified against pi-mcp-adapter @ ~/.pi/agent/npm)

- `auth: "bearer"` is **required** — `server-manager.ts` resolves
  `bearerToken` only under that auth mode; adapter prefixes `Bearer ` itself.
- `!command` secrets run via `spawnSync(cmd, { shell: true })` → `~` expands,
  stdout is trimmed (≤1 MiB, 10 s, exit 0, non-empty). jq is at
  `/etc/profiles/per-user/alexch/bin/jq` and that dir is in pi's inherited
  PATH (verified in-session) — bare `jq` resolves.
- Adapter never rewrites the source `mcp.json` (prior finding) → safe to
  symlink `dots/pi/agent/mcp.json` via `home.file` like the other pi configs.
- SSE responses: adapter does StreamableHTTP with SSE fallback natively.

### Steps

- [x] Write `dots/pi/agent/mcp.json` (content above). Verified: valid JSON;
      secret command returns a non-empty 49-char key without echoing it.
- [x] `home/dotfiles.nix`: mcp.json line added; both `zai-web-*.ts` lines
      removed; pi-agent comment block extended (symlink-safety, auth.json-only
      key, jq-on-PATH note). File parses (`nix-instantiate --parse`).
- [x] Delete `dots/pi/agent/extensions/zai-web-search.ts` +
      `zai-web-reader.ts` (dir back to modes.ts + modes.test.ts).
- [ ] **User-owned git** (user took git over): `git add -N
      dots/pi/agent/mcp.json` before switch (flake visibility — else silent
      dangling symlink); stage the two `D` deletions + modified files when
      committing (their usual `just stage` flow).
- [ ] User runs: `sudo darwin-rebuild switch --flake .#$(scutil --get LocalHostName)`.
- [ ] Session: `/reload`; check MCP servers connect (mcp gateway status).
      If the servers don't appear after `/reload`, restart the pi session
      (adapter reads mcp.json at startup).
- [ ] Live probes: `web-search` (real query) + `web-reader`
      (https://example.com) via mcp gateway; confirm tool names/namespace.
- [ ] Key-leak audit: key literal absent from repo diff, `dots/pi/agent/mcp.json`
      (contains only the reference, not the key), and store paths;
      `~/.pi/agent/extensions/` back to `modes.ts` only (home-manager removes
      its own dead symlinks).
- [ ] Close out: check boxes, summarize under Findings.

### Risks / stop-and-discuss

- A `tools/call` returning 1113 (plan credits not applying) → stop, report.
- Tool naming/namespace after pivot unknown until probe (adapter may prefix) —
  cosmetic, discovered at verification.
- jq PATH assumption holds for sessions launched from the user's shell
  (always the case here); a clean-env launch would fail the secret command
  with a clear adapter error — acceptable, documented in dotfiles.nix comment.
- MCP context overhead: mitigated by pi-mcp-adapter's lazy loading.

### Findings (history, 2026-09-19)

- Extensions (REST route) worked end-to-end but z.ai returns **1113** on
  `/paas/v4/web_search` + `/reader` (and the coding base
  `/api/coding/paas/v4/*`) — those are open-platform pay-per-use APIs; GLM
  Coding Plan credits don't apply. Extension files + home.file wiring were
  implemented, verified (store paths, parse, key-leak clean), and now get
  removed by this pivot.
- MCP endpoints accept the plan key: `initialize` → HTTP 200 on both
  `api.z.ai/api/mcp/web_search/mcp` and `…/web_reader/mcp`.
- Coding-plan chat base URL (models.dev `zai-coding-plan`):
  `https://api.z.ai/api/coding/paas/v4` — distinct from open-platform
  `/api/paas/v4` and from the MCP bases.
