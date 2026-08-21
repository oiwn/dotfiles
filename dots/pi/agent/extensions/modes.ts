/**
 * Modes extension — three working modes for disciplined sessions.
 *
 * research   read-only exploration: understand the problem, survey related
 *            materials, discuss with the user before anything else.
 *            edit/write disabled; bash limited to read-only commands.
 * plan       research + specdev planning: edit/write allowed only under
 *            specs/**; bash still read-only.
 * implement  full access (stock pi behavior — the default).
 *
 * Mechanism (modeled on pi's examples/extensions/plan-mode, minus its
 * plan-execution machinery — specdev's specs/ctx.md owns planning state):
 * - tool swap via pi.setActiveTools() with save/restore
 * - bash allowlist + specs path gate via pi.on("tool_call")
 * - per-mode banner injected on before_agent_start (hidden, tagged, and
 *   filtered from context once stale after a mode switch)
 * - mode persisted via pi.appendEntry() and restored on session_start
 *
 * Tools not managed here (MCP tools, other extensions' tools) stay active in
 * every mode; only built-in edit/write are ever swapped out. The banners below
 * are the single source of mode instructions — no separate skill. The context
 * filter keeps only the most recent current-mode banner so instructions are
 * delivered every turn without accumulating.
 *
 * Usage: /mode [research|plan|implement] (picker when no arg), Shift+Tab or
 * Ctrl+Alt+M to cycle. Shift+Tab requires keybindings.json to move
 * app.thinking.cycle off shift+tab (here: ctrl+alt+t). Footer shows the active
 * mode. The bash allowlist is a heuristic guardrail, not a sandbox. It is
 * quoting-aware: literal metacharacters inside quotes or after a backslash
 * (grep "a\|b", sed -n '1p;2p', echo "x; y") are masked before the
 * structural checks, while $( ) and backticks stay visible even inside
 * double quotes because the shell executes them there.
 */

import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { resolve, sep } from "path";

const MODES = ["research", "plan", "implement"] as const;
type Mode = (typeof MODES)[number];

const MODE_DESCRIPTIONS: Record<Mode, string> = {
	research: "read-only exploration: understand the problem, survey materials, discuss with the user",
	plan: "read-only exploration + specs/** planning (specdev)",
	implement: "full access",
};

const MODE_BANNERS: Record<Mode, string | undefined> = {
	research: `[MODE: research]
You are in RESEARCH mode: reach a correct understanding of the problem and agree on clear goals — before any plan or code.
- Analyze the situation in general: what is being asked, what the constraints are, who/what it affects. Do not tunnel on symptoms or jump to solutions.
- Survey the related materials: relevant code and specs, docs, web (pginf, curl GET).
- Formalize demands into explicit requirements; establish clear goals and success criteria for a proper solution.
- Distinguish verified facts from assumptions; surface open questions.
edit/write are disabled; bash is limited to read-only commands. Conclude by presenting the problem as you understand it, the requirements, and proposed goals — then discuss with the user until you agree. Only after agreement switch: /mode plan.`,
	plan: `[MODE: plan]
You are in PLAN mode: turn the agreed understanding into a concrete plan — no implementation yet.
- Follow the specdev skill: read specs/overview.md and specs/ctx.md; write the plan as checkboxes in specs/ctx.md (surgical edits, specs/** only).
- Plan the solution direction validated in research. If you discover the problem was misunderstood, stop and discuss — return to research rather than planning the wrong thing.
- Keep the plan concise and decision-relevant: ordered steps, choices, risks.
edit/write are limited to specs/**; bash stays read-only. Present the plan, get explicit user agreement, then switch: /mode implement.`,
	implement: `[MODE: implement]
You are in IMPLEMENT mode: execute the agreed plan.
- Work through the specs/ctx.md checkboxes in order; tick each as completed ([ ] → [x]).
- Stay in scope: deviations from the agreed plan are discussed with the user first, never improvised.
- Verify your changes; report what changed and what remains.
Full tools available. When all steps are done, summarize and stop for review.`,
};

// Built-in tools swapped out in research mode. Everything else stays active.
const RESEARCH_DISABLED_TOOLS = new Set(["edit", "write"]);

interface ModesState {
	mode: Mode;
	toolsBeforeModes?: string[];
}

