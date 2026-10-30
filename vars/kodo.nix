{
  hostName   = "kodo";            # must match `scutil --get LocalHostName`
  systemUser = "alexch";          # must match `whoami`
  platform   = "aarch64-darwin";
  gitName    = "oiwn";
  gitEmail   = "alex@imscraping.ninja";

  # Casks this host skips (checked against the shared list in hosts/macbook.nix).
  # Drops: creative suite (blender, gimp, krita, reaper, obs) + special-purpose
  # (bambu-studio, surge-xt, docker-desktop) + bakodo-only apps (comfy, headlamp,
  # openvpn-connect, raspberry-pi-imager, ungoogled-chromium, yandex).
  caskExclude = [
    "bambu-studio"
    "blender"
    "comfy"
    "docker-desktop"
    "gimp"
    "headlamp"
    "krita"
    "obs"
    "openvpn-connect"
    "raspberry-pi-imager"
    "reaper"
    "surge-xt"
    "ungoogled-chromium"
    "yandex"
  ];
}
