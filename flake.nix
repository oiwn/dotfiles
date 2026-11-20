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
      # One darwinConfiguration per host; each host's values live in vars/<host>.nix.
      hosts = [ "bakodo" "kodo" ];
    in {
      darwinConfigurations = nixpkgs.lib.genAttrs hosts (host:
        let
          vars = import ./vars/${host}.nix;
        in
        nix-darwin.lib.darwinSystem {
          system = vars.platform;
          specialArgs = { inherit vars; };
          modules = [
            home-manager.darwinModules.home-manager
            {
              nixpkgs.hostPlatform = vars.platform;

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
        });
    };
}