// --- bash read-only allowlist ---------------------------------------------
//
// All structural checks (pipeline splitting, metachar rejection, allowlist
// prefixes) run on a QUOTE-MASKED copy of the command: characters the shell
// treats as literal (quoted content, backslash-escaped chars) become 'a'.
// `grep "a\|b" f` no longer looks like a pipeline; `sed -n '1p;2p'` no
// longer looks chained. Substitution stays visible: $( ) and backticks are
// kept even inside double quotes, because the shell executes them there.
// Token checks that must survive quoting (find -exec, date -s, curl write
// flags) run on the RAW string with quote-tolerant patterns — masking alone
// would hide a quoted flag like find "-exec".

// Commands whose first token qualifies as read-only. Anchored at the start of
// the command (leading whitespace allowed).
const READONLY_PATTERNS: RegExp[] = [
	// file inspection
	/^\s*(cat|head|tail|less|more|bat|wc|file|stat|du|df|tree)\b/,
	// search
	/^\s*(rg|grep|find|fd|which|whereis|type)\b/,
	// directory
	/^\s*(ls|pwd|eza)\b/,
	// text processing (no output redirection survives the metachar check)
	/^\s*(echo|printf|sort|uniq|diff|jq|sed\s+-n|awk)\b/,
	// system info
	/^\s*(printenv|uname|whoami|id|uptime|ps)\b/,
	/^\s*env\s*$/, // bare env only: `env CMD args` would run CMD
	/^\s*date\b/,
	// git (read-only subcommands)
	/^\s*git\s+(status|log|diff|show|blame|remote|describe|rev-parse|shortlog)\b/i,
	/^\s*git\s+(branch|tag)\s*$/i, // bare list forms only (branch NAME creates!)
	/^\s*git\s+(branch|tag)\s+(-a|-v|-r|-vv|-av|-avv|--list)\b/i,
	/^\s*git\s+ls-/i,
	/^\s*git\s+config\s+--get\b/i,
	/^\s*git\s+stash\s+list\b/i,
	// cargo (manifest-level only, never runs builds)
	/^\s*cargo\s+(metadata|tree|locate-project)\b/,
	/^\s*(cargo|rustc|node|python3?)\s+--version\b/,
	// pageinfo (local, keyless web fetch — stdout only)
	/^\s*pginf\b/,
];

