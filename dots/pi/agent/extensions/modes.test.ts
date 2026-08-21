/**
 * Unit tests for the modes extension's bash gate and specs path gate.
 *
 * Run from this directory:  node --test modes.test.ts
 *
 * This file lives in the repo only — home/dotfiles.nix symlinks modes.ts into
 * ~/.pi/agent/extensions/ but NOT this file, so pi never loads it. modes.ts
 * imports the pi SDK only as types (stripped at load), so these tests run
 * under plain node with no pi dependencies installed.
 */

import assert from "node:assert/strict";
import { test } from "node:test";
import { isReadOnlyCommand, isSpecsPath, maskShellQuoting } from "./modes.ts";

// --- maskShellQuoting shape checks ----------------------------------------

test("mask: single-quoted content is fully literal", () => {
	assert.equal(maskShellQuoting("grep 'a|b' f"), "grep 'aaa' f");
	assert.equal(maskShellQuoting("sed -n '5p;37p' x"), "sed -n 'aaaaaa' x");
});

test("mask: double quotes hide literals but keep $ ` ( ) visible", () => {
	assert.equal(maskShellQuoting('echo "x; y"'), 'echo "aaaa"');
	assert.equal(maskShellQuoting('echo "$(cmd)"'), 'echo "$(aaa)"');
	assert.equal(maskShellQuoting("echo \"`id`\""), 'echo "`aa`"');
	assert.equal(maskShellQuoting('echo "(paren)"'), 'echo "(aaaaa)"');
});

test("mask: backslash escapes are literal; line continuations drop", () => {
	assert.equal(maskShellQuoting("grep a\\|b f"), "grep aab f");
	assert.equal(maskShellQuoting("ls \\\n-la"), "ls -la");
});

test("mask: unquoted # comment strips to EOL, keeps the newline", () => {
	assert.equal(maskShellQuoting("git log # recent"), "git log ");
	assert.equal(maskShellQuoting("ls #c\nrm"), "ls \nrm");
	assert.equal(maskShellQuoting("echo a#b"), "echo a#b"); // mid-word: literal
	assert.equal(maskShellQuoting("grep '#' f"), "grep 'a' f"); // quoted: not a comment
});

test("mask: malformed input returns undefined", () => {
	assert.equal(maskShellQuoting("echo 'unterminated"), undefined);
	assert.equal(maskShellQuoting('echo "unterminated'), undefined);
	assert.equal(maskShellQuoting("echo trailing\\"), undefined);
});

// --- gate corpus: must ALLOW ------------------------------------------------

const ALLOWED: string[] = [
	// false positives hit in the live session (2025-08-19) — the reason this
	// hardening round exists
	'grep -n "extended-keys\\|escape-time" dots/.tmux.conf',
	'grep -n "ZAI\\|z.ai" home/ hosts/ dots/',
	'grep -rn "ZAI\\|z.ai" home/ hosts/ dots/',
	'grep -n "pginf\\|pageinfo" flake.nix home/packages.nix',
	// quoting class: metacharacters as literal argument content
	'echo "x && y"',
	"sed -n '5p;37p' specs/ctx.md",
	"rg 'foo|bar' src/",
	"awk '{print $1}' file.txt",
	"jq '.a | .b' data.json",
	'git log --format="%h %s" -5',
	"grep '#' README.md",
	"echo a\\|b", // shell prints: a|b
	"echo 'a; b'",
	"git log --oneline # recent commits",
	"find . -name '*.rs'",
	'find . -name "*.ts" -maxdepth 3',
	"printf '%s\\n' hello",
	"pginf 'https://example.com?a=1&b=2'",
	// read-only pipelines
	"git log --oneline | head -3",
	"git log | head -3 | wc -l",
	'git log --grep="fix" | grep -v merge',
	// regression basics
	"git status",
	"git status --short",
	"rg -n \"mode\" specs/",
	"cat specs/ctx.md",
	"ls -la",
	"bat README.md",
	"git show HEAD",
	"git diff",
	"git branch",
	"git tag",
	"git branch -a",
	"git branch -avv",
	"cargo metadata",
	"cargo tree --depth 1",
	"pginf https://example.com",
	"curl https://example.com",
	"curl -fsSL https://api.example.com/health",
	"curl -H 'Accept: application/json' https://api.example.com",
	"which rg",
	"printenv",
	"uname -a",
	"echo hello",
	"sort file.txt",
	"uniq -c file.txt",
	"diff a.txt b.txt",
	"jq . data.json",
	"wc -l file.txt",
	"stat file.txt",
	"du -sh .",
	"tree -L 2",
	"ps aux",
	"git config --get user.name",
	"git stash list",
	"git ls-remote origin",
	"node --version",
	"date",
];

