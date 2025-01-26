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
      ubuntu = "x86_64-linux";
    };

    pkgsFor = system: import nixpkgs { inherit system; };
  in {

    homeConfigurations = {
      # macOS用のHome Manager設定
      macos = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor systems.darwin;
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./home.nix
        ];
      };

      # Ubuntu用のHome Manager設定
      ubuntu = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor systems.ubuntu;
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./config/ubuntu.nix
        ];
      };
    };

    darwinConfigurations.MacBookProM2 = nix-darwin.lib.darwinSystem {
      system = systems.darwin;
      modules = [ ./darwin/default.nix ];
    };

    apps = {
      ${systems.darwin}.update = {
        type = "app";
        program = pkgsFor systems.darwin.writeShellScript "update-script" ''
          set -e
          echo "Updating flake..."
          nix flake update
          echo "Updating home-manager..."
          nix run "nixpkgs#home-manager" -- switch --flake ".#macos"
          echo "Updating nix-darwin..."
          nix run nix-darwin -- switch --flake ".#MacBookProM2"
          echo "Update complete!"
        '';
      };

      ${systems.ubuntu}.update = {
        type = "app";
        program = pkgsFor systems.ubuntu.writeShellScript "update-script" ''
          set -e
          echo "Updating flake..."
          nix flake update
          echo "Updating home-manager..."
          nix run "nixpkgs#home-manager" -- switch --flake ".#ubuntu"
          echo "Update complete!"
        '';
      };
    };

    formatter = {
      "${systems.darwin}" = pkgsFor systems.darwin.alejandra;
      "${systems.ubuntu}" = pkgsFor systems.ubuntu.alejandra;
    };
  };
}

