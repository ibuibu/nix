{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}: let
  version = "0.9.9";

  sources = {
    "aarch64-darwin" = {
      url = "https://github.com/colbymchenry/codegraph/releases/download/v${version}/codegraph-darwin-arm64.tar.gz";
      hash = "sha256-Jm7gOMUpRulu4iKEP8bz5E01E0HtmPEfUne9/OmIDKU=";
    };
    "x86_64-linux" = {
      url = "https://github.com/colbymchenry/codegraph/releases/download/v${version}/codegraph-linux-x64.tar.gz";
      hash = "sha256-xA7oC84tNUyHS+/l7OmWKBy0bPCDAENy02/YpyOLWfs=";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
    or (throw "codegraph: unsupported platform ${stdenv.hostPlatform.system}");
in
  stdenv.mkDerivation {
    pname = "codegraph";
    inherit version;

    src = fetchurl source;

    nativeBuildInputs = lib.optionals stdenv.isLinux [autoPatchelfHook];
    buildInputs = lib.optionals stdenv.isLinux [stdenv.cc.cc.lib];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/libexec/codegraph $out/bin
      cp -r . $out/libexec/codegraph/
      ln -s $out/libexec/codegraph/bin/codegraph $out/bin/codegraph
      runHook postInstall
    '';

    meta = with lib; {
      description = "Local-first code graph indexer with MCP server for AI agents";
      homepage = "https://github.com/colbymchenry/codegraph";
      license = licenses.mit;
      mainProgram = "codegraph";
      platforms = builtins.attrNames sources;
    };
  }
