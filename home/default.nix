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
    username = vars.userName;
    homeDirectory = "/Users/${vars.userName}";
    stateVersion = "24.11";
  };
}
