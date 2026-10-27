{
  hostName   = "kodo";            # must match `scutil --get LocalHostName`
  systemUser = "alexch";          # must match `whoami`
  platform   = "aarch64-darwin";
  gitName    = "oiwn";
  gitEmail   = "alex@imscraping.ninja";

  # Casks this host skips (checked against the shared list in hosts/macbook.nix).
  # Drops: creative suite (blender, gimp, krita, reaper, obs) + special-purpose
  # (bambu-studio, surge-xt, docker-desktop). Everything else identical to bakodo.
  caskExclude = [
    "bambu-studio"
    "blender"
    "docker-desktop"
    "gimp"
    "krita"
    "obs"
    "reaper"
    "surge-xt"
  ];
}
