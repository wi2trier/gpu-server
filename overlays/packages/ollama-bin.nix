{
  fetchurl,
  lib,
  stdenvNoCC,
  installShellFiles,
  zstd,
  acceleration ? null,
}:
stdenvNoCC.mkDerivation rec {
  pname = "ollama";
  version = "0.15.2";

  # https://github.com/ollama/ollama/releases/latest
  # copy the hash for asset `ollama-linux-amd64.tar.zst` from the release page
  # VERSION="x.y.z" nix store prefetch-file "https://github.com/ollama/ollama/releases/download/v$VERSION/ollama-linux-amd64.tar.zst"
  src = fetchurl {
    url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tar.zst";
    hash = "sha256-RF+u48o7l8FY5CyZ5arrtgss7aGBMDl8F/qisk4Vbis=";
  };

  sourceRoot = ".";

  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [
    installShellFiles
    zstd
  ];

  unpackPhase = ''
    runHook  preUnpack

    zstd -dc $src | tar -xvf -

    runHook postUnpack
  '';

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
