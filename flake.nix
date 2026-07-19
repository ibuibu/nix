{
  description = "Minimal package definition for aarch64-darwin and x86_64-linux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # hunk の nixpkgs は follows させず、hunk 自身がロックした nixpkgs を使う。
    # nixpkgs unstable (26.11) は x86_64-darwin を drop したが、hunk は
    # nix-systems/default (x86_64-darwin を含む) で全システムの出力を評価するため、
    # follows すると hunk のビルド時に x86_64-darwin の評価が走って失敗する。
    hunk = {
      url = "github:modem-dev/hunk";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    claude-code,
    herdr,
    hunk,
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
          home-manager switch -b backup --flake ".#macos"
          echo "Updating nix-darwin..."
          sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake ".#MacBookProM2"
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
            home-manager switch --flake ".#wsl"
          else
            home-manager switch --flake ".#linux"
          fi
          echo "Update complete!"
        '');
      };
    };

    formatter.aarch64-darwin = nixpkgs.legacyPackages.aarch64-darwin.alejandra;
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
  };
}