for (const command of ALLOWED) {
	test(`allow: ${command}`, () => {
		assert.equal(isReadOnlyCommand(command), true);
	});
}

// --- gate corpus: must BLOCK ------------------------------------------------

const BLOCKED: string[] = [
	// correctly blocked in the live session — must stay blocked
	"git status --short && echo done",
	"ls > /tmp/x",
	"ls ~/.pi/agent/ 2>/dev/null",
	"cargo search pageinfo --limit 3",
	// substitution (executes even inside double quotes)
	'echo "$(rm -rf /)"',
	"echo $(git status)",
	"echo `whoami`",
	"echo \"`id`\"",
	"git log | head; rm x",
	// bad pipeline segments
	"cat f | tee g",
	"cat f | sh",
	"cat specs/ctx.md | ruby",
	"cat f |",
	"| cat",
	// chaining / redirects
	"echo hi; rm x",
	"echo hi && rm x",
	"echo hi || rm x",
	"git log >> out.txt",
	"echo done > log",
	"ls\nrm -rf /", // real newline
	// find / date / curl write tokens, incl. quoted-flag evasion
	"find . -exec rm {} \\;",
	"find . -execdir sh \\;",
	"find . -delete",
	"find '-exec' rm {} \\;", // quoted flag — closed by raw token check
	"find . -name '*.tmp' -ok rm {} \\;",
	"date -s 12:00",
	"date --set 12:00",
	"date '-s' 12:00",
	"curl -X POST https://x.dev",
	"curl -d @file https://x.dev",
	"curl --output /tmp/x https://x.dev",
	"curl '-o' out https://x.dev",
	// unlisted / dangerous commands
	"git push",
	"git branch new-branch",
	"sh -c 'ls'",
	"bash -c 'ls'",
	"env rm -rf /",
	"tmux show-options -g", // accepted limitation
	"touch x",
	"mkdir d",
	"mv a b",
	"rm x",
	"xargs rm",
	"make",
	"npm install",
	// malformed
	"echo 'unterminated",
	'echo "unterminated',
	"echo trailing\\",
];

for (const command of BLOCKED) {
	test(`block: ${command}`, () => {
		assert.equal(isReadOnlyCommand(command), false);
	});
}

// --- specs path gate --------------------------------------------------------

const CWD = "/w";
const SPECS_ALLOWED: Array<[string, string]> = [
	["specs/ctx.md", "inside specs"],
	["specs", "the specs dir itself"],
	["specs/", "trailing slash"],
	["./specs/ctx.md", "explicit relative"],
	["/w/specs/ctx.md", "absolute inside"],
	["../w/specs/a.md", "normalized back inside"],
];
const SPECS_BLOCKED: Array<[string, string]> = [
	["", "empty"],
	["README.md", "repo root"],
	["specsx/a", "prefix collision"],
	["dots/specs/a", "specs under another dir"],
	["../specs/a", "outside cwd"],
	["/other/specs/a", "absolute elsewhere"],
];

for (const [path, why] of SPECS_ALLOWED) {
	test(`specs allow: ${path} (${why})`, () => {
		assert.equal(isSpecsPath(path, CWD), true);
	});
}
for (const [path, why] of SPECS_BLOCKED) {
	test(`specs block: ${path} (${why})`, () => {
		assert.equal(isSpecsPath(path, CWD), false);
	});
}
