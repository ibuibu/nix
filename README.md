# nix

###

```shell
nix run ".#update"
```

### format

```shell
nix fmt <nix-file>
```

### 世代の確認

```shell
nix run "nixpkgs#home-manager" -- generations
```
