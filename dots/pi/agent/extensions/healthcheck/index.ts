/**
 * /healthcheck — quick inventory + health of the pi workflow instruments.
 *
 * One overlay answers: what tools are available and at what version, and is
 * anything broken? Checks:
 * - pi itself (binary + version)
 * - CLI instruments from modes/readonly.ts (single source of truth):
 *   rust CLIs (nix/brew) + the user's crates specdev/pginf (cargo), each via
 *   `--version`. ✗ not on PATH; ⚠ present but no --version support.
 * - specdev skill (~/.agents/skills/specdev/SKILL.md with frontmatter)
 * - mcp.json servers + auth.json .zai.key presence (key value never printed)
 * - MCP tool registration via pi.getAllTools() (proves the servers actually
 *   initialized through pi-mcp-adapter)
 * - keybindings.json + theme file, modes extension file
 *
 * Binaries are spawned via child_process directly — that is intentional:
 * it works regardless of the bash tool's mode gate. Extensions cannot invoke
 * MCP tools, so MCP health = registration, not a live call.
 *
 * Usage: /healthcheck (close with q, Escape, or Enter)
 */

import type { ExtensionAPI, ExtensionCommandContext, Theme } from "@earendil-works/pi-coding-agent";
import { matchesKey, visibleWidth, type Focusable } from "@earendil-works/pi-tui";
import { execFile } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { CLI_INSTRUMENTS } from "../modes/readonly.ts";

interface Row {
	status: "ok" | "warn" | "fail";
	name: string;
	detail: string;
}

interface Section {
	title: string;
	rows: Row[];
}

const AGENT_DIR = join(homedir(), ".pi", "agent");
const SKILL_MD = join(homedir(), ".agents", "skills", "specdev", "SKILL.md");
const VERSION_TIMEOUT_MS = 5000;

const firstLine = (s: string): string => s.trim().split("\n")[0] ?? "";

function versionOf(cmd: string, args: string[] = ["--version"]): Promise<{ ok: boolean; out: string }> {
	return new Promise((res) => {
		execFile(cmd, args, { timeout: VERSION_TIMEOUT_MS, encoding: "utf8" }, (err, stdout, stderr) => {
			if (!err) {
				res({ ok: true, out: firstLine(stdout) || "(no output)" });
				return;
			}
			const e = err as NodeJS.ErrnoException;
			if (e.code === "ENOENT") {
				res({ ok: false, out: "not on PATH" });
			} else {
				const code = typeof e.code === "number" ? `exit ${e.code}` : "failed";
				res({ ok: false, out: firstLine(stderr || stdout) || code });
			}
		});
	});
}

async function checkBinary(name: string, note: string): Promise<Row> {
	const { ok, out } = await versionOf(name);
	if (ok) {
		// Tools often prefix output with their own name ("tokei 14.0.0 …") —
		// the row already shows the name; strip the redundant prefix.
		const stripped = out.toLowerCase().startsWith(name.toLowerCase())
			? out.slice(name.length).replace(/^[-\s]+/, "")
			: out;
		return { status: "ok", name, detail: stripped || out };
	}
	// Distinguish "missing" from "present but --version rejected": re-probe
	// with which-like behavior via a bare --help fallback.
	const help = await versionOf(name, ["--help"]);
	if (help.ok) return { status: "warn", name, detail: `${note} — present, no --version support` };
	return { status: "fail", name, detail: `${note} — ${out}` };
}

function readFileJson(path: string): Record<string, unknown> | undefined {
	try {
		return JSON.parse(readFileSync(path, "utf8")) as Record<string, unknown>;
	} catch {
		return undefined;
	}
}

