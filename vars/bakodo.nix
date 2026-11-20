{
  hostName   = "bakodo";          # must match `scutil --get LocalHostName`
  systemUser = "alexch";          # must match `whoami`
  platform   = "aarch64-darwin";
  gitName    = "oiwn";
  gitEmail   = "alex@imscraping.ninja";

  # Casks this host skips (checked against the shared list in hosts/macbook.nix).
  caskExclude = [ ];
}
