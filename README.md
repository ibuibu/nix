# nix

## Update

```shell
nix run ".#update"
```

## format

```shell
nix fmt <nix-file>
```

## check generation

```shell
nix run "nixpkgs#home-manager" -- generations
```
