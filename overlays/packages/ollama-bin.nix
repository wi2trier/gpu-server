{
  fetchurl,
  lib,
  stdenvNoCC,
  installShellFiles,
  acceleration ? null,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ollama";
  version = "0.13.1";

  # https://github.com/ollama/ollama/releases/latest
  # copy the hash for asset `ollama-linux-amd64.tgz` from the release page
  src = fetchurl {
    url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tgz";
    hash = "sha256:4997753db0c578d24f8fc95d1538741609d72529ab6e913ecbf910ae919b0232";
  };

  sourceRoot = ".";

  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [
    installShellFiles
  ];

  # ollama looks for acceleration libs in ../lib/ollama/ (now also for CPU-only with arch specific optimizations)
  # https://github.com/ollama/ollama/blob/main/docs/development.md#library-detection
  installPhase = ''
    runHook preInstall

    installBin ./bin/ollama

    mkdir -p $out/lib
    cp -r ./lib/ollama $out/lib/

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
