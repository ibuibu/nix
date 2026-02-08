{
  description = "Minimal package definition for aarch64-darwin and x86_64-linux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    neovim-nightly-overlay,
    home-manager,
    nix-darwin,
  } @ inputs: let
    systems = {
      darwin = "aarch64-darwin";
      linux = "x86_64-linux";
    };

    pkgsFor = system: import nixpkgs {inherit system;};
  in {
    homeConfigurations = {
      macos = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor systems.darwin;
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./home/darwin/default.nix
        ];
      };

      linux = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor systems.linux;
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./home/linux/default.nix
        ];
      };

      wsl = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor systems.linux;
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./home/wsl/default.nix
        ];
      };
    };

    darwinConfigurations.MacBookProM2 = nix-darwin.lib.darwinSystem {
      system = systems.darwin;
      modules = [./nix-darwin/default.nix];
    };

    apps = {
      aarch64-darwin.update = {
        type = "app";
        program = toString (nixpkgs.legacyPackages.aarch64-darwin.writeShellScript "update-script" ''
          set -e
          echo "Updating flake..."
          nix flake update
          echo "Updating home-manager..."
          nix run "nixpkgs#home-manager" -- switch --flake ".#macos"
          echo "Updating nix-darwin..."
          nix run nix-darwin -- switch --flake ".#MacBookProM2"
          echo "Update complete!"
        '');
      };

      x86_64-linux.update = {
        type = "app";
        program = toString (nixpkgs.legacyPackages.x86_64-linux.writeShellScript "update-script" ''
          set -e
          echo "Updating flake..."
          nix flake update
          echo "Updating home-manager..."
          if grep -qi microsoft /proc/version 2>/dev/null; then
            nix run "nixpkgs#home-manager" -- switch --flake ".#wsl"
          else
            nix run "nixpkgs#home-manager" -- switch --flake ".#linux"
          fi
          echo "Update complete!"
        '');
      };
    };

    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;

    # formatter = {
    #   "${systems.darwin}" = pkgsFor systems.darwin.alejandra;
    #   "${systems.ubuntu}" = pkgsFor systems.ubuntu.alejandra;
    # };
  };
}
