/**
 * Modes extension — three working modes for disciplined sessions.
 *
 * research   read-only exploration: understand the problem, survey related
 *            materials (code, specs, docs, the web), discuss with the user
 *            before anything else. edit/write disabled; bash limited to
 *            read-only commands (readonly.ts).
 * plan       research + specdev planning: edit/write allowed only under
 *            specs/**; bash still read-only.
 * implement  full access (stock pi behavior — the default).
 *
 * Banners are specs-aware: `specs/` existence is detected once at
 * session_start (cwd is fixed per session) and each mode injects a specs or
 * plain variant on every before_agent_start. specdev is framed as awareness
 * in research — consult specs when useful, never an obligation. Research and
 * plan name the web stack: search via the web-search-prime MCP tool, read
 * pages with pginf (web-reader MCP fallback, curl GET last resort) — used
 * when the task needs external knowledge, not forced.
 *
 * Mechanism (modeled on pi's examples/extensions/plan-mode, minus its
 * plan-execution machinery — specdev's specs/ctx.md owns planning state):
 * - tool swap via pi.setActiveTools() with save/restore
 * - bash allowlist + specs path gate via pi.on("tool_call") (logic in readonly.ts)
 * - per-mode banner injected on before_agent_start (hidden, tagged, and
 *   filtered from context once stale after a mode switch)
 * - mode persisted via pi.appendEntry() and restored on session_start
 *
 * Tools not managed here (MCP tools, other extensions' tools) stay active in
 * every mode; only built-in edit/write are ever swapped out. The banners are
 * the single source of mode instructions — no separate skill. The context
 * filter keeps only the most recent current-mode banner so instructions are
 * delivered every turn without accumulating.
 *
 * Usage: /mode [research|plan|implement] (picker when no arg), Shift+Tab or
 * Ctrl+Alt+M to cycle. Shift+Tab requires keybindings.json to move
 * app.thinking.cycle off shift+tab (here: ctrl+alt+t). Footer shows the active
 * mode. The bash allowlist is a heuristic guardrail, not a sandbox.
 */

import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { existsSync } from "fs";
import { resolve, sep } from "path";
import { isReadOnlyCommand } from "./readonly.ts";

const MODES = ["research", "plan", "implement"] as const;
type Mode = (typeof MODES)[number];

const MODE_DESCRIPTIONS: Record<Mode, string> = {
	research: "read-only exploration: understand the problem, survey materials (specs, docs, web), discuss with the user",
	plan: "read-only exploration + specs/** planning (specdev)",
	implement: "full access",
};

const COMMON_RESEARCH_TAIL = `edit/write are disabled; bash is limited to read-only commands. Conclude by presenting the problem as you understand it, the requirements, and proposed goals — then discuss with the user until you agree. Only after agreement switch: /mode plan.`;

const RESEARCH_BODY = `You are in RESEARCH mode: reach a correct understanding of the problem and agree on clear goals — before any plan or code.
- Analyze the situation in general: what is being asked, what the constraints are, who/what it affects. Do not tunnel on symptoms or jump to solutions.
- Survey the related materials: relevant code, docs — and the internet when the task needs it: search with the web-search-prime MCP tool; read pages with pginf (web-reader MCP as fallback; curl GET last resort).
- Prefer the rust CLIs installed here: rg (grep), fd (find), bat (cat), eza (ls), duf (df).
- Formalize demands into explicit requirements; establish clear goals and success criteria for a proper solution.
- Distinguish verified facts from assumptions; surface open questions.`;

