current_dir := `pwd`

scan:
	detect-secrets scan --use-all-plugins --all-files dots/ > .secrets.baseline

# Stage everything except vars.nix (gitignored + intent-to-add; never track its content).
stage:
    git add -A -- . ':(exclude)vars.nix'
