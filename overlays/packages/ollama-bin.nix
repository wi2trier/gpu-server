{
  fetchurl,
  lib,
  stdenvNoCC,
  acceleration ? null,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ollama";
  version = "0.12.10";

  # https://github.com/ollama/ollama/releases/latest
  # copy the hash for asset `ollama-linux-amd64.tgz` from the release page
  src = fetchurl {
    url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tgz";
    hash = "sha256:8f4bf70a9856a34ba71355745c2189a472e2691a020ebd2e242a58e4d2094722";
  };

  sourceRoot = ".";

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -Dm755 ./bin/ollama $out/bin/ollama

    mkdir -p $out/lib/ollama
    cp -r ./lib/ollama/* $out/lib/ollama/

    runHook postInstall
  '';

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
