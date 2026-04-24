default:
    @just --list

update:
    nix run ".#update"
    chezmoi apply
