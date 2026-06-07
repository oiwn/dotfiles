{ pkgs, ... }:

{
  imports = [
    ./packages.nix
    ./dotfiles.nix
    ./terminal.nix
    ./dev.nix
    ./apps.nix
  ];

  home = {
    username = "alexch";
    homeDirectory = "/Users/alexch";
    stateVersion = "24.11";
  };
}