// Reject within an allowlisted command (checked on the MASKED string):
// anything that could chain, redirect, or substitute — i.e. characters the
// shell would actually interpret. Single-level read-only pipelines are fine;
// the caller splits on unquoted `|` and checks each segment.
const REJECT_PATTERNS: RegExp[] = [
	/[\n\r]/, // second command on a new line
	/[;&<>`]|\|\||\$\(/, // chaining, redirection, substitution, backticks
];

// Token checks on the RAW command: a quoted flag behaves like a bare one
// once the shell strips the quotes (find "-exec", date "-s"), so these
// patterns tolerate optional quotes — masking alone would hide them.
const RAW_TOKEN_PATTERNS: RegExp[] = [
	/\s['"]?(-delete|-exec(?:dir)?|-ok(?:dir)?|-fls|-fprint\w*)\b/, // find actions
	/^\s*date\s+['"]?(-s|--set)\b/,
];

// curl: allowed as a GET-only fetcher (stdout), never with write flags.
// Checked on the raw string (quote-tolerant) whenever curl appears anywhere.
const CURL_WRITE_FLAGS = /(\s|=)['"]?(-X|-d|-F|-T|-o|--request|--data|--form|--upload-file|--output)\b/;

/**
 * Quote/escape-aware masking for the bash gate's structural checks. Walks the
 * command once and returns a copy where shell-literal characters are
 * replaced with 'a':
 * - single-quoted content: fully literal → fully masked
 * - double-quoted content: masked, but $ ` ( ) stay visible so that "$(cmd)"
 *   and "`cmd`" (which the shell executes) remain detectable
 * - backslash-escaped characters (outside quotes): masked; backslash-newline
 *   (line continuation) is dropped
 * - unquoted # at word start: comment, stripped to end of line (newline kept)
 * Returns undefined for commands too malformed to reason about
 * (unterminated quote, trailing backslash) — callers reject conservatively.
 */
export function maskShellQuoting(command: string): string | undefined {
	let out = "";
	let i = 0;
	const n = command.length;
	while (i < n) {
		const ch = command[i];
		if (ch === "\\") {
			if (i + 1 >= n) return undefined; // trailing backslash
			if (command[i + 1] === "\n") {
				i += 2; // line continuation: drop both chars
				continue;
			}
			out += "a"; // escaped character is literal
			i += 2;
			continue;
		}
		if (ch === "'") {
			const end = command.indexOf("'", i + 1);
			if (end === -1) return undefined; // unterminated
			out += "'" + "a".repeat(end - i - 1) + "'";
			i = end + 1;
			continue;
		}
		if (ch === '"') {
			i++;
			let seg = "";
			let closed = false;
			while (i < n) {
				const c = command[i];
				if (c === '"') {
					closed = true;
					i++;
					break;
				}
				if (c === "\\" && i + 1 < n) {
					seg += "a"; // \" \\$ \\` etc. — all literal inside "…"
					i += 2;
					continue;
				}
				if (c === "$" || c === "`" || c === "(" || c === ")") seg += c; // stays visible
				else seg += "a";
				i++;
			}
			if (!closed) return undefined; // unterminated
			out += '"' + seg + '"';
			continue;
		}
		if (ch === "#" && (out === "" || /[\s|]/.test(out.slice(-1)))) {
			// unquoted comment at word start: strip to end of line, keep the \n
			const nl = command.indexOf("\n", i);
			if (nl === -1) break;
			i = nl;
			continue;
		}
		out += ch;
		i++;
	}
	return out;
}

function isSingleReadOnlyCommand(maskedSegment: string): boolean {
	if (REJECT_PATTERNS.some((p) => p.test(maskedSegment))) return false;
	if (/^\s*curl\b/.test(maskedSegment)) return !CURL_WRITE_FLAGS.test(maskedSegment);
	return READONLY_PATTERNS.some((p) => p.test(maskedSegment));
}

/**
 * True when the command is read-only per the allowlist: every pipeline
 * segment must individually pass (`git log | head` yes; `cat f | tee g`,
 * `cat f | sh` no). Quoted metacharacters are treated as the literals the
 * shell sees; substitution and find/date/curl write tokens still reject.
 */
export function isReadOnlyCommand(command: string): boolean {
	if (RAW_TOKEN_PATTERNS.some((p) => p.test(command))) return false;
	if (/\bcurl\b/.test(command) && CURL_WRITE_FLAGS.test(command)) return false;
	const masked = maskShellQuoting(command);
	if (masked === undefined) return false; // malformed → reject conservatively
	// Pipelines are read-only only when every segment is read-only
	return masked.split("|").every((segment) => isSingleReadOnlyCommand(segment));
}

// --- specs path gate --------------------------------------------------------

export function isSpecsPath(path: string, cwd: string): boolean {
	if (!path) return false;
	const specsRoot = resolve(cwd, "specs");
	const abs = resolve(cwd, path);
	return abs === specsRoot || abs.startsWith(specsRoot + sep);
}

// --- extension -------------------------------------------------------------

export default function modesExtension(pi: ExtensionAPI): void {
	let mode: Mode = "implement";
	let toolsBeforeModes: string[] | undefined;
	let cwd = ".";

	function updateStatus(ctx: ExtensionContext): void {
		if (mode === "research") {
			ctx.ui.setStatus("modes", ctx.ui.theme.fg("warning", "🔍 research"));
		} else if (mode === "plan") {
			ctx.ui.setStatus("modes", ctx.ui.theme.fg("accent", "🧭 plan"));
		} else {
			ctx.ui.setStatus("modes", undefined);
		}
	}

	function applyTools(): void {
		if (mode === "research") {
			if (toolsBeforeModes === undefined) {
				toolsBeforeModes = pi.getActiveTools();
			}
			pi.setActiveTools(toolsBeforeModes.filter((name) => !RESEARCH_DISABLED_TOOLS.has(name)));
		} else if (toolsBeforeModes !== undefined) {
			// plan keeps every tool active (edit/write are path-gated instead);
			// implement restores the pre-modes set
			pi.setActiveTools(toolsBeforeModes);
			toolsBeforeModes = undefined;
		}
	}

	function persistState(): void {
		pi.appendEntry("modes", { mode, toolsBeforeModes });
	}

	function setMode(next: Mode, ctx: ExtensionContext): void {
		mode = next;
		applyTools();
		updateStatus(ctx);
		persistState();
		ctx.ui.notify(`Mode: ${mode} — ${MODE_DESCRIPTIONS[mode]}`, "info");
	}

	pi.registerCommand("mode", {
		description: "Switch working mode: research | plan | implement",
		handler: async (args, ctx) => {
			const arg = args.trim().toLowerCase();
			if (arg === "") {
				const choice = await ctx.ui.select(
					`Current: ${mode}. Select mode:`,
					MODES.map((m) => `${m} — ${MODE_DESCRIPTIONS[m]}`),
				);
				const picked = choice?.split(" — ")[0];
				if (picked && (MODES as readonly string[]).includes(picked)) {
					setMode(picked as Mode, ctx);
				}
				return;
			}
			if (!(MODES as readonly string[]).includes(arg)) {
				ctx.ui.notify(`Unknown mode "${arg}". Use: ${MODES.join(", ")}`, "error");
				return;
			}
			setMode(arg as Mode, ctx);
		},
	});

	function cycleMode(ctx: ExtensionContext): void {
		const next = MODES[(MODES.indexOf(mode) + 1) % MODES.length];
		setMode(next, ctx);
	}

	// Primary: Shift+Tab (Codex/Claude Code muscle memory); requires
	// keybindings.json to remap app.thinking.cycle → ctrl+alt+t.
	pi.registerShortcut("shift+tab", {
		description: "Cycle working mode (research → plan → implement)",
		handler: async (ctx) => cycleMode(ctx),
	});

	pi.registerShortcut("ctrl+alt+m", {
		description: "Cycle working mode (research → plan → implement)",
		handler: async (ctx) => cycleMode(ctx),
	});

	// Enforce the mode contract regardless of which tools are active
	// (defense in depth: research also swaps edit/write out of the tool set).
	pi.on("tool_call", async (event) => {
		if (mode === "implement") return;

		if (event.toolName === "bash") {
			const command = String((event.input as { command?: string })?.command ?? "");
			if (!isReadOnlyCommand(command)) {
				return {
					block: true,
					reason: `${mode} mode: bash is limited to read-only commands — read-only pipelines like "git log | head" are fine; no ;/&&/|| chaining, no redirects, no $() or backtick substitution, no writes. Keep metacharacters that are part of an argument quoted. Switch with /mode implement.\nCommand: ${command}`,
				};
			}
			return;
		}

		if (event.toolName !== "edit" && event.toolName !== "write") return;

		if (mode === "research") {
			return {
				block: true,
				reason: "research mode: edit/write are disabled. Present your findings and agree on the next step with the user first, then switch with /mode plan.",
			};
		}

		// plan mode: specs/** only
		const path = String((event.input as { path?: string })?.path ?? "");
		if (!isSpecsPath(path, cwd)) {
			return {
				block: true,
				reason: `plan mode: edit/write are limited to files under specs/** (put the plan in specs/ctx.md). Switch with /mode implement for code changes.\nPath: ${path}`,
			};
		}
	});

	// Inject the current mode's banner as a hidden message each turn
	pi.on("before_agent_start", async () => {
		const banner = MODE_BANNERS[mode];
		if (!banner) return;
		return { message: { customType: "modes-context", content: banner, display: false } };
	});

	// Keep only the most recent banner of the current mode: instructions are
	// re-injected every turn by before_agent_start, so older copies and banners
	// of other modes are dropped instead of accumulating in context.
	pi.on("context", async (event) => {
		const currentTag = `[MODE: ${mode}]`;
		let lastBannerIndex = -1;
		for (let i = event.messages.length - 1; i >= 0; i--) {
			const msg = event.messages[i] as AgentMessage & { customType?: string };
			if (
				msg.customType === "modes-context" &&
				typeof msg.content === "string" &&
				msg.content.startsWith(currentTag)
			) {
				lastBannerIndex = i;
				break;
			}
		}
		return {
			messages: event.messages.filter((m, i) => {
				const msg = m as AgentMessage & { customType?: string };
				return msg.customType !== "modes-context" || i === lastBannerIndex;
			}),
		};
	});

	// Restore persisted mode on session start / resume
	pi.on("session_start", async (_event, ctx) => {
		cwd = ctx.cwd;
		const entries = ctx.sessionManager.getEntries();
		const entry = entries
			.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "modes")
			.pop() as { data?: ModesState } | undefined;
		if (entry?.data?.mode && (MODES as readonly string[]).includes(entry.data.mode)) {
			mode = entry.data.mode;
			toolsBeforeModes = entry.data.toolsBeforeModes ?? toolsBeforeModes;
		}
		applyTools();
		updateStatus(ctx);
	});
}
