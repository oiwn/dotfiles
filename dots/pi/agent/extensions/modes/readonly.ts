/**
 * Read-only bash gate — data + logic for the modes extension.
 *
 * Single source of truth for two consumers:
 * - modes/index.ts: the tool_call gate (isReadOnlyCommand)
 * - healthcheck/index.ts: CLI instrument inventory (CLI_INSTRUMENTS)
 *
 * Entries are rust-first per what's actually installed: rust CLIs from nix
 * (fd, bat, eza, duf, tokei) and brew (rg), user crates from cargo (specdev,
 * pginf). POSIX twins stay allowed as fallback because models emit them
 * naturally; banners tell the agent to prefer the rust versions.
 *
 * The gate is a heuristic guardrail, not a sandbox — `sh -c` evasions are
 * out of scope. Quoting-aware: literal metacharacters inside quotes or after
 * a backslash (grep "a\|b", sed -n '1p;2p', echo "x; y") are masked before
 * the structural checks, while $( ) and backticks stay visible even inside
 * double quotes because the shell executes them there.
 */

// --- inventory ---------------------------------------------------------------

export type CommandSource = "nix" | "brew" | "cargo" | "posix" | "vcs" | "dev";

export interface ReadOnlyEntry {
	/** Anchored at command start (leading whitespace allowed). */
	readonly pattern: RegExp;
	/** Where the binary comes from — docs/healthcheck provenance. */
	readonly source: CommandSource;
	readonly note: string;
}

/**
 * CLI instruments the healthcheck verifies (binary on PATH + --version).
 * Kept beside the gate data so "what the gate allows" and "what we expect
 * installed" cannot drift apart.
 */
export const CLI_INSTRUMENTS: readonly {
	name: string;
	source: "nix" | "brew" | "cargo";
	note: string;
}[] = [
	{ name: "rg", source: "brew", note: "code search (rust grep)" },
	{ name: "fd", source: "nix", note: "file finder (rust find)" },
	{ name: "bat", source: "nix", note: "file viewer (rust cat)" },
	{ name: "eza", source: "nix", note: "listing (rust ls)" },
	{ name: "duf", source: "nix", note: "disk usage (rust df)" },
	{ name: "tokei", source: "nix", note: "code stats" },
	{ name: "jq", source: "nix", note: "JSON (mcp.json command secret)" },
	{ name: "specdev", source: "cargo", note: "specs workflow (user crate)" },
	{ name: "pginf", source: "cargo", note: "web page fetch (user crate)" },
];

// --- allowlist ----------------------------------------------------------------

const entry = (pattern: RegExp, source: CommandSource, note: string): ReadOnlyEntry => ({
	pattern,
	source,
	note,
});

export const READONLY_ENTRIES: readonly ReadOnlyEntry[] = [
	// rust CLIs (preferred; exact provenance in CLI_INSTRUMENTS — rg via brew, rest nix, jq is C but essential)
	entry(/^\s*(rg|fd|bat|eza|duf|tokei|jq)\b/, "nix", "rust CLIs — preferred over POSIX twins"),
	// user crates
	entry(/^\s*pginf\b/, "cargo", "web page → structured output (any args, stdout only)"),
	entry(/^\s*specdev\s+(status|scan|list)\b/, "cargo", "specdev inspection (never mutates spec content)"),
	entry(/^\s*specdev\s+(-V|--version|-h|--help)\b/, "cargo", "specdev meta"),
	// file inspection (POSIX fallbacks)
	entry(/^\s*(cat|head|tail|less|more|wc|file|stat|du|df|tree)\b/, "posix", "file inspection"),
	// search (POSIX fallbacks)
	entry(/^\s*(grep|find|which|whereis|type)\b/, "posix", "search"),
	// directory
	entry(/^\s*(ls|pwd)\b/, "posix", "directory listing"),
	// text processing (no output redirection survives the metachar check)
	entry(/^\s*(echo|printf|sort|uniq|diff|sed\s+-n|awk)\b/, "posix", "text processing"),
	// system info
	entry(/^\s*(printenv|uname|whoami|id|uptime|ps)\b/, "posix", "system info"),
	entry(/^\s*env\s*$/, "posix", "bare env only — `env CMD args` would run CMD"),
	entry(/^\s*date\b/, "posix", "clock (write flags rejected below)"),
	// git (read-only subcommands)
	entry(/^\s*git\s+(status|log|diff|show|blame|remote|describe|rev-parse|shortlog)\b/i, "vcs", "git read-only"),
	entry(/^\s*git\s+(branch|tag)\s*$/i, "vcs", "bare list forms only (branch NAME creates!)"),
	entry(/^\s*git\s+(branch|tag)\s+(-a|-v|-r|-vv|-av|-avv|--list)\b/i, "vcs", "git list flags"),
	entry(/^\s*git\s+ls-/i, "vcs", "git ls-*"),
	entry(/^\s*git\s+config\s+--get\b/i, "vcs", "git config read"),
	entry(/^\s*git\s+stash\s+list\b/i, "vcs", "git stash list"),
	// cargo (manifest-level only, never runs builds)
	entry(/^\s*cargo\s+(metadata|tree|locate-project)\b/, "dev", "cargo manifest info"),
	entry(/^\s*(cargo|rustc|node|python3?)\s+--version\b/, "dev", "toolchain versions"),
];

const READONLY_PATTERNS: RegExp[] = READONLY_ENTRIES.map((e) => e.pattern);

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

// --- quoting-aware mask -------------------------------------------------------

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
