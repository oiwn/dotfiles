/**
 * /footer — one-line status footer.
 *
 * Replaces pi's default multi-segment footer stats with a single line:
 *
 *   ~/code/dotfiles · ↑1.4M ↓108k · 17.2%/1.0M · glm-5.3 · 🧭 plan
 *
 * Segments: abbreviated cwd, cumulative input/output tokens, context usage
 * (pi's >70%/>90% colorization), model id, and the mode status set by the
 * modes extension (read via footerData.getExtensionStatuses()).
 *
 * Data sources (all public extension API — verified in pi's
 * core/extensions/types.d.ts):
 * - tokens: ctx.sessionManager.getEntries() — assistant message usage PLUS
 *   branch_summary/compaction usage blocks, so counts survive compaction
 *   (a getBranch()-only sum resets at every compaction)
 * - context: ctx.getContextUsage() — compaction-aware, nulls right after a
 *   compaction until the next LLM response (rendered as "?/window" like pi)
 * - model: ctx.model; cwd: ctx.cwd; mode: extension statuses ("modes")
 *
 * Dropped from the default footer: R/W cache tokens, CH% hit rate, $ cost,
 * (auto) compaction tag. formatTokens/formatCwd reimplemented locally —
 * pi's footer module is internal, not extension API.
 *
 * /footer toggles custom ↔ default (default: on, installed at session_start).
 * Stays live via footerData.onBranchChange + requestRender on model_select
 * and agent_end.
 */

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { homedir } from "node:os";

/** pi's compact token format (k/M), mirroring the default footer's display. */
function formatTokens(count: number): string {
	if (count < 1000) return `${count}`;
	if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
	if (count < 1000000) return `${Math.round(count / 1000)}k`;
	if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
	return `${Math.round(count / 1000000)}M`;
}

function formatCwd(cwd: string): string {
	const home = homedir();
	if (home && cwd === home) return "~";
	if (home && cwd.startsWith(`${home}/`)) return `~${cwd.slice(home.length)}`;
	return cwd;
}

interface TokenUsage {
	input?: number;
	output?: number;
}

/** Cumulative in/out over ALL session entries, compaction blocks included. */
function cumulativeTokens(entries: readonly unknown[]): { input: number; output: number } {
	let input = 0;
	let output = 0;
	for (const raw of entries) {
		const e = raw as { type?: string; message?: { role?: string; usage?: TokenUsage }; usage?: TokenUsage };
		if (e.type === "branch_summary" || e.type === "compaction") {
			if (e.usage) {
				input += e.usage.input ?? 0;
				output += e.usage.output ?? 0;
			}
		} else if (e.type === "message" && e.message?.role === "assistant") {
			const u = e.message.usage;
			if (u) {
				input += u.input ?? 0;
				output += u.output ?? 0;
			}
		}
	}
	return { input, output };
}

export default function footerExtension(pi: ExtensionAPI): void {
	let enabled = false;
	let ctxRef: ExtensionContext | undefined;
	let tuiRef: { requestRender(): void } | null = null;

	function install(): void {
		const ctx = ctxRef;
		if (!ctx) return;
		ctx.ui.setFooter((tui, theme, footerData) => {
			tuiRef = tui;
			const unsub = footerData.onBranchChange(() => tui.requestRender());
			return {
				dispose: () => {
					unsub();
					tuiRef = null;
				},
				invalidate() {
					tui.requestRender();
				},
				render(width: number): string[] {
					const { input, output } = cumulativeTokens(ctx.sessionManager.getEntries());
					const usage = ctx.getContextUsage();
					const window = usage?.contextWindow ?? ctx.model?.contextWindow ?? 0;

					let contextStr: string;
					if (usage && usage.percent !== null) {
						const display = `${usage.percent.toFixed(1)}%/${formatTokens(window)}`;
						contextStr =
							usage.percent > 90
								? theme.fg("error", display)
								: usage.percent > 70
									? theme.fg("warning", display)
									: display;
					} else {
						contextStr = theme.fg("dim", `?/${window > 0 ? formatTokens(window) : "?"}`);
					}

					const left = `${theme.fg("dim", formatCwd(ctx.cwd))} · ↑${formatTokens(input)} ↓${formatTokens(output)} · ${contextStr}`;
					const modeStatus = footerData.getExtensionStatuses().get("modes") ?? theme.fg("dim", "⚙ implement");
					const right = `${theme.fg("dim", ctx.model?.id ?? "no-model")} · ${modeStatus}`;

					const lw = visibleWidth(left);
					const rw = visibleWidth(right);
					if (lw + rw + 1 > width) {
						return [truncateToWidth(`${left} ${right}`, width)];
					}
					return [left + " ".repeat(width - lw - rw) + right];
				},
			};
		});
	}

	pi.registerCommand("footer", {
		description: "Toggle the one-line status footer (custom ↔ default)",
		handler: async (_args, ctx) => {
			ctxRef = ctx;
			enabled = !enabled;
			if (enabled) {
				install();
				ctx.ui.notify("One-line footer enabled", "info");
			} else {
				ctx.ui.setFooter(undefined);
				ctx.ui.notify("Default footer restored", "info");
			}
		},
	});

	// Keep segments live: model switches and finished turns change the line.
	pi.on("model_select", async () => tuiRef?.requestRender());
	pi.on("agent_end", async () => tuiRef?.requestRender());

	// Default on for every session.
	pi.on("session_start", async (_event, ctx) => {
		ctxRef = ctx;
		enabled = true;
		install();
	});
}