async function gatherSections(pi: ExtensionAPI): Promise<Section[]> {
	// --- core + CLI instruments ---------------------------------------------
	const core = await checkBinary("pi", "pi agent CLI");
	const cliRows = await Promise.all(
		CLI_INSTRUMENTS.map(({ name, note }) => checkBinary(name, note)),
	);

	// --- specdev skill --------------------------------------------------------
	const skillRow: Row = existsSync(SKILL_MD)
		? /(^|\n)description:/.test(readFileSync(SKILL_MD, "utf8").slice(0, 2048))
			? { status: "ok", name: "specdev skill", detail: "~/.agents/skills/specdev (global)" }
			: { status: "warn", name: "specdev skill", detail: "SKILL.md missing description frontmatter" }
		: { status: "fail", name: "specdev skill", detail: "~/.agents/skills/specdev/SKILL.md not found" };

	// --- MCP config + auth ----------------------------------------------------
	const mcpRows: Row[] = [];
	const mcp = readFileJson(join(AGENT_DIR, "mcp.json"));
	const servers = mcp && typeof mcp.mcpServers === "object" && mcp.mcpServers !== null
		? Object.keys(mcp.mcpServers as Record<string, unknown>)
		: [];
	mcpRows.push(
		servers.length > 0
			? { status: "ok", name: "mcp.json", detail: servers.join(", ") }
			: { status: "fail", name: "mcp.json", detail: "missing or has no mcpServers" },
	);
	const auth = readFileJson(join(AGENT_DIR, "auth.json"));
	const zai = auth?.zai as { key?: unknown } | undefined;
	mcpRows.push(
		zai && typeof zai.key === "string" && zai.key.length > 0
			? { status: "ok", name: "z.ai auth", detail: "auth.json .zai.key present (value not shown)" }
			: { status: "fail", name: "z.ai auth", detail: "auth.json .zai.key missing — MCP calls will 401" },
	);

	// --- MCP registration (did the servers initialize?) -----------------------
	// getAllTools() exposes server-level proxies (mcp__web_reader), not the
	// servers' internal tool names (web-reader_webReader) — patterns must
	// tolerate both naming schemes.
	const toolNames = pi.getAllTools().map((t: { name?: string }) => String(t?.name ?? ""));
	const search = toolNames.filter((n) => /web[-_]?search[-_]?prime/i.test(n));
	const reader = toolNames.filter((n) => /web[-_]?reader/i.test(n));
	const regRows: Row[] = [
		search.length > 0
			? { status: "ok", name: "MCP search", detail: search.join(", ") }
			: { status: "fail", name: "MCP search", detail: "web-search-prime tools not registered" },
		reader.length > 0
			? { status: "ok", name: "MCP reader", detail: reader.join(", ") }
			: { status: "warn", name: "MCP reader", detail: "web-reader tools not registered (pginf is primary anyway)" },
	];

	// --- agent config files -----------------------------------------------------
	const cfgRows: Row[] = [];
	cfgRows.push(
		existsSync(join(AGENT_DIR, "keybindings.json"))
			? { status: "ok", name: "keybindings.json", detail: "present (symlink resolves)" }
			: { status: "fail", name: "keybindings.json", detail: "missing or dangling symlink" },
	);
	const settings = readFileJson(join(AGENT_DIR, "settings.json"));
	const theme = settings && typeof settings.theme === "string" ? settings.theme : undefined;
	cfgRows.push(
		theme
			? existsSync(join(AGENT_DIR, "themes", `${theme}.json`))
				? { status: "ok", name: "theme", detail: `${theme} (themes/${theme}.json)` }
				: { status: "fail", name: "theme", detail: `settings say "${theme}" but themes/${theme}.json is missing` }
			: { status: "warn", name: "theme", detail: "no theme set in settings.json" },
	);
	cfgRows.push(
		existsSync(join(AGENT_DIR, "extensions", "modes", "index.ts"))
			? { status: "ok", name: "modes extension", detail: "extensions/modes/index.ts present" }
			: { status: "fail", name: "modes extension", detail: "extensions/modes/index.ts missing — run darwin-rebuild switch" },
	);

	// --- pi packages (runtime-managed: settings.json `packages`) --------------
	// cc-safety-net is a CLI-hook install (not a pi package): detected via its
	// config dir and/or a settings.json mention; `npx cc-safety-net status`
	// remains the authoritative check.
	const pkgs = readFileJson(join(AGENT_DIR, "settings.json"));
	const installedPackages: string[] = Array.isArray(pkgs?.packages)
		? (pkgs!.packages as unknown[]).map(String)
		: [];
	const pkgRow = (name: string): Row =>
		installedPackages.some((p) => p === `npm:${name}` || p === name)
			? { status: "ok", name, detail: "installed (settings.json packages)" }
			: { status: "fail", name, detail: `not installed — pi install npm:${name}` };
	const settingsRaw = existsSync(join(AGENT_DIR, "settings.json"))
		? readFileSync(join(AGENT_DIR, "settings.json"), "utf8")
		: "";
	const ccsnDetected =
		existsSync(join(homedir(), ".cc-safety-net")) || settingsRaw.includes("cc-safety-net");
	const ccsnRow: Row = ccsnDetected
		? { status: "ok", name: "cc-safety-net", detail: "config present — verify with: npx cc-safety-net status" }
		: { status: "warn", name: "cc-safety-net", detail: "not detected — npx -y cc-safety-net@latest install" };

	return [
		{ title: "core", rows: [core] },
		{ title: "CLI instruments (modes/readonly.ts)", rows: cliRows },
		{ title: "specdev", rows: [skillRow] },
		{ title: "MCP", rows: [...mcpRows, ...regRows] },
		{ title: "pi packages", rows: [pkgRow("pi-subagents"), pkgRow("pi-lens"), ccsnRow] },
		{ title: "agent config", rows: cfgRows },
	];
}

