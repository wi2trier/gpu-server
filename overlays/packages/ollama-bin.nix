{
  fetchurl,
  lib,
  stdenv,
  autoPatchelfHook,
  acceleration ? null,
}:
stdenv.mkDerivation rec {
  pname = "ollama";
  version = "0.11.0";

  # https://github.com/ollama/ollama/releases/latest
  # copy the hash for asset `ollama-linux-amd64.tgz` from the release page
  src = fetchurl {
    url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tgz";
    hash = "sha256:6627e9898ab0e7924e4bdda05a7c41c66eaa23404ef237ae952c1ae2c86129de";
  };

  sourceRoot = ".";

  dontBuild = true;
  dontConfigure = true;

  buildInputs = [
    stdenv.cc.cc.lib
  ];

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm755 ./bin/ollama $out/bin/ollama

    mkdir -p $out/lib
    install -Dm644 ./lib/ollama/* $out/lib/

    runHook postInstall
  '';

  autoPatchelfIgnoreMissingDeps = true;

  passthru = {
    inherit acceleration;
  };

  meta = {
    homepage = "https://ollama.com";
    downloadPage = "https://github.com/ollama/ollama/releases";
    description = "Get up and running with Llama, Mistral, Gemma, and other large language models";
    mainProgram = "ollama";
    platforms = [ "x86_64-linux" ];
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ mirkolenz ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
