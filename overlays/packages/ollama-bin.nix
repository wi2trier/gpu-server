{
  fetchurl,
  lib,
  stdenvNoCC,
  acceleration ? null,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ollama";
  version = "0.12.6";

  # https://github.com/ollama/ollama/releases/latest
  # copy the hash for asset `ollama-linux-amd64.tgz` from the release page
  src = fetchurl {
    url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tgz";
    hash = "sha256:de82adce2ab79235115d511ff22fcb099ac53b67127870f12b80198c033ec0a1";
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
