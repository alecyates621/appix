{
  description = "Multi-host NixOS (laptop + desktop) with Hyprland and Zen";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Zen Browser flake
    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    # alt:
    # zen-browser.url = "github:MarceColl/zen-browser-flake";
  };

  outputs = { self, nixpkgs, home-manager, zen-browser, ... }:
  let
    mkSystem = hostPath: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Host-specific NixOS config
        hostPath

        # Shared NixOS modules
        ./modules/common.nix
        ./modules/hyprland.nix

        # Home-Manager as a NixOS module
        home-manager.nixosModules.home-manager

        # Home-Manager configuration module (options must live inside an attrset)
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-bak";

          home-manager.users.appa = { pkgs, ... }: {
            home.stateVersion = "25.05";
            imports = [ ./home/common.nix ];

            # Zen Browser from the flake input
            home.packages = [
              zen-browser.packages.${pkgs.system}.default
            ];
          };
        }
      ];
    };
  in
  {
    nixosConfigurations = {
      laptop  = mkSystem ./hosts/laptop/configuration.nix;
      desktop = mkSystem ./hosts/desktop/configuration.nix;
    };
  };
}