// Banner per mode × project kind. The `[MODE: x]` tag prefix is load-bearing:
// the context filter keys on it to drop stale banners after a mode switch.
const MODE_BANNERS: Record<Mode, { specs: string; plain: string }> = {
	research: {
		specs: `[MODE: research]
${RESEARCH_BODY}
- This project uses specdev: be aware of the skill — specs/overview.md (durable backdrop, gotchas) and specs/ctx.md (current task) exist here; consult them when they help. No obligation to load them for every question.
${COMMON_RESEARCH_TAIL}`,
		plain: `[MODE: research]
${RESEARCH_BODY}
${COMMON_RESEARCH_TAIL}`,
	},
	plan: {
		specs: `[MODE: plan]
You are in PLAN mode: turn the agreed understanding into a concrete plan — no implementation yet.
- Follow the specdev skill: read specs/overview.md and specs/ctx.md; write the plan as checkboxes in specs/ctx.md (surgical edits, specs/** only).
- Plan the solution direction validated in research. If you discover the problem was misunderstood, stop and discuss — return to research rather than planning the wrong thing.
- Verify the chosen approach online if needed: web-search-prime to search, pginf to read pages.
- Keep the plan concise and decision-relevant: ordered steps, choices, risks.
edit/write are limited to specs/**; bash stays read-only. Present the plan, get explicit user agreement, then switch: /mode implement.`,
		plain: `[MODE: plan]
You are in PLAN mode: turn the agreed understanding into a concrete plan — no implementation yet.
- Draft the plan and present it in conversation: ordered steps, choices, risks. Get explicit user agreement before any code.
- Verify the chosen approach online if needed: web-search-prime to search, pginf to read pages.
- This repo has no specs/ — consider suggesting \`specdev init\` to adopt the specs workflow.
edit/write are limited to specs/** (none exist here — the plan lives in conversation); bash stays read-only. After agreement switch: /mode implement.`,
	},
	implement: {
		specs: `[MODE: implement]
You are in IMPLEMENT mode: execute the agreed plan.
- Work through the specs/ctx.md checkboxes in order; tick each as completed ([ ] → [x]).
- Stay in scope: deviations from the agreed plan are discussed with the user first, never improvised.
- Verify your changes; report what changed and what remains.
Full tools available. When all steps are done, summarize and stop for review.`,
		plain: `[MODE: implement]
You are in IMPLEMENT mode: execute the agreed plan.
- Work through the plan steps in order; stay in scope: deviations are discussed with the user first, never improvised.
- Verify your changes; report what changed and what remains.
Full tools available. When all steps are done, summarize and stop for review.`,
	},
};

function bannerFor(mode: Mode, hasSpecs: boolean): string {
	return MODE_BANNERS[mode][hasSpecs ? "specs" : "plain"];
}

// Built-in tools swapped out in research mode. Everything else stays active.
const RESEARCH_DISABLED_TOOLS = new Set(["edit", "write"]);

interface ModesState {
	mode: Mode;
	toolsBeforeModes?: string[];
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
	let hasSpecs = false;

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
		return { message: { customType: "modes-context", content: bannerFor(mode, hasSpecs), display: false } };
	});

	// Keep only the most recent banner of the current mode: instructions are
	// re-injected every turn by before_agent_start, so older copies and banners
	// of other modes (or the other variant) are dropped instead of accumulating.
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
		// specs/ detection: once per session (cwd is fixed); the banner *text*
		// is re-delivered every turn, but the project kind does not change
		// mid-session (specdev init mid-session needs a fresh session anyway).
		hasSpecs = existsSync(resolve(cwd, "specs"));
		const entries = ctx.sessionManager.getEntries();
		const entry = entries
			.filter((e: { type: string; customType?: string }) => e.type === "custom" && e.customType === "modes")
			.pop() as { data?: ModesState } | undefined;
		if (entry?.data?.mode && (MODES as readonly string[]).includes(entry.data.mode)) {
			mode = entry.data.mode;
			toolsBeforeModes = entry.data.toolsBeforeModes ?? toolsBeforeModes;
		}
		// hasSpecs is NOT restored from the session: fresh existsSync is
		// authoritative (a resumed session may land in a different cwd).
		applyTools();
		updateStatus(ctx);
	});
}
