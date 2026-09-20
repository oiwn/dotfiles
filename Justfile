current_dir := `pwd`

scan:
	detect-secrets scan --use-all-plugins --all-files dots/ > .secrets.baseline
