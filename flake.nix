{
  description = "alexch dotfiles — nix-darwin + home-manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/9f78f44a87948854445dae0b6bf82b2e87e4efb5";
    nix-darwin = {
      url = "github:LnL7/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, nix-darwin, home-manager, ... }:
    let
      vars = import ./vars.nix;
    in {
      darwinConfigurations.${vars.hostName} = nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit vars; };
        modules = [
          home-manager.darwinModules.home-manager
          {
            nixpkgs.hostPlatform = "aarch64-darwin";

            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-bak";
              extraSpecialArgs = { inherit vars; };
              users.${vars.systemUser} = import ./home/default.nix;
            };
          }
          ./hosts/macbook.nix
        ];
      };
    };
}