const ICON = { ok: "✓", warn: "⚠", fail: "✗" } as const;
const COLOR = { ok: "success", warn: "warning", fail: "error" } as const;

class HealthcheckOverlay implements Focusable {
	readonly width = 78;
	focused = false;

	constructor(
		private readonly theme: Theme,
		private readonly sections: Section[],
		private readonly done: () => void,
	) {}

	handleInput(data: string): void {
		if (matchesKey(data, "escape") || matchesKey(data, "return") || data === "q") {
			this.done();
		}
	}

	render(_width: number): string[] {
		const th = this.theme;
		const w = this.width;
		const innerW = w - 2;
		const lines: string[] = [];
		const counts = { ok: 0, warn: 0, fail: 0 };
		for (const s of this.sections) for (const r of s.rows) counts[r.status]++;

		const pad = (s: string, len: number) => s + " ".repeat(Math.max(0, len - visibleWidth(s)));
		// Overflow guard: version strings can be long (tokei's carries build
		// flags) — clip to the available width instead of running past the box.
		const clip = (s: string, max: number) =>
			visibleWidth(s) <= max ? s : `${s.slice(0, Math.max(0, max - 1)).trimEnd()}…`;
		const row = (content: string) => th.fg("border", "│") + pad(content, innerW) + th.fg("border", "│");

		lines.push(th.fg("border", `╭${"─".repeat(innerW)}╮`));
		lines.push(
			row(
				` ${th.fg("accent", "🩺 pi workflow health")}  ${th.fg("success", `${counts.ok} ok`)} · ${th.fg("warning", `${counts.warn} warn`)} · ${th.fg("error", `${counts.fail} fail`)}`,
			),
		);

		for (const section of this.sections) {
			if (section.rows.length === 0) continue;
			lines.push(row(` ${th.fg("dim", `── ${section.title} ──`)}`));
			const nameW = Math.max(...section.rows.map((r) => visibleWidth(r.name))) + 2;
			const detailW = innerW - (1 + 1 + 1) - nameW; // " ✓ " + name column
			for (const r of section.rows) {
				const icon = th.fg(COLOR[r.status], ICON[r.status]);
				lines.push(row(` ${icon} ${pad(r.name, nameW)}${th.fg("dim", clip(r.detail, detailW))}`));
			}
		}

		lines.push(row(` ${th.fg("dim", "q / esc / enter to close")}`));
		lines.push(th.fg("border", `╰${"─".repeat(innerW)}╯`));
		return lines;
	}
}

export default function healthcheckExtension(pi: ExtensionAPI): void {
	pi.registerCommand("healthcheck", {
		description: "Inventory + health of pi workflow instruments (binaries, skill, MCP, config)",
		handler: async (_args: string, ctx: ExtensionCommandContext) => {
			const sections = await gatherSections(pi);
			await ctx.ui.custom<void>(
				(_tui, theme, _keybindings, done) => new HealthcheckOverlay(theme, sections, done),
				{ overlay: true },
			);
		},
	});
}
