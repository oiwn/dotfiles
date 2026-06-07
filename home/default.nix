{ pkgs, vars, ... }:

{
  imports = [
    ./packages.nix
    ./dotfiles.nix
    ./terminal.nix
    ./dev.nix
    ./apps.nix
  ];

  home = {
    username = vars.systemUser;
    homeDirectory = "/Users/${vars.systemUser}";
    stateVersion = "24.11";
  };
}
