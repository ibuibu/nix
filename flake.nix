{
  description = "Minimal package definition for aarch64-darwin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    neovim-nightly-overlay,
    home-manager,
  } @ inputs: let
    system = "aarch64-darwin";
    pkgs = nixpkgs.legacyPackages.${system};
  in {

    homeConfigurations = {
      myHomeConfig = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = system;
        };
        extraSpecialArgs = {
          inherit inputs;
        };
        modules = [
          ./home.nix
        ];
      };
    };

    packages.${system}.my-packages = pkgs.buildEnv {
      name = "my-packages-list";
      paths = with pkgs; [
        git
        curl
      ];
    };

    apps.${system}.update = {
      type = "app";
      program = toString (pkgs.writeShellScript "update-script" ''
        set -e
        echo "Updating flake..."
        nix flake update
        echo "Updating profile..."
        nix profile upgrade my-packages
        echo "Update complete!"
      '');
    };

    formatter.aarch64-darwin = pkgs.alejandra;
  };
}
