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
	npx -y cc-safety-net@latest install
