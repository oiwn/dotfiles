current_dir := `pwd`

scan:
	detect-secrets scan --use-all-plugins --all-files dots/ > .secrets.baseline

# Converge pi runtime packages. Idempotent — safe to re-run (fresh-machine
# path too); pi update remains the explicit refresh. cc-safety-net keeps
# @latest per its own README (bare spec can hit a stale npx cache).
pi-setup:
	pi install npm:pi-mcp-adapter
	pi install npm:pi-subagents
	pi install npm:pi-lens
	pi install npm:@narumitw/pi-usage
	pi install npm:@juicesharp/rpiv-ask-user-question
	pi install npm:@juicesharp/rpiv-todo
	npx -y cc-safety-net@latest install

# Reclaim disk: drop nix system generations older than <window> (rollback window) + clear the whole brew download cache.
gc window="14d":
	nix-collect-garbage --delete-older-than {{window}}
	brew cleanup --prune=all
